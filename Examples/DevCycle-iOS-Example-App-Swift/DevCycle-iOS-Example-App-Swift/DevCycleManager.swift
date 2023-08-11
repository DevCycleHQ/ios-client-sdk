//
//  DevCycleManager.swift
//  DevCycle-Example-App
//
//

import Foundation
import DevCycle

struct DevCycleKeys {
    static var DEVELOPMENT = "<DEVCYCLE_MOBILE_SDK_KEY>"
}

class DevCycleManager {
    
    var client: DevCycleClient?
    static let shared = DevCycleManager()
    
    func initialize(user: DevCycleUser) {
        let options = DevCycleOptions.builder()
//                                .logLevel(.debug)
                                .build()
        
        guard let client = try? DevCycleClient.builder()
                .sdkKey(DevCycleKeys.DEVELOPMENT)
                .user(user)
                .options(options)
                .build(onInitialized: nil)
        else {
            return
        }
        self.client = client
        
        
        client.subscribe(SubscribeHandlers.error(SubscribeError { error in
            print("DevCycle Error: \(error.localizedDescription)")
        }))
        client.subscribe(SubscribeHandlers.initialized(SubscribeInitialized({ success in
            print("DevCycle Initialized: \(success) from subscription")
        })))
    }
}
