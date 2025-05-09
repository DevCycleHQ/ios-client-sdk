//
//  DevCycleManager.swift
//  DevCycle-Example-App
//
//

import DevCycle
import Foundation

struct DevCycleKeys {
    static var DEVELOPMENT = "YOUR_DEVCYCLE_MOBILE_KEY_HERE"
}

class DevCycleManager {

    var client: DevCycleClient?
    static let shared = DevCycleManager()

    func initialize(user: DevCycleUser) {
        let options = DevCycleOptions.builder()
            //                                .logLevel(.debug)
            .build()

        guard
            let client = try? DevCycleClient.builder()
                .sdkKey(DevCycleKeys.DEVELOPMENT)
                .user(user)
                .options(options)
                .build(onInitialized: nil)
        else {
            return
        }
        self.client = client
    }
}
