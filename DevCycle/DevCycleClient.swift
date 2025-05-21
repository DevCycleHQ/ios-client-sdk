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
}

public typealias ClientInitializedHandler = (Error?) -> Void
public typealias IdentifyCompletedHandler = (Error?, [String: Variable]?) -> Void
public typealias FlushCompletedHandler = (Error?) -> Void
public typealias CloseCompletedHandler = () -> Void

public class DevCycleClient {
    var sdkKey: String?
    var user: DevCycleUser?
    var lastIdentifiedUser: DevCycleUser?
    var config: DVCConfig?
    var options: DevCycleOptions?
    var configCompletionHandlers: [ClientInitializedHandler] = []
    var initialized: Bool = false
    var eventQueue: EventQueue = EventQueue()
    private let defaultFlushInterval: Int = 10000
    private var flushEventsInterval: Double = 10.0
    private var enableEdgeDB: Bool = false
    var inactivityDelayMS: Double = 120000

    private var service: DevCycleServiceProtocol?
    private var cacheService: CacheServiceProtocol = CacheService()
    private var cache: Cache?
    var sseConnection: SSEConnectionProtocol?
    private var flushTimer: Timer?
    private var closed: Bool = false
    private var inactivityWorkItem: DispatchWorkItem?
    private var variableInstanceDictonary = [String: NSMapTable<AnyObject, AnyObject>]()
    private var isConfigCached: Bool = false
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

    /**
        Setup client with the DevCycleService and the callback
     */
    func setup(service: DevCycleServiceProtocol, callback: ClientInitializedHandler? = nil) {
        guard let user = self.user else {
            callback?(ClientError.MissingSDKKeyOrUser)
            return
        }
        self.service = service

        var cachedConfig: UserConfig?
        if let configCacheTTL = options?.configCacheTTL,
            let disableConfigCache = options?.disableConfigCache, !disableConfigCache
        {
            cachedConfig = cacheService.getConfig(user: user, ttlMs: configCacheTTL)
        }

        if cachedConfig != nil {
            self.config?.userConfig = cachedConfig
            self.isConfigCached = true
            Log.debug("Loaded config from cache")
        }

        self.service?.getConfig(
            user: user, enableEdgeDB: self.enableEdgeDB, extraParams: nil,
            completion: { [weak self] config, error in
                guard let self = self else { return }
                if let error = error {
                    Log.error("Error getting config: \(error)", tags: ["setup"])
                    self.cache = self.cacheService.load()
                } else {
                    if let config = config {
                        Log.debug("Config: \(config)", tags: ["setup"])
                    }
                    self.config?.userConfig = config
                    self.isConfigCached = false

                    self.cacheUser(user: user)

                    if self.checkIfEdgeDBEnabled(config: config!, enableEdgeDB: self.enableEdgeDB) {
                        if !(user.isAnonymous ?? false) {
                            self.service?.saveEntity(
                                user: user,
                                completion: { data, response, error in
                                    if error != nil {
                                        Log.error(
                                            "Error saving user entity for \(user). Error: \(String(describing: error))"
                                        )
                                    } else {
                                        Log.info("Saved user entity")
                                    }
                                })
                        }
                    }
                }

                self.setupSSEConnection()

                for handler in self.configCompletionHandlers {
                    handler(error)
                }
                callback?(error)
                self.initialized = true
                self.configCompletionHandlers = []
            })

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
                    } else {
                        self.config?.userConfig = config
                        self.isConfigCached = false
                    }
                })
        }
    }

    private func cacheUser(user: DevCycleUser) {
        self.cacheService.save(user: user)
    }

    private func setupSSEConnection() {
        if let disableRealtimeUpdates = self.options?.disableRealtimeUpdates, disableRealtimeUpdates
        {
            Log.info("Disabling Realtime Updates based on Initialization parameter")
            return
        }

        guard let sseURL = self.config?.userConfig?.sse?.url else {
            Log.error("No SSE URL in config")
            return
        }
        guard let parsedURL = URL(string: sseURL) else {
            Log.error("Failed to parse SSE URL in config")
            return
        }
        if let inactivityDelay = self.config?.userConfig?.sse?.inactivityDelay {
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
                    let messageDictionary =
                        try JSONSerialization.jsonObject(
                            with: messageData, options: .fragmentsAllowed) as! [String: Any]
                    let sseMessage = try SSEMessage(from: messageDictionary)
                    if sseMessage.data.type == nil || sseMessage.data.type == "refetchConfig" {
                        if self?.config?.userConfig?.etag == nil
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
        let regex = try? NSRegularExpression(pattern: ".*[^a-z0-9(\\-)(_)].*")
        if regex?.firstMatch(in: key, range: NSMakeRange(0, key.count)) != nil {
            Log.error(
                "The variable key \(key) is invalid. It must contain only lowercase letters, numbers, hyphens and underscores. The default value will always be returned for this call."
            )
            return DVCVariable(
                key: key,
                value: nil,
                defaultValue: defaultValue,
                evalReason: nil
            )
        }

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
                if let config = self.config?.userConfig,
                    let variableFromApi = config.variables[key]
                {
                    variable = DVCVariable(from: variableFromApi, defaultValue: defaultValue)
                } else {
                    variable = DVCVariable(
                        key: key,
                        value: nil,
                        defaultValue: defaultValue,
                        evalReason: nil
                    )
                }

                self.variableInstanceDictonary[key]?.setObject(
                    variable, forKey: defaultValue as AnyObject)
            }

            if !self.closed && !self.disableAutomaticEventLogging {
                self.eventQueue.updateAggregateEvents(
                    variableKey: variable.key, variableIsDefaulted: variable.isDefaulted)
            }

            return variable
        }
    }

    public func identifyUser(user: DevCycleUser, callback: IdentifyCompletedHandler? = nil) throws {
        guard let currentUser = self.user, let userId = currentUser.userId,
            let incomingUserId = user.userId
        else {
            throw ClientError.InvalidUser
        }
        self.flushEvents()
        var updateUser: DevCycleUser = currentUser
        if userId == incomingUserId {
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
                    Log.error("Error getting config: \(error)", tags: ["identify"])
                    self.cache = self.cacheService.load()
                } else {
                    if let config = config {
                        Log.debug("Config: \(config)", tags: ["identify"])
                    }
                    self.config?.userConfig = config
                    self.isConfigCached = false
                }
                self.user = user
                self.cacheUser(user: user)
                callback?(error, config?.variables)
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
                continuation.resume(throwing: error)
            }
        }
    }

    public func resetUser(callback: IdentifyCompletedHandler? = nil) throws {
        self.cache = cacheService.load()
        self.flushEvents()

        let cachedAnonUserId = self.cacheService.getAnonUserId()
        self.cacheService.clearAnonUserId()
        let anonUser = try DevCycleUser.builder().isAnonymous(true).build()

        self.lastIdentifiedUser = anonUser

        self.service?.getConfig(
            user: anonUser, enableEdgeDB: self.enableEdgeDB, extraParams: nil,
            completion: { [weak self] config, error in
                guard let self = self else { return }
                guard error == nil else {
                    if let previousAnonUserId = cachedAnonUserId {
                        self.cacheService.setAnonUserId(anonUserId: previousAnonUserId)
                    }
                    callback?(error, nil)
                    return
                }

                if let config = config {
                    Log.debug("Config: \(config)", tags: ["reset"])
                }
                self.config?.userConfig = config
                self.isConfigCached = false
                self.user = anonUser
                self.cacheUser(user: anonUser)
                callback?(error, config?.variables)
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
        return self.config?.userConfig?.features ?? [:]
    }

    public func allVariables() -> [String: Variable] {
        return self.config?.userConfig?.variables ?? [:]
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

            let result = self.client
            if let service = service {
                result.initialize(service: service, callback: onInitialized)
            } else {
                result.initialize(callback: onInitialized)
            }
            self.client = DevCycleClient()
            return result
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
}

@available(*, deprecated, message: "Use DevCycleClient")
public typealias DVCClient = DevCycleClient
