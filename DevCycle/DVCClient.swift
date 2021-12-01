//
//  DVCClient.swift
//  DevCycle-iOS-SDK
//
//

enum ClientError: Error {
    case NotImplemented
    case BuiltClient
    case InvalidEnvironmentKey
    case InvalidUser
}

import Foundation

public class DVCClient {
    private var environmentKey: String?
    private var user: DVCUser?
    private var config: DVCConfig?
    
    private var service: DevCycleServiceProtocol?
    
    /**
        Setup client with the DevCycleService after client builder calls .build()
     */
    func setup(_ service: DevCycleServiceProtocol? = nil) {
        self.config = DVCConfig(environmentKey: self.environmentKey!, user: self.user!)
        if let service = service {
            self.service = service
        } else {
            self.service = DevCycleService(config: self.config!)
        }
        
        self.service?.getConfig(completion: { [weak self] config, error in
            guard let self = self else { return }
            if let error = error {
                print("Error: \(error)")
                return
            }
            self.config?.config = config
            print("Config: \(config)")
        })
    }
    
    func setEnvironmentKey(_ environmentKey: String) {
        self.environmentKey = environmentKey
    }
    
    func setUser(_ user: DVCUser) {
        self.user = user
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

    public func track() throws -> String {
        throw ClientError.NotImplemented
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
        
        public func build() -> DVCClient? {
            guard self.client.environmentKey != nil else {
                print("Missing Environment Key")
                return nil
            }
            guard self.client.user != nil else {
                print("Missing User")
                return nil
            }
            
            self.client.setup()
            
            let result = self.client
            self.client = DVCClient()
            return result
        }
    }
    
    public static func builder() -> ClientBuilder {
        return ClientBuilder()
    }
}
