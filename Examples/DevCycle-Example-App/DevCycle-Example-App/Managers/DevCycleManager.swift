//
//  DevCycleManager.swift
//  DevCycle-Example-App
//
//

import Foundation
import DevCycle

struct DevCycleKeys {
    static var DEVELOPMENT = "mobile-16e8e500-80d2-4bb5-9d4f-8219381a90da"
}

class DevCycleManager {
    
    var client: DVCClient?
    static let shared = DevCycleManager()
    
    func initialize(user: DVCUser) {
        let options = DVCOptions.builder()
                                .logLevel(.debug)
                                .build()
        
        guard let client = try? DVCClient.builder()
                .environmentKey(DevCycleKeys.DEVELOPMENT)
                .user(user)
                .options(options)
                .build(onInitialized: nil)
        else {
            return
        }
        self.client = client
    }
}
