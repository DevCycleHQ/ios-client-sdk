//
//  ObjCDVCClient.swift
//  DevCycle
//
//

import Foundation

@objc(DVCClientBuilder)
public class ObjCClientBuilder: NSObject {
    @objc public var environmentKey: String?
    @objc public var user: ObjCDVCUser?
    @objc public var options: ObjCDVCOptions?
}

@objc(DVCClient)
public class ObjCDVCClient: NSObject {
    var client: DVCClient?
    @objc public var eventQueue: [ObjCDVCEvent] = []
    
    @objc(build:block:onInitialized:)
    public static func build(
        block: ((ObjCClientBuilder) -> Void),
        onInitialized: ((Error?) -> Void)?
    ) throws -> ObjCDVCClient {
        let builder = ObjCClientBuilder()
        block(builder)
        let client = try ObjCDVCClient(builder: builder, onInitialized: onInitialized)
        return client
    }
    
    @objc(initialize:user:err:)
    public static func initialize(
        environmentKey: String,
        user: ObjCUserBuilder
    ) throws -> ObjCDVCClient {
        try self.initialize(
            environmentKey: environmentKey,
            user: user,
            options: nil,
            onInitialized: nil
        )
    }
        
    @objc(initialize:user:options:err:)
    public static func initialize(
        environmentKey: String,
        user: ObjCUserBuilder,
        options: ObjCOptionsBuilder?
    ) throws -> ObjCDVCClient {
        try self.initialize(
            environmentKey: environmentKey,
            user: user,
            options: options,
            onInitialized: nil
        )
    }
        
    @objc(initialize:user:options:err:onInitialized:)
    public static func initialize(
        environmentKey: String,
        user: ObjCUserBuilder,
        options: ObjCOptionsBuilder?,
        onInitialized: ((Error?) -> Void)?
    ) throws -> ObjCDVCClient {
        let dvcUser = try ObjCDVCUser(builder: user)
        let dvcOptions = options != nil ? ObjCDVCOptions(builder: options!) : nil
        
        let builder = ObjCClientBuilder()
        builder.environmentKey = environmentKey
        builder.user = dvcUser
        builder.options = dvcOptions
        let client = try ObjCDVCClient(builder: builder, onInitialized: onInitialized)
        return client
    }
    
    init(builder: ObjCClientBuilder, onInitialized: ((Error?) -> Void)?) throws {
        guard let environmentKey = builder.environmentKey,
              let objcUser = builder.user,
              let user = objcUser.user
        else {
            if (builder.environmentKey == nil) {
                Log.error("Environment key missing", tags: ["build", "objc"])
                throw ObjCClientErrors.MissingEnvironmentKey
            } else if (builder.user == nil) {
                Log.error("User missing", tags: ["build", "objc"])
                throw ObjCClientErrors.MissingUser
            } else if (builder.user != nil && builder.user?.user == nil) {
                Log.error("User is invalid", tags: ["build", "objc"])
                throw ObjCClientErrors.InvalidUser
            }
            return
        }
        
        var clientBuilder = DVCClient.builder()
            .environmentKey(environmentKey)
            .user(user)
        
        if let options = builder.options?.options {
            clientBuilder = clientBuilder.options(options)
        }
        
        guard let client = try? clientBuilder.build(onInitialized: onInitialized)
        else {
            Log.error("Error creating client", tags: ["build", "objc"])
            throw ObjCClientErrors.InvalidClient
        }
        self.client = client
    }
    
    
    @objc(identifyUser:user:)
    public func identify(user: ObjCDVCUser, callback: ((Error?, [String: ObjCVariable]?) -> Void)?) {
        guard let client = self.client else { return }
        guard user.userId != nil else {
            callback?(NSError(), nil)
            return
        }
        let createdUser = DVCUser()
        createdUser.update(with: user)
        
        try? client.identifyUser(user: createdUser, callback: { error, variables in
            guard let callback = callback else { return }
            callback(error, self.variableToObjCVariable(variables: variables))
        })
    }
    
    @objc(resetUser:)
    public func reset(callback: ((Error?, [String: ObjCVariable]) -> Void)?) {
        guard let client = self.client else { return }
        try? client.resetUser { error, variables in
            guard let callback = callback else { return }
            callback(error, self.variableToObjCVariable(variables: variables))
        }
    }
    
    @objc public func variable(key: String, defaultValue: Any) throws -> ObjCDVCVariable {
        var variable: ObjCDVCVariable
        if let variableFromConfig = self.client?.config?.userConfig?.variables[key] {
            variable = try ObjCDVCVariable(
                key: key,
                type: variableFromConfig.type,
                evalReason: variableFromConfig.evalReason,
                value: variableFromConfig.value,
                defaultValue: defaultValue
            )
        } else {
            variable = try ObjCDVCVariable(
                key: key,
                type: nil,
                evalReason: nil,
                value: nil,
                defaultValue: defaultValue
            )
        }
        
        client?.configCompletionHandlers.append({ error in
            if let variableFromApi = self.client?.config?.userConfig?.variables[key] {
                try? variable.update(from: variableFromApi)
            }
        })
        
        self.client?.updateAggregateEvents(variableKey: variable.key, variableIsDefaulted: variable.isDefaulted)
        
        return variable
    }
    
    @objc public func allFeatures() -> [String: ObjCFeature]? {
        guard let client = self.client else { return [:] }
        return featureToObjCFeature(features: client.allFeatures())
    }
    
    @objc public func allVariables() -> [String: ObjCVariable]? {
        guard let client = self.client else { return [:] }
        return variableToObjCVariable(variables: client.allVariables())
    }
    
    @objc public func track(_ event: ObjCDVCEvent) {
        let dvcEvent: DVCEvent = DVCEvent(
            type: event.type,
            target: event.target ?? nil,
            clientDate: event.clientDate as Date? ?? Date(),
            value: (event.value as! Int),
            metaData: (event.metaData as! [String: Any])
        )
        self.client?.track(dvcEvent)
    }
    
    @objc public func flushEvents() {
        self.client?.flushEvents()
    }
}

extension ObjCDVCClient {
    func featureToObjCFeature(features: [String: Feature]?) -> [String: ObjCFeature] {
        var objcFeatures: [String: ObjCFeature] = [:]
        if let features = features {
            for (key, value) in features {
                objcFeatures[key] = ObjCFeature.create(from: value)
            }
        }
        return objcFeatures
    }
    
    func variableToObjCVariable(variables: [String: Variable]?) -> [String: ObjCVariable] {
        var objcVariables: [String: ObjCVariable] = [:]
        if let variables = variables {
            for (key, value) in variables {
                objcVariables[key] = ObjCVariable.create(from: value)
            }
        }
        return objcVariables
    }
}
