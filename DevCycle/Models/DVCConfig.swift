//
//  DVCConfig.swift
//  DevCycle
//
//  Created by Jason Salaber on 2021-11-30.
//

import Foundation

public class DVCConfig {
    var environmentKey: String
    var user: DVCUser
    var userConfig: UserConfig?
    
    init(environmentKey: String, user: DVCUser) {
        self.environmentKey = environmentKey
        self.user = user
    }
}
