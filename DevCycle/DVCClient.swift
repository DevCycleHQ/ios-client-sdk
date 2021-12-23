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
    case APIError
    case MissingUserOrFeatureVariationsMap
}

public typealias ClientInitializedHandler = (Error?) -> Void
public typealias IdentifyCompletedHandler = (Error?, [String: Variable]?) -> Void

public class DVCClient {
    var environmentKey: String?
    var user: DVCUser?
    var config: DVCConfig?
    var options: DVCOptions?
    var configCompletionHandlers: [ClientInitializedHandler] = []
    var initialized: Bool = false
    var eventQueue: [DVCEvent] = []
    
    private let defaultFlushInterval: Int = 10000
    private let msToSecond: Int = 1000
    private var service: DevCycleServiceProtocol?
    private var cacheService: CacheServiceProtocol = CacheService()
    private var cache: Cache?
    
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
        self.service?.getConfig(user: user, completion: { [weak self] config, error in
            guard let self = self else { return }
            if let error = error {
                print("Error: \(error)")
                self.cache = self.cacheService.load()
            } else {
                print("Config: \(String(describing: config))")
                self.config?.userConfig = config
            }
            
            for handler in self.configCompletionHandlers {
                handler(error)
            }
            callback?(error)
            self.initialized = true
            self.configCompletionHandlers = []
        })

        Timer.scheduledTimer(withTimeInterval: TimeInterval(((options?.flushEventsIntervalMs ?? self.defaultFlushInterval)/self.msToSecond)), repeats: true) { timer in
            self.flushEvents()
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
    
    public func variable<T>(key: String, defaultValue: T) throws -> DVCVariable<T> {
        var variable: DVCVariable<T>
        if let config = self.config?.userConfig,
           let variableFromApi = config.variables[key] {
            variable = try DVCVariable(from: variableFromApi, defaultValue: defaultValue)
        } else {
            variable = DVCVariable(key: key, type: String(describing: T.self), value: nil, defaultValue: defaultValue, evalReason: nil)
        }
        
        if (!self.initialized) {
            self.configCompletionHandlers.append { error in
                if let variableFromApi = self.config?.userConfig?.variables[key] {
                    try? variable.update(from: variableFromApi)
                }
            }
        }
        
        return variable
    }
    
    public func identifyUser(user: DVCUser, callback: IdentifyCompletedHandler? = nil) throws {
        guard let currentUser = self.user, let userId = currentUser.userId, let incomingUserId = user.userId else {
            throw ClientError.InvalidUser
        }
        var updateUser: DVCUser = currentUser
        if (userId == incomingUserId) {
            updateUser.update(with: user)
        } else {
            updateUser = user
        }
        
        self.service?.getConfig(user: updateUser, completion: { [weak self] config, error in
            guard let self = self else { return }
            if let error = error {
                print("Error: \(error)")
                self.cache = self.cacheService.load()
            } else {
                print("Config: \(String(describing: config))")
                self.config?.userConfig = config
            }
            self.cacheService.save(user: user, anonymous: user.isAnonymous ?? false)
            callback?(error, config?.variables)
        })
    }
    
    public func resetUser(callback: IdentifyCompletedHandler? = nil) throws {
        self.cache = cacheService.load()
        var anonUser: DVCUser
        if let cachedAnonUser = self.cache?.anonUser {
            anonUser = cachedAnonUser
        } else {
            anonUser = try DVCUser.builder().isAnonymous(true).build()
        }
        
        self.service?.getConfig(user: anonUser, completion: { [weak self] config, error in
            guard let self = self else { return }
            if (error == nil) {
                print("Config: \(String(describing: config))")
                self.config?.userConfig = config
            }
            self.cacheService.save(user: anonUser, anonymous: true)
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
        self.eventQueue.append(event)
    }

    public func flushEvents() {
        self.service?.publishEvents(events: self.eventQueue, user: self.user!, completion: { [weak self] data, response, error in
            if let error = error {
                print("Error: \(error)")
                return
            }
            print("Submitted: \(String(describing: self?.eventQueue.count)) events")
            self?.eventQueue = []
        })
    }
    
    public class ClientBuilder {
        private var client: DVCClient
        
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
        
        public func build(onInitialized: ClientInitializedHandler?) throws -> DVCClient {
            guard self.client.environmentKey != nil else {
                print("Missing Environment Key")
                throw ClientError.MissingEnvironmentKeyOrUser
            }
            guard self.client.user != nil else {
                print("Missing User")
                throw ClientError.MissingEnvironmentKeyOrUser
            }
            
            let result = self.client
            result.initialize(callback: onInitialized)
            self.client = DVCClient()
            return result
        }
    }
    
    public static func builder() -> ClientBuilder {
        return ClientBuilder()
    }
}
