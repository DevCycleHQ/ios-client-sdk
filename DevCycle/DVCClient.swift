//
//  DVCClient.swift
//  DevCycle-iOS-SDK
//
//

enum ClientError: Error {
    case NotImplemented
    case BuiltClient
}

import Foundation

public class DVCClient {
    private var environmentKey: String?
    private var user: DVCUser?
    
    init(environmentKey: String? = nil, user: DVCUser? = nil) {
        self.environmentKey = environmentKey
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
}
