//
//  DevCycleManager.swift
//  DevCycle-MacOS-Example-App
//

import DevCycle
import Foundation

struct DevCycleKeys {
    static var DEVELOPMENT = "<DEVCYCLE_MOBILE_SDK_KEY>"
}

class DevCycleManager {
    private var client: DevCycleClient?
    private var initializationTask: Task<DevCycleClient?, Never>?
    static let shared = DevCycleManager()

    func initialize(user: DevCycleUser) {
        guard initializationTask == nil else { return }
        initializationTask = Task {
            let options = DevCycleOptions.builder()
                .build()
            let client = try? await DevCycleClient.builder()
                .sdkKey(DevCycleKeys.DEVELOPMENT)
                .user(user)
                .options(options)
                .build()
            self.client = client
            return client
        }
    }

    var clientAsync: DevCycleClient? {
        get async {
            return await initializationTask?.value
        }
    }
}
