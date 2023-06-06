//
//  DVCConfig.swift
//  DevCycle
//
//

import Foundation

open class DVCConfig {
    var sdkKey: String
    var user: DVCUser
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
    
    init(sdkKey: String, user: DVCUser) {
        self.sdkKey = sdkKey
        self.user = user
    }
}
