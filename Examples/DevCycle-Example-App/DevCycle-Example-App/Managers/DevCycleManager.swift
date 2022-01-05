//
//  DevCycleManager.swift
//  DevCycle-Example-App
//
//

import Foundation
import DevCycle

struct DevCycleKeys {
    static var DEVELOPMENT = "client-123fde1a-2e2b-40a7-bfac-10e47d2608f8"
}

class DevCycleManager {
    
    var client: DVCClient?
    static let shared = DevCycleManager()
    
    func initialize(user: DVCUser) {
        guard let client = try? DVCClient.builder()
                .environmentKey(DevCycleKeys.DEVELOPMENT)
                .user(user)
                .build(onInitialized: nil)
        else {
            return
        }
        self.client = client
    }
}
