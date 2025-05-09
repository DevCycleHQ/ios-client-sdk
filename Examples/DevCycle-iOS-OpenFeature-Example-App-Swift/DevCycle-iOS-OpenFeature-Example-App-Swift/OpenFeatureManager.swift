//
//  DevCycleManager.swift
//  DevCycle-Example-App
//
//

import DevCycle
import Foundation
import OpenFeature

struct DevCycleKeys {
    static var DEVELOPMENT = "YOUR_DEVCYCLE_MOBILE_KEY_HERE"
}

class OpenFeatureManager {
    public var provider: DevCycleProvider?
    static let shared = OpenFeatureManager()

    func initialize(user: EvaluationContext?) {
        let options = DevCycleOptions.builder()
            .logLevel(.debug)
            .build()

        let dvcProvider = DevCycleProvider(sdkKey: DevCycleKeys.DEVELOPMENT, options: options)
        self.provider = dvcProvider

        Task {
            await OpenFeatureAPI.shared.setProviderAndWait(
                provider: dvcProvider, initialContext: user)
        }
    }
}
