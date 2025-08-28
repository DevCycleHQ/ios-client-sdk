//
//  DVCConfig.swift
//  DevCycle
//
//

import Foundation

public class DVCConfig {
    var sdkKey: String
    var user: DevCycleUser
    private let userConfigQueue = DispatchQueue(label: "com.devcycle.userConfigQueue")
    var userConfig: UserConfig?
    
    init(sdkKey: String, user: DevCycleUser) {
        self.sdkKey = sdkKey
        self.user = user
    }
    
    func getUserConfig() -> UserConfig? {
        return userConfigQueue.sync {
            return self.userConfig
        }
    }
    
    func setUserConfig(config: UserConfig?) {
        var configToNotify: UserConfig?
        
        userConfigQueue.sync {
            self.userConfig = config
            configToNotify = config
        }
        
        // Post notification outside of the lock to avoid potential deadlocks
        if let userConfig = configToNotify {
            DispatchQueue.main.async {
                NotificationCenter.default.post(
                    name: Notification.Name(NotificationNames.NewUserConfig),
                    object: self,
                    userInfo: ["new-user-config" : userConfig]
                )
            }
        }
    }
}
