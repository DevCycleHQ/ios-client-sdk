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
        print("DVC Manager Initialize")
        guard initializationTask == nil else { return }
        initializationTask = Task {
            let options = DevCycleOptions.builder()
                .build()
            let client = try? await DevCycleClient.builder()
                .sdkKey(DevCycleKeys.DEVELOPMENT)
                .user(user)
                .options(options)
                .build()
            print("DVC Manager ")
            self.client = client
            return client
        }
    }

    var clientAsync: DevCycleClient? {
        get async {
            print("Get clientAsync")
            return await initializationTask?.value
        }
    }
}
