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
}

public typealias ClientInitializedHandler = (Error?) -> Void

public class DVCClient {
    var environmentKey: String?
    var user: DVCUser?
    var config: DVCConfig?
    var options: DVCOptions?
    var eventQueue: [DVCEvent] = []
    
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
        service.cacheService = cacheService
        self.setup(service: service, callback: callback)
    }
    
    /**
        Setup client with the DevCycleService and the callback
     */
    func setup(service: DevCycleServiceProtocol, callback: ClientInitializedHandler? = nil) {
        self.service = service
        self.service?.getConfig(completion: { [weak self] config, error in
            guard let self = self else { return }
            if let error = error {
                print("Error: \(error)")
                self.cache = self.cacheService.load()
                callback?(error)
                return
            }
            self.config?.userConfig = config
            callback?(nil)
            print("Config: \(config!)")
        })
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
    
    public func identifyUser() throws -> String {
        throw ClientError.NotImplemented
    }
    
    public func variable<T>(key: String, defaultValue: T) throws -> DVCVariable<T> {
        var variable: DVCVariable<T>
        if let config = self.config?.userConfig,
           let variableFromApi = config.variables[key] {
            variable = try DVCVariable(from: variableFromApi, defaultValue: defaultValue)
        } else {
            variable = DVCVariable(key: key, type: String(describing: T.self), value: nil, defaultValue: defaultValue, evalReason: nil)
        }
        
        // TODO: add config handler that will update the variable when the config returns
        
        return variable
    }
    
    public func resetUser() throws -> String {
        throw ClientError.NotImplemented
    }

    public func allFeatures() throws -> String {
        throw ClientError.NotImplemented
    }

    public func allVariables() throws -> String {
        throw ClientError.NotImplemented
    }

    public func track(_ event: DVCEvent) {
        self.eventQueue.append(event)
    }

    public func flushEvents() throws -> String {
        throw ClientError.NotImplemented
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
            self.client = DVCClient()
            self.client.initialize(callback: onInitialized)
            return result
        }
    }
    
    public static func builder() -> ClientBuilder {
        return ClientBuilder()
    }
}
