//
//  ObjCDVCClient.swift
//  DevCycle
//
//

import Foundation

@objc(DVCClient)
public class ObjCDVCClient: NSObject {
    
    var clientBuilder: DVCClient.ClientBuilder?
    var client: DVCClient?
    
    override init() {
        self.clientBuilder = DVCClient.builder()
    }
    
    @objc(DVCClientBuilder)
    public class ObjCClientBuilder: NSObject {
        var objcClient: ObjCDVCClient
        override init() {
            self.objcClient = ObjCDVCClient()
        }
        
        @objc public func environmentKey(_ environmentKey: String) -> ObjCClientBuilder {
            guard let clientBuilder = self.objcClient.clientBuilder else {
                return self
            }
            self.objcClient.clientBuilder = clientBuilder.environmentKey(environmentKey)
            return self
        }
        
        @objc public func build() -> ObjCDVCClient {
            guard let clientBuilder = self.objcClient.clientBuilder, let swiftClient = clientBuilder.build() else {
                print("Error building client")
                return self.objcClient
            }
            self.objcClient.client = swiftClient
            return self.objcClient
        }
    }
    
    @objc public static func builder() -> ObjCClientBuilder {
        return ObjCClientBuilder()
    }
}
