//
//  DevCycleManager.swift
//  DevCycle-Example-App
//
//

import Foundation
import DevCycle

struct DevCycleKeys {
    static var DEVELOPMENT = "mobile-af49df8f-f39b-4863-a960-c0dc6165874a"
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
