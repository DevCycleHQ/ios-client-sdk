//
//  DVCConfig.swift
//  DevCycle
//
//

import Foundation

public class DVCConfig {
    var environmentKey: String
    var user: DVCUser
    var userConfig: UserConfig? {
        didSet {
            if let userConfig = self.userConfig {
                NotificationCenter.default.post(name: Notification.Name(NotificationNames.NewUserConfig), object: self, userInfo: ["new-user-config" : userConfig])
            }
        }
    }
    
    init(environmentKey: String, user: DVCUser) {
        self.environmentKey = environmentKey
        self.user = user
    }
}
