//
//  DevCycleClient.swift
//  DevCycle-iOS-SDK
//
//

import Foundation

#if os(iOS) || os(tvOS)
    import UIKit
#elseif os(watchOS)
    import WatchKit
#elseif os(macOS)
    import AppKit
#endif

enum ClientError: Error {
    case NotImplemented
    case MissingSDKKeyOrUser
    case InvalidSDKKey
    case InvalidUser
    case MissingUserOrFeatureVariationsMap
    case MissingUser
    case ConfigFetchFailed
}

public typealias ClientInitializedHandler = (Error?) -> Void
public typealias IdentifyCompletedHandler = (Error?, [String: Variable]?) -> Void
public typealias FlushCompletedHandler = (Error?) -> Void
public typealias CloseCompletedHandler = () -> Void
/// Invoked with `nil` on successful background refresh, or a definitive `Error` (e.g. invalid SDK key).
public typealias ConfigUpdatedHandler = (Error?) -> Void

public class DevCycleClient {
    var sdkKey: String?
    var user: DevCycleUser?
    var lastIdentifiedUser: DevCycleUser?
    var config: DVCConfig?
    var options: DevCycleOptions?
    var configCompletionHandlers: [ClientInitializedHandler] = []
    var initialized: Bool = false
    private var isConfigCached: Bool = false
    var eventQueue: EventQueue = EventQueue()
    private let configUpdateQueue = DispatchQueue(label: "com.devcycle.ConfigUpdateQueue")
    private var configUpdatedCallbacks: [ConfigUpdatedHandler] = []
    private var hasPendingConfigUpdate: Bool = false
    private var pendingConfigUpdateError: Error?
    private let defaultFlushInterval: Int = 10000
    private var flushEventsInterval: Double = 10.0
    private var enableEdgeDB: Bool = false
    var inactivityDelayMS: Double = 120000

    private var service: DevCycleServiceProtocol?
    internal var cacheService: CacheServiceProtocol = CacheService()
    var sseConnection: SSEConnectionProtocol?
    private var flushTimer: Timer?
    private var closed: Bool = false
    private var inactivityWorkItem: DispatchWorkItem?
    private var variableInstanceDictonary = [String: NSMapTable<AnyObject, AnyObject>]()
    private var disableAutomaticEventLogging: Bool = false
    private var disableCustomEventLogging: Bool = false

    private var variableQueue = DispatchQueue(label: "com.devcycle.VariableQueue")

    /**
        Method to initialize the Client object after building
     */
    func initialize(callback: ClientInitializedHandler?) {
        guard let user = self.user, let sdkKey = self.sdkKey else {
            callback?(ClientError.MissingSDKKeyOrUser)
            return
        }

        if let options = self.options {
            self.cacheService = CacheService(
                configCacheTTL: options.configCacheTTL,
                cacheKeyPrefix: options.cacheKeyPrefix
            )
        }

        self.config = DVCConfig(sdkKey: sdkKey, user: user)

        let service = DevCycleService(
            config: self.config!, cacheService: self.cacheService, options: self.options)

        self.initialize(service: service, callback: callback)
    }

    internal func initialize(service: DevCycleServiceProtocol, callback: ClientInitializedHandler?)
    {
        if let options = self.options {
            Log.level = options.logLevel
            self.flushEventsInterval =
                Double(self.options?.eventFlushIntervalMS ?? self.defaultFlushInterval) / 1000.0
            self.enableEdgeDB = options.enableEdgeDB
            self.disableAutomaticEventLogging = options.disableAutomaticEventLogging
            self.disableCustomEventLogging = options.disableCustomEventLogging
        } else {
            Log.level = .error
        }

        self.lastIdentifiedUser = self.user

        self.setup(service: service, callback: callback)

        #if os(iOS) || os(tvOS)
            NotificationCenter.default.addObserver(
                self,
                selector: #selector(appMovedToBackground),
                name: UIApplication.willResignActiveNotification,
                object: nil)
            NotificationCenter.default.addObserver(
                self,
                selector: #selector(appMovedToForeground),
                name: UIApplication.willEnterForegroundNotification,
                object: nil)
            NotificationCenter.default.addObserver(
                self,
                selector: #selector(appMovedToForeground),
                name: UIApplication.didBecomeActiveNotification,
                object: nil)
        #elseif os(watchOS)
            NotificationCenter.default.addObserver(
                self,
                selector: #selector(appMovedToBackground),
                name: WKExtension.applicationWillResignActiveNotification,
                object: nil)
            NotificationCenter.default.addObserver(
                self,
                selector: #selector(appMovedToForeground),
                name: WKExtension.applicationWillEnterForegroundNotification,
                object: nil)
        #elseif canImport(AppKit)
            NotificationCenter.default.addObserver(
                self,
                selector: #selector(appMovedToBackground),
                name: NSApplication.willResignActiveNotification,
                object: nil)
            NotificationCenter.default.addObserver(
                self,
                selector: #selector(appMovedToForeground),
                name: NSApplication.willBecomeActiveNotification,
                object: nil)
        #endif
    }

    /// On a cache hit, returns synchronously from the persisted config and refreshes
    /// in the background (observe via `onConfigUpdated(_:)`). On a cache miss, falls
    /// back to the network-first path.
    func setup(service: DevCycleServiceProtocol, callback: ClientInitializedHandler? = nil) {
        guard let user = self.user else {
            callback?(ClientError.MissingSDKKeyOrUser)
            return
        }
        self.service = service

        let cacheHit = self.useCachedConfigForUser(user: user)

        if cacheHit {
            self.deliverInitializationComplete(error: nil, callback: callback)
            self.performBackgroundRefresh()
        } else {
            self.service?.getConfig(
                user: user, enableEdgeDB: self.enableEdgeDB, extraParams: nil,
                completion: { [weak self] config, error in
                    guard let self = self else { return }

                    var finalError: Error? = error

                    if let error = error {
                        Log.error("Error getting config: \(error)", tags: ["setup"])

                        if self.config?.getUserConfig() != nil {
                            Log.info("Using cached config due to network error")
                            finalError = nil
                        }
                    } else if let config = config {
                        Log.debug("Config: \(config)", tags: ["setup"])
                        self.updateUserConfig(config)
                    } else {
                        Log.error("No config returned for setup", tags: ["setup"])
                        finalError = ClientError.ConfigFetchFailed
                    }

                    if let config = config {
                        self.syncUserToEdgeDBIfEnabled(user: user, config: config)
                    }

                    self.deliverInitializationComplete(error: finalError, callback: callback)
                })
        }

        self.flushTimer = Timer.scheduledTimer(
            withTimeInterval: TimeInterval(self.flushEventsInterval),
            repeats: true
        ) {
            timer in self.flushEvents()
        }
    }

    func checkIfEdgeDBEnabled(config: UserConfig, enableEdgeDB: Bool) -> Bool {
        if config.project.settings.edgeDB.enabled {
            return !(!enableEdgeDB)
        } else {
            Log.debug("EdgeDB is not enabled for this project. Only using local user data.")
            return false
        }
    }

    private func syncUserToEdgeDBIfEnabled(user: DevCycleUser, config: UserConfig) {
        guard !user.isAnonymous,
              checkIfEdgeDBEnabled(config: config, enableEdgeDB: self.enableEdgeDB)
        else { return }

        self.service?.saveEntity(user: user) { _, _, error in
            if let error = error {
                Log.error("Error saving user entity for \(user). Error: \(error)")
            } else {
                Log.info("Saved user entity")
            }
        }
    }

    func setSDKKey(_ sdkKey: String) {
        self.sdkKey = sdkKey
    }

    func setUser(_ user: DevCycleUser) {
        self.user = user
    }

    func setOptions(_ options: DevCycleOptions) {
        self.options = options
    }

    func refetchConfig(sse: Bool, lastModified: Int?, etag: String?) {
        if let lastIdentifiedUser = self.lastIdentifiedUser, self.initialized {
            let extraParams = RequestParams(sse: sse, lastModified: lastModified, etag: etag)
            self.service?.getConfig(
                user: lastIdentifiedUser, enableEdgeDB: self.enableEdgeDB, extraParams: extraParams,
                completion: { [weak self] config, error in
                    guard let self = self else { return }
                    if let error = error {
                        Log.error("Error getting config: \(error)", tags: ["refetchConfig"])
                        if self.isDefinitiveError(error) {
                            self.notifyConfigUpdated(error: error)
                        }
                    } else if let config = config {
                        self.updateUserConfig(config)
                        self.notifyConfigUpdated(error: nil)
                    } else {
                        Log.error("No config returned for refetchConfig", tags: ["refetchConfig"])
                    }
                })
        }
    }

    private func deliverInitializationComplete(
        error: Error?,
        callback: ClientInitializedHandler?
    ) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.initialized = true
            // Snapshot then clear so a handler that calls setup() again can't re-fire itself.
            let handlers = self.configCompletionHandlers
            self.configCompletionHandlers = []
            for handler in handlers {
                handler(error)
            }
            callback?(error)
        }
    }

    private func performBackgroundRefresh() {
        guard !self.closed, let user = self.lastIdentifiedUser else { return }
        self.service?.getConfig(user: user, enableEdgeDB: self.enableEdgeDB, extraParams: nil) {
            [weak self] config, error in
            guard let self = self, !self.closed else { return }

            // Discard if the user was switched mid-flight (ADR 0009: context change supersedes).
            guard user.userId == self.lastIdentifiedUser?.userId else {
                Log.warn(
                    "Background refresh result is for stale user, ignoring",
                    tags: ["backgroundRefresh"])
                return
            }

            if let error = error {
                if self.isDefinitiveError(error) {
                    // ADR 0009: keep cached values usable; only TTL evicts the cache.
                    Log.error(
                        "Background refresh failed with definitive error, keeping cached config and notifying observers: \(error)",
                        tags: ["backgroundRefresh"])
                    self.notifyConfigUpdated(error: error)
                } else {
                    Log.warn(
                        "Background refresh failed with transient error, keeping cached config: \(error)",
                        tags: ["backgroundRefresh"])
                }
            } else if let config = config {
                self.updateUserConfig(config)
                self.syncUserToEdgeDBIfEnabled(user: user, config: config)
                self.notifyConfigUpdated(error: nil)
            } else {
                Log.warn(
                    "Background refresh returned nil config with no error",
                    tags: ["backgroundRefresh"])
            }
        }
    }

    private func isDefinitiveError(_ error: Error) -> Bool {
        guard let apiError = error as? APIError else { return false }
        return apiError.isDefinitiveError
    }

    private func updateUserConfig(_ config: UserConfig) {
        let oldSSEURL = self.config?.userConfig?.sse?.url
        self.config?.setUserConfig(config: config)
        self.isConfigCached = false

        if let newSSEURL = config.sse?.url,
           self.options?.disableRealtimeUpdates != true,
           oldSSEURL != newSSEURL || self.sseConnection == nil
        {
            self.setupSSEConnection()
        }
    }

    private func setupSSEConnection() {
        if let disableRealtimeUpdates = self.options?.disableRealtimeUpdates, disableRealtimeUpdates
        {
            Log.info("Disabling Realtime Updates based on Initialization parameter")
            return
        }

        guard let sseURL = self.config?.getUserConfig()?.sse?.url else {
            Log.error("No SSE URL in config")
            return
        }
        guard let parsedURL = URL(string: sseURL) else {
            Log.error("Failed to parse SSE URL in config")
            return
        }

        if self.sseConnection != nil {
            Log.debug("Closing existing SSE connection")
            self.sseConnection?.close()
            self.sseConnection = nil
        }

        if let inactivityDelay = self.config?.getUserConfig()?.sse?.inactivityDelay {
            self.inactivityDelayMS = Double(inactivityDelay)
        }
        self.sseConnection = SSEConnection(
            url: parsedURL,
            eventHandler: { [weak self] (message: String) -> Void in
                Log.debug("Received message " + message)
                guard let messageData = message.data(using: .utf8) else {
                    Log.error("Failed to parse SSE message")
                    return
                }
                do {
                    guard
                        let messageDictionary =
                            try JSONSerialization.jsonObject(
                                with: messageData, options: .fragmentsAllowed) as? [String: Any]
                    else {
                        throw SSEMessage.SSEMessageError.messageError(
                            "Error serializing sse message to JSON")
                    }
                    let sseMessage = try SSEMessage(from: messageDictionary)
                    if sseMessage.data.type == nil || sseMessage.data.type == "refetchConfig" {
                        if self?.config?.getUserConfig()?.etag == nil
                            || sseMessage.data.etag != self?.config?.userConfig?.etag
                        {
                            self?.refetchConfig(
                                sse: true, lastModified: sseMessage.data.lastModified,
                                etag: sseMessage.data.etag)
                        }
                    }
                } catch {
                    Log.error("Failed to parse SSE message: \(error)")
                }
            })
    }

    public func variableValue(key: String, defaultValue: Bool) -> Bool {
        return getVariable(key: key, defaultValue: defaultValue).value
    }
    public func variableValue(key: String, defaultValue: String) -> String {
        return getVariable(key: key, defaultValue: defaultValue).value
    }
    public func variableValue(key: String, defaultValue: NSString) -> NSString {
        return getVariable(key: key, defaultValue: defaultValue).value
    }
    public func variableValue(key: String, defaultValue: Double) -> Double {
        return getVariable(key: key, defaultValue: defaultValue).value
    }
    public func variableValue(key: String, defaultValue: NSNumber) -> NSNumber {
        return getVariable(key: key, defaultValue: defaultValue).value
    }
    public func variableValue(key: String, defaultValue: [String: Any]) -> [String: Any] {
        return getVariable(key: key, defaultValue: defaultValue).value
    }
    public func variableValue(key: String, defaultValue: NSDictionary) -> NSDictionary {
        return getVariable(key: key, defaultValue: defaultValue).value
    }
    @available(
        *, deprecated, renamed: "variableValue()",
        message: "Use strictly typed versions of variableValue() methods"
    )
    public func variableValue<T>(key: String, defaultValue: T) -> T {
        return getVariable(key: key, defaultValue: defaultValue).value
    }

    public func variable(key: String, defaultValue: Bool) -> DVCVariable<Bool> {
        return getVariable(key: key, defaultValue: defaultValue)
    }
    public func variable(key: String, defaultValue: String) -> DVCVariable<String> {
        return getVariable(key: key, defaultValue: defaultValue)
    }
    public func variable(key: String, defaultValue: NSString) -> DVCVariable<NSString> {
        return getVariable(key: key, defaultValue: defaultValue)
    }
    public func variable(key: String, defaultValue: Double) -> DVCVariable<Double> {
        return getVariable(key: key, defaultValue: defaultValue)
    }
    public func variable(key: String, defaultValue: NSNumber) -> DVCVariable<NSNumber> {
        return getVariable(key: key, defaultValue: defaultValue)
    }
    public func variable(key: String, defaultValue: [String: Any]) -> DVCVariable<[String: Any]> {
        return getVariable(key: key, defaultValue: defaultValue)
    }
    public func variable(key: String, defaultValue: NSDictionary) -> DVCVariable<NSDictionary> {
        return getVariable(key: key, defaultValue: defaultValue)
    }
    @available(
        *, deprecated, renamed: "variable()",
        message: "Use strictly typed versions of variable() methods"
    )
    public func variable<T>(key: String, defaultValue: T) -> DVCVariable<T> {
        return getVariable(key: key, defaultValue: defaultValue)
    }

    func getVariable<T>(key: String, defaultValue: T) -> DVCVariable<T> {
        return variableQueue.sync {
            var variable: DVCVariable<T>
            if self.variableInstanceDictonary[key] == nil {
                self.variableInstanceDictonary[key] = NSMapTable<AnyObject, AnyObject>(
                    valueOptions: .weakMemory)
            }

            if let variableFromDictionary = self.variableInstanceDictonary[key]?.object(
                forKey: defaultValue as AnyObject) as? DVCVariable<T>
            {
                variable = variableFromDictionary
            } else {
                if let config = self.config?.getUserConfig(),
                    let variableFromApi = config.variables[key]
                {
                    variable = DVCVariable(from: variableFromApi, defaultValue: defaultValue)
                    if self.isConfigCached {
                        variable.eval = variable.eval?.withReason("CACHED")
                    }
                } else {
                    variable = DVCVariable(
                        key: key,
                        value: nil,
                        defaultValue: defaultValue,
                        eval: EvalReason.defaultReason(
                            details: DVCDefaultDetails.userNotTargeted.rawValue)
                    )
                }

                self.variableInstanceDictonary[key]?.setObject(
                    variable, forKey: defaultValue as AnyObject)
            }

            if !self.closed && !self.disableAutomaticEventLogging {
                self.eventQueue.updateAggregateEvents(
                    variableKey: variable.key,
                    variableIsDefaulted: variable.isDefaulted,
                    metadata: createVariableEventMetaData(variableEval: variable.eval)
                )
            }

            return variable
        }
    }

    private func createVariableEventMetaData(variableEval: EvalReason?) -> EvalMetaData? {
        if let eval = variableEval {
            if let targetId = eval.targetId {
                return [
                    "eval": [
                        "reason": eval.reason, "details": eval.details ?? "", "target_id": targetId,
                    ]
                ]
            }
            return ["eval": ["reason": eval.reason, "details": eval.details ?? ""]]
        }
        return nil
    }

    public func identifyUser(user: DevCycleUser, callback: IdentifyCompletedHandler? = nil) throws {
        guard let currentUser = self.user, !currentUser.userId.isEmpty,
            !user.userId.isEmpty
        else {
            throw ClientError.InvalidUser
        }
        self.flushEvents()
        var updateUser: DevCycleUser = currentUser
        if currentUser.userId == user.userId {
            updateUser.update(with: user)
        } else {
            updateUser = user
        }

        self.lastIdentifiedUser = user

        self.service?.getConfig(
            user: updateUser, enableEdgeDB: self.enableEdgeDB, extraParams: nil,
            completion: { [weak self] config, error in
                guard let self = self else { return }

                if let error = error {
                    Log.error(
                        "Error getting config: \(error) for user_id \(String(describing: updateUser.userId))",
                        tags: ["identify"])

                    // Try to use cached config for the new user
                    // If we have a cached config, proceed without error
                    if self.useCachedConfigForUser(user: updateUser),
                        self.config?.getUserConfig() != nil
                    {
                        Log.info(
                            "Using cached config for identifyUser due to network error: \(error)",
                            tags: ["identify"])
                        self.user = user
                        callback?(nil, self.config?.getUserConfig()?.variables)
                        return
                    } else {
                        // No cached config available, return error and don't change client state
                        Log.error(
                            "Error getting config for identifyUser: \(error)", tags: ["identify"])
                        callback?(error, nil)
                        return
                    }
                }

                if let config = config {
                    Log.debug("IdentifyUser config: \(config)", tags: ["identify"])
                    self.updateUserConfig(config)
                    self.user = user
                    callback?(nil, self.config?.getUserConfig()?.variables)
                } else {
                    Log.error("No config returned for identifyUser", tags: ["identify"])
                    callback?(ClientError.ConfigFetchFailed, nil)
                }
            })
    }

    @available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.0, *)
    public func identifyUser(user: DevCycleUser) async throws -> [String: Variable]? {
        return try await withCheckedThrowingContinuation { continuation in
            do {
                try self.identifyUser(user: user) { error, variables in
                    if let error = error {
                        continuation.resume(throwing: error)
                    } else {
                        continuation.resume(returning: variables)
                    }
                }
            } catch {
                Log.error(
                    "Error calling identifyUser for user_id \(String(describing: user.userId))",
                    tags: ["identify"])
                continuation.resume(throwing: error)
            }
        }
    }

    public func resetUser(callback: IdentifyCompletedHandler? = nil) throws {
        self.flushEvents()

        let cachedAnonUserId = self.cacheService.getAnonUserId()
        self.cacheService.clearAnonUserId()
        let anonUser = try DevCycleUser.builder().isAnonymous(true).build()

        self.lastIdentifiedUser = anonUser

        self.service?.getConfig(
            user: anonUser, enableEdgeDB: self.enableEdgeDB, extraParams: nil,
            completion: { [weak self] config, error in
                guard let self = self else { return }

                if let error = error {
                    Log.error("Error getting config for resetUser: \(error)", tags: ["reset"])
                    // Restore previous anonymous user ID on error and don't change client state
                    if let previousAnonUserId = cachedAnonUserId {
                        self.cacheService.setAnonUserId(anonUserId: previousAnonUserId)
                    }
                    callback?(error, nil)
                    return
                }

                if let config = config {
                    Log.debug("ResetUser config: \(config)", tags: ["reset"])
                    self.updateUserConfig(config)
                    self.user = anonUser
                    callback?(nil, config.variables)
                } else {
                    Log.error("No config returned for resetUser", tags: ["reset"])
                    callback?(ClientError.ConfigFetchFailed, nil)
                }
            })
    }

    @available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.0, *)
    public func resetUser() async throws -> [String: Variable]? {
        return try await withCheckedThrowingContinuation { continuation in
            do {
                try self.resetUser { error, variables in
                    if let error = error {
                        continuation.resume(throwing: error)
                    } else {
                        continuation.resume(returning: variables)
                    }
                }
            } catch {
                continuation.resume(throwing: error)
            }
        }
    }

    public func allFeatures() -> [String: Feature] {
        return self.config?.getUserConfig()?.features ?? [:]
    }

    public func allVariables() -> [String: Variable] {
        return self.config?.getUserConfig()?.variables ?? [:]
    }

    /// `true` while the in-memory config is from the persisted cache and no successful refresh has replaced it yet.
    public func hasUsableCachedConfig() -> Bool {
        return self.config?.getUserConfig() != nil && self.isConfigCached
    }

    /// Invoked (main queue) on a successful refresh or a definitive error; transient errors are not delivered.
    /// A refresh completing before any handler is registered is buffered and replayed once to the first registrant.
    public func onConfigUpdated(_ callback: @escaping ConfigUpdatedHandler) {
        var pendingError: Error?
        var hasPending = false
        configUpdateQueue.sync {
            configUpdatedCallbacks.append(callback)
            if hasPendingConfigUpdate {
                pendingError = pendingConfigUpdateError
                hasPending = true
                hasPendingConfigUpdate = false
                pendingConfigUpdateError = nil
            }
        }
        if hasPending {
            let errorToDeliver = pendingError
            DispatchQueue.main.async { callback(errorToDeliver) }
        }
    }

    private func notifyConfigUpdated(error: Error? = nil) {
        var callbacksSnapshot: [ConfigUpdatedHandler] = []
        configUpdateQueue.sync {
            if configUpdatedCallbacks.isEmpty {
                hasPendingConfigUpdate = true
                pendingConfigUpdateError = error
                return
            }
            callbacksSnapshot = configUpdatedCallbacks
        }
        guard !callbacksSnapshot.isEmpty else { return }
        DispatchQueue.main.async {
            for cb in callbacksSnapshot { cb(error) }
        }
    }

    public func track(_ event: DevCycleEvent) {
        if self.closed {
            Log.error("DevCycleClient is closed, cannot log new events.")
            return
        }
        if !self.disableCustomEventLogging {
            self.eventQueue.queue(event)
        }
    }

    public func flushEvents(callback: FlushCompletedHandler?) {
        self.flushEvents(callback)
    }

    @available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.0, *)
    public func flushEvents() async throws {
        try await withCheckedThrowingContinuation {
            (continuation: CheckedContinuation<Void, Error>) in
            self.flushEvents({ error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(returning: ())
                }
            })
        }
    }

    internal func flushEvents(_ callback: FlushCompletedHandler? = nil) {
        if !self.eventQueue.isEmpty() {
            guard let user = self.user else {
                Log.error("Flushing events failed, user not defined")
                return
            }
            guard let service = self.service else {
                Log.error("Client not set up correctly")
                return
            }
            self.eventQueue.flush(service: service, user: user) { error in
                callback?(error)
            }
        } else {
            callback?(nil)
        }
    }

    public func close(callback: CloseCompletedHandler?) {
        if self.closed {
            Log.error("DevCycleClient is already closed.")
            return
        }
        Log.info("Closing DevCycleClient and flushing remaining events.")
        self.closed = true
        configUpdateQueue.sync {
            self.configUpdatedCallbacks.removeAll()
            self.hasPendingConfigUpdate = false
            self.pendingConfigUpdateError = nil
        }
        self.flushTimer?.invalidate()
        self.flushEvents(callback: { error in
            callback?()
        })
        self.sseConnection?.close()
    }

    @available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.0, *)
    public func close() async {
        await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
            self.close {
                continuation.resume(returning: ())
            }
        }
    }

    public class ClientBuilder {
        private var client: DevCycleClient
        private var service: DevCycleServiceProtocol?

        init() {
            self.client = DevCycleClient()
        }

        @available(*, deprecated, message: "Use sdkKey()")
        public func environmentKey(_ key: String) -> ClientBuilder {
            self.client.setSDKKey(key)
            return self
        }

        public func sdkKey(_ key: String) -> ClientBuilder {
            self.client.setSDKKey(key)
            return self
        }

        public func user(_ user: DevCycleUser) -> ClientBuilder {
            self.client.setUser(user)
            return self
        }

        public func options(_ options: DevCycleOptions) -> ClientBuilder {
            self.client.setOptions(options)
            return self
        }

        internal func service(_ service: DevCycleServiceProtocol) -> ClientBuilder {
            self.service = service
            return self
        }

        public func build(onInitialized: ClientInitializedHandler?) throws -> DevCycleClient {
            guard self.client.sdkKey != nil else {
                Log.error("Missing SDK Key", tags: ["build"])
                throw ClientError.MissingSDKKeyOrUser
            }
            guard self.client.user != nil else {
                Log.error("Missing User", tags: ["build"])
                throw ClientError.MissingSDKKeyOrUser
            }

            if let service = service {
                self.client.initialize(service: service, callback: onInitialized)
            } else {
                self.client.initialize(callback: onInitialized)
            }
            return self.client
        }

        @available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.0, *)
        public func build() async throws -> DevCycleClient {
            return try await withCheckedThrowingContinuation { continuation in
                do {
                    var resultClient: DevCycleClient?
                    let client = try self.build(onInitialized: { error in
                        if let error = error {
                            continuation.resume(throwing: error)
                        } else if let resultClient = resultClient {
                            continuation.resume(returning: resultClient)
                        }
                    })
                    resultClient = client
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    public static func builder() -> ClientBuilder {
        return ClientBuilder()
    }

    @objc func appMovedToForeground() {
        inactivityWorkItem?.cancel()
        if let connected = self.sseConnection?.connected, !connected {
            self.refetchConfig(sse: false, lastModified: nil, etag: nil)
            self.sseConnection?.reopen()
        }
    }

    @objc func appMovedToBackground() {
        let delay = self.inactivityDelayMS / 1000 / 60
        let work = DispatchWorkItem(block: {
            self.sseConnection?.close()
        })
        self.inactivityWorkItem = work
        DispatchQueue.main.asyncAfter(deadline: .now() + Double(delay), execute: work)
    }

    private func useCachedConfigForUser(user: DevCycleUser) -> Bool {
        // Load cached config by default, unless explicitly disabled
        if options?.disableConfigCache != true,
            let cachedConfig = cacheService.getConfig(user: user)
        {
            self.config?.setUserConfig(config: cachedConfig)
            self.isConfigCached = true
            Log.debug("Loaded config from cache for user_id \(String(describing: user.userId))")

            // Bring up SSE from the cached URL; updateUserConfig() reconnects if the refresh changes it.
            if cachedConfig.sse?.url != nil,
                self.options?.disableRealtimeUpdates != true,
                self.sseConnection == nil
            {
                self.setupSSEConnection()
            }

            return true
        }
        self.isConfigCached = false
        return false
    }
}

@available(*, deprecated, message: "Use DevCycleClient")
public typealias DVCClient = DevCycleClient
