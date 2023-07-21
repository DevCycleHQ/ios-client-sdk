//
//  DVCConfig.swift
//  DevCycle
//
//

import Foundation

public class DVCConfig {
    var sdkKey: String
    var user: DevCycleUser
    var userConfig: UserConfig? {
        didSet {
            if let userConfig = self.userConfig {
                NotificationCenter.default.post(
                    name: Notification.Name(NotificationNames.NewUserConfig),
                    object: self,
                    userInfo: ["new-user-config" : userConfig]
                )
            }
        }
    }
    
    init(sdkKey: String, user: DevCycleUser) {
        self.sdkKey = sdkKey
        self.user = user
    }
}
