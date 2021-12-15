//
//  DVCClient.swift
//  DevCycle-iOS-SDK
//
//

import Foundation

enum ClientError: Error {
    case NotImplemented
    case BuiltClient
    case InvalidEnvironmentKey
    case InvalidUser
}

public typealias ClientInitializedHandler = (Error?) -> Void

public class DVCClient {
    var environmentKey: String?
    var user: DVCUser?
    var config: DVCConfig?
    var options: DVCOptions?
    
    private var service: DevCycleServiceProtocol?
    private var eventQueue: [DVCEvent] = []
    
    /**
        Method to initialize the Client object after building
     */
    public func initialize(callback: ClientInitializedHandler?) {
        self.config = DVCConfig(environmentKey: self.environmentKey!, user: self.user!)
        let service = DevCycleService(config: self.config!)
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
                callback?(error)
                return
            }
            self.config?.config = config
            callback?(nil)
            print("Config: \(config)")
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
    
    public func variable() throws -> String {
        throw ClientError.NotImplemented
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
        
        public func build() -> DVCClient? {
            guard self.client.environmentKey != nil else {
                print("Missing Environment Key")
                return nil
            }
            guard self.client.user != nil else {
                print("Missing User")
                return nil
            }
            
            let result = self.client
            self.client = DVCClient()
            return result
        }
    }
    
    public static func builder() -> ClientBuilder {
        return ClientBuilder()
    }
}
