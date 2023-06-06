//
//  DevCycleManager.swift
//  DevCycle-MacOS-Example-App
//

import Foundation
import DevCycle

struct DevCycleKeys {
    static var DEVELOPMENT = "<YOUR SDK KEY>"
}

enum DevCycleManagerError: Error {
    case MissingClient
}

class DevCycleManager {
    var client: DVCClient?
    static let shared = DevCycleManager()
    
    func initialize(user: DVCUser) {
        let options = DVCOptions.builder()
                                .logLevel(.debug)
                                .build()
        
        guard let client = try? DVCClient.builder()
                .sdkKey(DevCycleKeys.DEVELOPMENT)
                .user(user)
                .options(options)
                .build(onInitialized: nil)
        else {
            return
        }
        self.client = client
    }
    
    func variable<T>(key: String, defaultValue: T) throws -> DVCVariable<T>  {
        guard let client = self.client else {
            throw DevCycleManagerError.MissingClient
        }
        let variable = client.variable(key: key, defaultValue: defaultValue)
        if (variable.isDefaulted) {
            // track variableDefaulted event
        } else {
            // track variableEvaluated event
        }
        return variable
    }
}
