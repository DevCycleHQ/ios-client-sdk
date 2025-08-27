//
//  DVCConfig.swift
//  DevCycle
//
//

import Foundation

public class DVCConfig {
    var sdkKey: String
    var user: DevCycleUser
    private let userConfigQueue = DispatchQueue(
        label: "com.devcycle.userConfig", attributes: .concurrent)
    private var _userConfig: UserConfig?

    var userConfig: UserConfig? {
        get {
            return userConfigQueue.sync { _userConfig }
        }
        set {
            // Synchronously set using a barrier to preserve existing semantics
            userConfigQueue.async(flags: .barrier) {
                self._userConfig = newValue
                if let userConfig = newValue {
                    DispatchQueue.main.async {
                        NotificationCenter.default.post(
                            name: Notification.Name(NotificationNames.NewUserConfig),
                            object: self,
                            userInfo: ["new-user-config": userConfig]
                        )
                    }
                }
            }
            // Fence: wait for the async barrier write above to complete so subsequent reads
            // observe the new value immediately (mirrors original didSet synchronous behavior).
            userConfigQueue.sync {}
        }
    }

    init(sdkKey: String, user: DevCycleUser) {
        self.sdkKey = sdkKey
        self.user = user
    }
}
