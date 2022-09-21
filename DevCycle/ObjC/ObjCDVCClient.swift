//
//  ObjCDVCClient.swift
//  DevCycle
//
//

import Foundation

@objc(DVCClient)
public class ObjCDVCClient: NSObject {
    var client: DVCClient?
    
    @objc(initialize:user:)
    public static func initialize(
        environmentKey: String,
        user: ObjCUser
    ) -> ObjCDVCClient {
        return ObjCDVCClient(
            environmentKey: environmentKey,
            user: user,
            options: nil,
            onInitialized: nil
        )
    }
        
    @objc(initialize:user:options:)
    public static func initialize(
        environmentKey: String,
        user: ObjCUser,
        options: ObjCOptions?
    ) -> ObjCDVCClient {
        return ObjCDVCClient(
            environmentKey: environmentKey,
            user: user,
            options: options,
            onInitialized: nil
        )
    }
        
    @objc(initialize:user:options:onInitialized:)
    public static func initialize(
        environmentKey: String,
        user: ObjCUser,
        options: ObjCOptions?,
        onInitialized: ((Error?) -> Void)?
    ) -> ObjCDVCClient {
        return ObjCDVCClient(
            environmentKey: environmentKey,
            user: user,
            options: options,
            onInitialized: onInitialized
        )
    }
    
    init(
        environmentKey: String,
        user: ObjCUser,
        options: ObjCOptions?,
        onInitialized: ((Error?) -> Void)?
    ) {
        do {
            if (environmentKey == nil || environmentKey == "") {
                Log.error("Environment key missing", tags: ["build", "objc"])
                throw ObjCClientErrors.MissingEnvironmentKey
            } else if (user == nil) {
                Log.error("User missing", tags: ["build", "objc"])
                throw ObjCClientErrors.MissingUser
            } else if (user.userId?.isEmpty == true) {
                throw ObjCClientErrors.InvalidUser
            }
            
            let dvcUser = try user.buildDVCUser()
            
            var clientBuilder = DVCClient.builder()
                .environmentKey(environmentKey)
                .user(dvcUser)
            
            if let dvcOptions = options {
                clientBuilder = clientBuilder.options(dvcOptions.buildDVCOptions())
            }
            
            guard let client = try? clientBuilder.build(onInitialized: onInitialized)
            else {
                Log.error("Error creating client", tags: ["build", "objc"])
                throw ObjCClientErrors.InvalidClient
            }
            self.client = client
        } catch {
            if let onInitializedCallback = onInitialized {
                onInitializedCallback(error)
            } else {
                Log.error("Error initializing DVCClient: \(error)")
            }
        }
    }
    
    
    @objc(identifyUser:callback:)
    public func identify(user: ObjCUser, callback: ((Error?, [String: ObjCVariable]?) -> Void)?) {
        do {
            guard let client = self.client else { return }
            guard user.userId != nil else {
                callback?(NSError(), nil)
                return
            }
            let dvcUser = try user.buildDVCUser()

            let createdUser = DVCUser()
            createdUser.userId = user.userId!
            createdUser.isAnonymous = false
            createdUser.update(with: dvcUser)
            
            try? client.identifyUser(user: createdUser, callback: { error, variables in
                guard let callback = callback else { return }
                callback(error, self.variableToObjCVariable(variables))
            })
        } catch {
            if let idCallback = callback {
                idCallback(error, nil)
            } else {
                Log.error("Error calling DVCClient identifyUser:callback: \(error)")
            }
        }
    }
    
    @objc(resetUser:)
    public func reset(callback: ((Error?, [String: ObjCVariable]) -> Void)?) {
        guard let client = self.client else { return }
        try? client.resetUser { error, variables in
            guard let callback = callback else { return }
            callback(error, self.variableToObjCVariable(variables))
        }
    }
    
    @objc public func stringVariable(key: String, defaultValue: String) -> ObjCDVCVariable {
        return variable(key: key, defaultValue: defaultValue)
    }
    
    @objc public func numberVariable(key: String, defaultValue: NSNumber) -> ObjCDVCVariable {
        return variable(key: key, defaultValue: defaultValue)
    }
    
    @objc public func boolVariable(key: String, defaultValue: Bool) -> ObjCDVCVariable {
        return variable(key: key, defaultValue: defaultValue)
    }
    
    @objc public func jsonVariable(key: String, defaultValue: NSObject) -> ObjCDVCVariable {
        return variable(key: key, defaultValue: defaultValue)
    }
    
    func variable<T>(key: String, defaultValue: T) -> ObjCDVCVariable {
        guard let client = self.client else {
            return ObjCDVCVariable(
                DVCVariable<T>(
                    key: key,
                    type: String(describing: T.self),
                    value: nil,
                    defaultValue: defaultValue,
                    evalReason: nil
                )
            )
        }

        return ObjCDVCVariable(client.variable(key: key, defaultValue: defaultValue))
    }
    
    @objc public func allFeatures() -> [String: ObjCFeature]? {
        guard let client = self.client else { return [:] }
        return featureToObjCFeature(client.allFeatures())
    }
    
    @objc public func allVariables() -> [String: ObjCVariable]? {
        guard let client = self.client else { return [:] }
        return variableToObjCVariable(client.allVariables())
    }
    
    @objc(track:err:)
    public func track(_ event: ObjCDVCEvent) throws {
        guard let client = self.client else { return }
        let dvcEvent = try event.buildDVCEvent()
        client.track(dvcEvent)
    }
    
    @objc public func flushEvents() {
        self.client?.flushEvents()
    }
}

extension ObjCDVCClient {
    func featureToObjCFeature(_ features: [String: Feature]?) -> [String: ObjCFeature] {
        var objcFeatures: [String: ObjCFeature] = [:]
        if let features = features {
            for (key, value) in features {
                objcFeatures[key] = ObjCFeature(value)
            }
        }
        return objcFeatures
    }
    
    func variableToObjCVariable(_ variables: [String: Variable]?) -> [String: ObjCVariable] {
        var objcVariables: [String: ObjCVariable] = [:]
        if let variables = variables {
            for (key, value) in variables {
                objcVariables[key] = ObjCVariable(value)
            }
        }
        return objcVariables
    }
}
