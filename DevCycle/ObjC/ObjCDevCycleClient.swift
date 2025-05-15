//
//  ObjCDevCycleClient.swift
//  DevCycle
//
//

import Foundation

@objc(DevCycleClient)
public class ObjCDevCycleClient: NSObject {
    var client: DevCycleClient?

    @objc(initialize:user:)
    public static func initialize(
        sdkKey: String,
        user: ObjCDevCycleUser
    ) -> ObjCDevCycleClient {
        return ObjCDevCycleClient(
            sdkKey: sdkKey,
            user: user,
            options: nil,
            onInitialized: nil
        )
    }

    @objc(initialize:user:options:)
    public static func initialize(
        sdkKey: String,
        user: ObjCDevCycleUser,
        options: ObjCDevCycleOptions?
    ) -> ObjCDevCycleClient {
        return ObjCDevCycleClient(
            sdkKey: sdkKey,
            user: user,
            options: options,
            onInitialized: nil
        )
    }

    @objc(initialize:user:options:onInitialized:)
    public static func initialize(
        sdkKey: String,
        user: ObjCDevCycleUser,
        options: ObjCDevCycleOptions?,
        onInitialized: ((Error?) -> Void)?
    ) -> ObjCDevCycleClient {
        return ObjCDevCycleClient(
            sdkKey: sdkKey,
            user: user,
            options: options,
            onInitialized: onInitialized
        )
    }

    init(
        sdkKey: String,
        user: ObjCDevCycleUser,
        options: ObjCDevCycleOptions?,
        onInitialized: ((Error?) -> Void)?
    ) {
        do {
            if sdkKey == nil || sdkKey == "" {
                Log.error("SDK Key missing", tags: ["build", "objc"])
                throw ObjCClientErrors.MissingSDKKey
            } else if user == nil {
                Log.error("User missing", tags: ["build", "objc"])
                throw ObjCClientErrors.MissingUser
            } else if user.userId?.isEmpty == true {
                throw ObjCClientErrors.InvalidUser
            }

            let dvcUser = try user.buildDevCycleUser()

            var clientBuilder = DevCycleClient.builder()
                .sdkKey(sdkKey)
                .user(dvcUser)

            if let dvcOptions = options {
                clientBuilder = clientBuilder.options(dvcOptions.buildDevCycleOptions())
            }

            guard let client = try? clientBuilder.build(onInitialized: onInitialized)
            else {
                Log.error("Error creating DevCycleClient", tags: ["build", "objc"])
                throw ObjCClientErrors.InvalidClient
            }
            self.client = client
        } catch {
            if let onInitializedCallback = onInitialized {
                onInitializedCallback(error)
            } else {
                Log.error("Error initializing DevCycleClient: \(error)")
            }
        }
    }

    @objc(identifyUser:callback:)
    public func identify(
        user: ObjCDevCycleUser, callback: ((Error?, [String: ObjCVariable]?) -> Void)?
    ) {
        do {
            guard let client = self.client else { return }
            guard user.userId != nil else {
                callback?(NSError(), nil)
                return
            }
            let dvcUser = try user.buildDevCycleUser()

            let createdUser = DevCycleUser()
            createdUser.userId = user.userId!
            createdUser.isAnonymous = false
            createdUser.update(with: dvcUser)

            try? client.identifyUser(
                user: createdUser,
                callback: { error, variables in
                    guard let callback = callback else { return }
                    callback(error, self.variableToObjCVariable(variables))
                })
        } catch {
            if let idCallback = callback {
                idCallback(error, nil)
            } else {
                Log.error("Error calling DevCycleClient identifyUser:callback: \(error)")
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

    @objc public func stringVariableValue(key: String, defaultValue: String) -> String {
        guard let client = self.client else {
            return defaultValue
        }
        return client.variableValue(key: key, defaultValue: defaultValue)
    }
    @objc public func numberVariableValue(key: String, defaultValue: NSNumber) -> NSNumber {
        guard let client = self.client else {
            return defaultValue
        }
        return client.variableValue(key: key, defaultValue: defaultValue)
    }
    @objc public func boolVariableValue(key: String, defaultValue: Bool) -> Bool {
        guard let client = self.client else {
            return defaultValue
        }
        return client.variableValue(key: key, defaultValue: defaultValue)
    }
    @objc public func jsonVariableValue(key: String, defaultValue: NSDictionary) -> NSDictionary {
        guard let client = self.client else {
            return defaultValue
        }
        return client.variableValue(key: key, defaultValue: defaultValue)
    }

    @objc public func stringVariable(key: String, defaultValue: String) -> ObjCDVCVariable {
        guard let client = self.client else {
            return objcDefaultVariable(key: key, defaultValue: defaultValue)
        }
        return ObjCDVCVariable(client.variable(key: key, defaultValue: defaultValue))
    }
    @objc public func numberVariable(key: String, defaultValue: NSNumber) -> ObjCDVCVariable {
        guard let client = self.client else {
            return objcDefaultVariable(key: key, defaultValue: defaultValue)
        }
        return ObjCDVCVariable(client.variable(key: key, defaultValue: defaultValue))
    }
    @objc public func boolVariable(key: String, defaultValue: Bool) -> ObjCDVCVariable {
        guard let client = self.client else {
            return objcDefaultVariable(key: key, defaultValue: defaultValue)
        }
        return ObjCDVCVariable(client.variable(key: key, defaultValue: defaultValue))
    }
    @objc public func jsonVariable(key: String, defaultValue: NSDictionary) -> ObjCDVCVariable {
        guard let client = self.client else {
            return objcDefaultVariable(key: key, defaultValue: defaultValue)
        }
        return ObjCDVCVariable(client.variable(key: key, defaultValue: defaultValue))
    }

    func objcDefaultVariable<T>(key: String, defaultValue: T) -> ObjCDVCVariable {
        return ObjCDVCVariable(
            DVCVariable<T>(
                key: key,
                value: nil,
                defaultValue: defaultValue,
                evalReason: nil
            )
        )
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
    public func track(_ event: ObjCDevCycleEvent) throws {
        guard let client = self.client else { return }
        let dvcEvent = try event.buildDevCycleEvent()
        client.track(dvcEvent)
    }

    @objc public func flushEvents() {
        Task {
            try? await self.client?.flushEvents()
        }
    }
}

extension ObjCDevCycleClient {
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

@available(*, deprecated, message: "Use DevCycleClient")
@objc(DVCClient)
public class ObjCDVCClient: ObjCDevCycleClient {}
