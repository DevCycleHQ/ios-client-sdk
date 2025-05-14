//
//  DevCycleManager.swift
//  DevCycle-Example-App
//
//

import DevCycle
import DevCycleOpenFeatureProvider
import Foundation
import OpenFeature

struct DevCycleKeys {
    static var DEVELOPMENT = "<DEVCYCLE_MOBILE_SDK_KEY>"
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
