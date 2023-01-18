//
//  DevCycleManager.swift
//  DevCycle-MacOS-Example-App
//

import Foundation
import DevCycle

struct DevCycleKeys {
    static var DEVELOPMENT = "dvc_mobile_7b9d8183_e37e_421a_96f9_63010ae103f8_83be92f"
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
