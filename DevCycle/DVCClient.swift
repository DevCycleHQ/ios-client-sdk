//
//  DVCClient.swift
//  DevCycle-iOS-SDK
//
//

import Foundation

enum ClientError: Error {
    case NotImplemented
    case MissingEnvironmentKeyOrUser
    case InvalidEnvironmentKey
    case InvalidUser
    case MissingUserOrFeatureVariationsMap
    case MissingUser
}

public typealias ClientInitializedHandler = (Error?) -> Void
public typealias IdentifyCompletedHandler = (Error?, [String: Variable]?) -> Void
public typealias FlushCompletedHandler = (Error?) -> Void
public typealias CloseCompletedHandler = () -> Void

public class DVCClient {
    var environmentKey: String?
    var user: DVCUser?
    var lastIdentifiedUser: DVCUser?
    var config: DVCConfig?
    var options: DVCOptions?
    var configCompletionHandlers: [ClientInitializedHandler] = []
    var initialized: Bool = false
    var eventQueue: EventQueue = EventQueue()
    
    private let defaultFlushInterval: Int = 10000
    private var flushEventsInterval: Double = 10.0
    private var enableEdgeDB: Bool = false
    
    private var service: DevCycleServiceProtocol?
    private var cacheService: CacheServiceProtocol = CacheService()
    private var cache: Cache?
    private var sseConnection: SSEConnection?
    private var flushTimer: Timer?
    private var closed: Bool = false
    
    /**
        Method to initialize the Client object after building
     */
    func initialize(callback: ClientInitializedHandler?) {
        guard let user = self.user, let environmentKey = self.environmentKey else {
            callback?(ClientError.MissingEnvironmentKeyOrUser)
            return
        }
        
        self.config = DVCConfig(environmentKey: environmentKey, user: user)
        
        let service = DevCycleService(config: self.config!, cacheService: self.cacheService)

        self.initialize(service: service, callback: callback)
    }
    
    internal func initialize(service: DevCycleServiceProtocol, callback: ClientInitializedHandler?) {
    
        if let options = self.options {
            Log.level = options.logLevel
            self.flushEventsInterval = Double(self.options?.flushEventsIntervalMs ?? self.defaultFlushInterval) / 1000.0
            self.enableEdgeDB = options.enableEdgeDB
        } else {
            Log.level = .error
        }
        
        self.lastIdentifiedUser = self.user
        
        self.setup(service: service, callback: callback)
    }
    
    /**
        Setup client with the DevCycleService and the callback
     */
    func setup(service: DevCycleServiceProtocol, callback: ClientInitializedHandler? = nil) {
        guard let user = self.user else {
            callback?(ClientError.MissingEnvironmentKeyOrUser)
            return
        }
        self.service = service
        self.service?.getConfig(user: user, enableEdgeDB: self.enableEdgeDB, completion: { [weak self] config, error in
            guard let self = self else { return }
            if let error = error {
                Log.error("Error getting config: \(error)", tags: ["setup"])
                self.cache = self.cacheService.load()
            } else {
                if let config = config {
                    Log.debug("Config: \(config)", tags: ["setup"])
                }
                self.config?.userConfig = config
                
                if (self.checkIfEdgeDBEnabled(config: config!, enableEdgeDB: self.enableEdgeDB)) {
                    if (!(user.isAnonymous ?? false)) {
                        self.service?.saveEntity(user: user, completion: { data, response, error in
                            if error != nil {
                                Log.error("Error saving user entity for \(user). Error: \(String(describing: error))")
                            } else {
                                Log.info("Saved user entity")
                            }
                        })
                    }
                }
            }
            
            if let sseURL = self.config?.userConfig?.sse?.url {
                if let parsedUrl = URL(string: sseURL) {
                    self.sseConnection = SSEConnection(url: parsedUrl, eventHandler: { (message: String ) -> Void in
                        Log.debug("Received message " + message)
                        // TODO implement message handling
                    })
                } else {
                    Log.error("Invalid URL received for realtime connection, skipping.")
                }
            }
            
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
        if (config.project.settings.edgeDB.enabled) {
            return !(!enableEdgeDB)
        } else {
            Log.debug("EdgeDB is not enabled for this project. Only using local user data.")
            return false
        }
    }
    
    func setEnvironmentKey(_ environmentKey: String) {
        self.environmentKey = environmentKey
    }
    
    func setUser(_ user: DVCUser) {
        self.user = user
    }
    
    func setOptions(_ options: DVCOptions) {
        self.options = options
    }
    
    func refetchConfig() {
        if let lastIdentifiedUser = self.lastIdentifiedUser, self.initialized {
            self.service?.getConfig(user: lastIdentifiedUser, enableEdgeDB: self.enableEdgeDB, completion: { [weak self] config, error in
                guard let self = self else { return }
                if let error = error {
                    Log.error("Error getting config: \(error)", tags: ["refetchConfig"])
                } else {
                    self.config?.userConfig = config
                }
            })
        }
    }

    public func variable<T>(key: String, defaultValue: T) -> DVCVariable<T> {
        var variable: DVCVariable<T>
        let regex = try? NSRegularExpression(pattern: ".*[^a-z0-9(\\-)(_)].*")
        if (regex?.firstMatch(in: key, range: NSMakeRange(0, key.count)) != nil) {
            Log.error("The variable key \(key) is invalid. It must contain only lowercase letters, numbers, hyphens and underscores. The default value will always be returned for this call.")
            return DVCVariable(
                key: key,
                type: String(describing: T.self),
                value: nil,
                defaultValue: defaultValue,
                evalReason: nil
            )
        }
        
        if let config = self.config?.userConfig,
           let variableFromApi = config.variables[key] {
            variable = DVCVariable(from: variableFromApi, defaultValue: defaultValue)
        } else {
            variable = DVCVariable(
                key: key,
                type: String(describing: T.self),
                value: nil,
                defaultValue: defaultValue,
                evalReason: nil
            )
        }
        
        if (!self.initialized) {
            self.configCompletionHandlers.append { error in
                if let variableFromApi = self.config?.userConfig?.variables[key] {
                    variable.update(from: variableFromApi)
                }
            }
        }
        
        if (!self.closed) {
            self.eventQueue.updateAggregateEvents(variableKey: variable.key, variableIsDefaulted: variable.isDefaulted)
        }
        
        return variable
    }
    
    public func identifyUser(user: DVCUser, callback: IdentifyCompletedHandler? = nil) throws {
        guard let currentUser = self.user, let userId = currentUser.userId, let incomingUserId = user.userId else {
            throw ClientError.InvalidUser
        }
        self.flushEvents()
        var updateUser: DVCUser = currentUser
        if (userId == incomingUserId) {
            updateUser.update(with: user)
        } else {
            updateUser = user
        }
        
        self.lastIdentifiedUser = user

        self.service?.getConfig(user: updateUser, enableEdgeDB: self.enableEdgeDB,  completion: { [weak self] config, error in
            guard let self = self else { return }
            if let error = error {
                Log.error("Error getting config: \(error)", tags: ["identify"])
                self.cache = self.cacheService.load()
            } else {
                if let config = config {
                    Log.debug("Config: \(config)", tags: ["identify"])
                }
                self.config?.userConfig = config
            }
            // TODO: save config in cache
            self.user = user
            self.cacheService.save(user: user)
            callback?(error, config?.variables)
        })
    }
    
    public func resetUser(callback: IdentifyCompletedHandler? = nil) throws {
        self.cache = cacheService.load()
        self.flushEvents()
        let anonUser = try DVCUser.builder().isAnonymous(true).build()
        
        self.lastIdentifiedUser = anonUser

        self.service?.getConfig(user: anonUser, enableEdgeDB: self.enableEdgeDB, completion: { [weak self] config, error in
            guard let self = self else { return }
            guard error == nil else {
                callback?(error, nil)
                return
            }
    
            // TODO: save config in cache
            if let config = config {
                Log.debug("Config: \(config)", tags: ["reset"])
            }
            self.config?.userConfig = config
            self.user = anonUser
            self.cacheService.save(user: anonUser)
            callback?(error, config?.variables)
        })
    }

    public func allFeatures() -> [String: Feature] {
        return self.config?.userConfig?.features ?? [:]
    }

    public func allVariables() -> [String: Variable] {
        return self.config?.userConfig?.variables ?? [:]
    }

    public func track(_ event: DVCEvent) {
        if (self.closed) {
            Log.error("DVCClient is closed, cannot log new events.")
            return
        }
        self.eventQueue.queue(event)
    }
    
    
    public func flushEvents() {
        self.flushEvents(callback: nil)
    }
    
    internal func flushEvents(callback: FlushCompletedHandler? = nil) {
        if (!self.eventQueue.isEmpty()) {
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
        if (self.closed) {
            Log.error("DVC Client is already closed.")
            return
        }
        Log.info("Closing DVC client and flushing remaining events.")
        self.closed = true
        self.flushTimer?.invalidate()
        self.flushEvents(callback: { error in
            callback?()
        })
        self.sseConnection?.close()
    }
    
    public class ClientBuilder {
        private var client: DVCClient
        private var service: DevCycleServiceProtocol?

        init() {
            self.client = DVCClient()
        }
        
        public func environmentKey(_ key: String) -> ClientBuilder {
            self.client.setEnvironmentKey(key)
            return self
        }
        
        public func user(_ user: DVCUser) -> ClientBuilder {
            self.client.setUser(user)
            return self
        }
        
        public func options(_ options: DVCOptions) -> ClientBuilder {
            self.client.setOptions(options)
            return self
        }
        
        internal func service(_ service: DevCycleServiceProtocol) -> ClientBuilder {
            self.service = service
            return self
        }
        
        public func build(onInitialized: ClientInitializedHandler?) throws -> DVCClient {
            guard self.client.environmentKey != nil else {
                Log.error("Missing Environment Key", tags: ["build"])
                throw ClientError.MissingEnvironmentKeyOrUser
            }
            guard self.client.user != nil else {
                Log.error("Missing User", tags: ["build"])
                throw ClientError.MissingEnvironmentKeyOrUser
            }
            
            let result = self.client
            if let service = service {
                result.initialize(service: service, callback: onInitialized)
            } else {
                result.initialize(callback: onInitialized)
            }
            self.client = DVCClient()
            return result
        }
    }
    
    public static func builder() -> ClientBuilder {
        return ClientBuilder()
    }
}
