//
//  DevCycleManager.swift
//  DevCycle-Example-App
//
//

import Foundation
import DevCycle

struct DevCycleKeys {
    static var DEVELOPMENT = "<DEVCYCLE_MOBILE_SDK_KEY>"
}

class DevCycleManager {
    
    var client: DevCycleClient?
    static let shared = DevCycleManager()
    
    func initialize(user: DevCycleUser) {
        let options = DevCycleOptions.builder()
//                                .logLevel(.debug)
                                .build()
        
        guard let client = try? DevCycleClient.builder()
                .sdkKey(DevCycleKeys.DEVELOPMENT)
                .user(user)
                .options(options)
                .build(onInitialized: nil)
        else {
            return
        }
        self.client = client
        
        let errHandler = ErrorEventHandler { error in
            print("DevCycle Error: \(error.localizedDescription)")
        }
        client.subscribe(errHandler)
        
        let initHandler = InitializedEventHandler { success in
            print("DevCycle Initialized: \(success) from subscription")
        }
        client.subscribe(initHandler)
        
        let configHandler = ConfigUpdatedEventHandler { variables in
            print("DevCycle Config Updated: \(variables)")
        }
        client.subscribe(configHandler)
        
        let variableUpdatedHandler = VariableUpdatedHandler(key: nil) { key, variable in
            print("DevCycle Variable \(key) Updated: \(variable)")
        }
        client.subscribe(variableUpdatedHandler)
        
        let variableEvalHandler = VariableEvaluatedHandler(key: nil) { key, variable in
            print("DevCycle Variable \(key) Evaluated: \(variable)")
        }
        client.subscribe(variableEvalHandler)
        
        let featureUpdatedHandler = FeatureUpdatedHandler(key: nil) { key, feature in
            print("DevCycle Feature \(key) Updated: \(feature)")
        }
        client.subscribe(featureUpdatedHandler)
    
        
        
        Timer.scheduledTimer(withTimeInterval: TimeInterval(15), repeats: false) { timer in
            print("Cleanup handlers")
            client.unsubscribe(errHandler)
            client.unsubscribe(initHandler)
            client.unsubscribe(configHandler)
            client.unsubscribe(variableUpdatedHandler)
            client.unsubscribe(variableEvalHandler)
            client.unsubscribe(featureUpdatedHandler)
        }
    }
}
