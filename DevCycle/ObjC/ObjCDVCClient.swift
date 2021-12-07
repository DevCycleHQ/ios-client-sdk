//
//  ObjCDVCClient.swift
//  DevCycle
//
//

import Foundation

@objc(DVCClient)
public class ObjCDVCClient: NSObject {
    
    var client: DVCClient?
    
    @objc(DVCClientBuilder)
    public class ObjCClientBuilder: NSObject {
        var objcClient: ObjCDVCClient
        var clientBuilder: DVCClient.ClientBuilder
        
        override init() {
            self.objcClient = ObjCDVCClient()
            self.clientBuilder = DVCClient.builder()
        }
        
        @objc public func environmentKey(_ environmentKey: String) -> ObjCClientBuilder {
            self.clientBuilder = self.clientBuilder.environmentKey(environmentKey)
            return self
        }
        
        @objc public func user(_ user: ObjCDVCUser) -> ObjCClientBuilder {
            guard let user = user.user else {
                print("User is not valid")
                return self
            }
            self.clientBuilder = self.clientBuilder.user(user)
            return self
        }
        
        @objc public func build() -> ObjCDVCClient? {
            guard let swiftClient = self.clientBuilder.build() else {
                print("Error building client")
                return nil
            }
            self.objcClient.client = swiftClient
            return self.objcClient
        }
    }
    
    @objc public static func builder() -> ObjCClientBuilder {
        return ObjCClientBuilder()
    }
}
