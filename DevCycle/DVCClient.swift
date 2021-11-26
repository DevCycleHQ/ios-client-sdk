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
    
    init(environmentKey: String? = nil, user: DVCUser? = nil) {
        self.environmentKey = environmentKey
        self.user = user
    }
    
    fileprivate func setEnvironmentKey(environmentKey: String) {
        self.environmentKey = environmentKey
    }
    
    fileprivate func setUser(user: DVCUser) {
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
        
        func environmentKey(key: String) -> ClientBuilder {
            self.client.setEnvironmentKey(environmentKey: key)
            return self
        }
        
        func user(user: DVCUser) -> ClientBuilder {
            self.client.setUser(user: user)
            return self
        }
        
        func build() -> DVCClient? {
            if (self.client.environmentKey == nil) {
                print("Missing Environment Key")
                return nil
            }
            
            if (self.client.user == nil) {
                print("Missing User")
                return nil
            }
                    
            let result = self.client
            self.client = DVCClient()
            return result
        }
    }
    
    static func builder() -> ClientBuilder {
        return ClientBuilder()
    }
}
