//
//  UserConfig.swift
//  DevCycle
//
//

import Foundation

enum UserConfigError: Error {
    case MissingInConfig(String)
    case MissingProperty(String)
}

enum UserConfigCodingKeys: String, CodingKey {
    case project, environment, featureVariationMap, features, variables
}

enum ProjectCodingKeys: String, CodingKey {
    case _id, key, a0_organization, settings
}

enum SettingsCodingKeys: String, CodingKey {
    case edgeDB
}

enum EdgeDBCodingKeys: String, CodingKey {
    case enabled
}

enum EnvironmentCodingKeys: String, CodingKey {
    case _id, key
}

enum FeatureCodingKeys: String, CodingKey {
    case _id, _variation, key, type, variationKey, variationName
}

enum VariablesCodingKeys: String, CodingKey {
    case _id, key, type, value, evalReason
}

public struct UserConfig: Encodable {
    var project: Project
    var environment: Environment
    var featureVariationMap: [String: String]
    var features: [String: Feature]
    var variables: [String: Variable]
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: UserConfigCodingKeys.self)
        try container.encode(project, forKey: .project)
        try container.encode(environment, forKey: .environment)
        try container.encode(featureVariationMap, forKey: .featureVariationMap)
        try container.encode(features, forKey: .features)
        try container.encode(variables, forKey: .variables)
    }
    
    init(from dictionary: [String:Any]) throws {
        guard let environment = dictionary["environment"] as? [String: Any] else { throw UserConfigError.MissingInConfig("environment") }
        guard let project = dictionary["project"] as? [String: Any] else { throw UserConfigError.MissingInConfig("project") }
        guard let featureVariationMap = dictionary["featureVariationMap"] as? [String: String] else { throw UserConfigError.MissingInConfig("featureVariationMap") }
        guard var featureMap = dictionary["features"] as? [String: Any] else { throw UserConfigError.MissingInConfig("features") }
        guard var variablesMap = dictionary["variables"] as? [String: Any] else { throw UserConfigError.MissingInConfig("variables") }
        
        self.project = try Project(from: project)
        self.environment = try Environment(from: environment)
        self.featureVariationMap = featureVariationMap
        
        let featureKeys = Array(featureMap.keys)
        let variableKeys = Array(variablesMap.keys)
        
        for key in featureKeys {
            if let featureDict = featureMap[key] as? [String:String]
            {
                let feature = try Feature(from: featureDict)
                featureMap[key] = feature
            }
        }
        
        for key in variableKeys {
            if let variableDict = variablesMap[key] as? [String:Any]
            {
                let variable = try Variable(from: variableDict)
                variablesMap[key] = variable
            }
        }
        
        self.features = featureMap as! [String: Feature]
        self.variables = variablesMap as! [String: Variable]
    }
}

public struct Project: Encodable {
    var _id: String
    var key: String
    var settings: Settings
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: ProjectCodingKeys.self)
        try container.encode(_id, forKey: ._id)
        try container.encode(key, forKey: .key)
        try container.encode(settings, forKey: .settings)
    }
    
    init (from dictionary: [String: Any]) throws {
        guard let key = dictionary["key"] as? String else { throw UserConfigError.MissingProperty("key in Project") }
        guard let id = dictionary["_id"] as? String else { throw UserConfigError.MissingProperty("_id in Project") }
        let settings = dictionary["settings"] as? [String:Any]
        self._id = id
        self.key = key
        self.settings = Settings(from: settings ?? ["edgeDB": ["enabled": false]])
    }
}

struct Settings: Encodable {
    var edgeDB: EdgeDB
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: SettingsCodingKeys.self)
        try container.encode(edgeDB, forKey: .edgeDB)
    }
    
    init(from dictionary: [String: Any]) {
        let edgeDB = dictionary["edgeDB"] as? [String: Any]
        
        self.edgeDB = EdgeDB(from: edgeDB ?? ["enabled": false])
    }
}

struct EdgeDB: Encodable {
    var enabled: Bool
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: EdgeDBCodingKeys.self)
        try container.encode(enabled, forKey: .enabled)
    }
    
    init(from dictionary: [String: Any]) {
        let enabled = dictionary["enabled"] as? Bool
        
        self.enabled = enabled ?? false
    }
}

public struct Environment: Codable {
    var _id: String
    var key: String
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: EnvironmentCodingKeys.self)
        try container.encode(_id, forKey: ._id)
        try container.encode(key, forKey: .key)
    }
    
    init (from dictionary: [String: Any]) throws {
        guard let key = dictionary["key"] as? String else { throw UserConfigError.MissingProperty("key in Environment") }
        guard let id = dictionary["_id"] as? String else { throw UserConfigError.MissingProperty("_id in Environment") }
        self._id = id
        self.key = key
    }
}

public struct Feature: Encodable {
    var _id: String
    var _variation: String
    var key: String
    var type: String
    var variationKey: String
    var variationName: String
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: FeatureCodingKeys.self)
        try container.encode(_id, forKey: ._id)
        try container.encode(_variation, forKey: ._variation)
        try container.encode(key, forKey: .key)
        try container.encode(type, forKey: .type)
        try container.encode(variationKey, forKey: .variationKey)
        try container.encode(variationName, forKey: .variationName)
    }
    
    init (from dictionary: [String: String]) throws {
        guard let id = dictionary["_id"] else { throw UserConfigError.MissingProperty("_id in Feature object") }
        guard let variation = dictionary["_variation"] else { throw UserConfigError.MissingProperty("_variation in Feature object") }
        guard let key = dictionary["key"] else { throw UserConfigError.MissingProperty("key in Feature object") }
        guard let type = dictionary["type"] else { throw UserConfigError.MissingProperty("type in Feature object") }
        guard let variationKey = dictionary["variationKey"] else { throw UserConfigError.MissingProperty("variationKey in Feature object") }
        guard let variationName = dictionary["variationName"] else { throw UserConfigError.MissingProperty("variationName in Feature object") }
        self._id = id
        self._variation = variation
        self.key = key
        self.type = type
        self.variationKey = variationKey
        self.variationName = variationName
    }
}

public struct Variable: Codable {
    var _id: String
    var key: String
    var type: String
    var value: Any
    var evalReason: String?
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: VariablesCodingKeys.self)
        try container.encode(_id, forKey: ._id)
        try container.encode(key, forKey: .key)
        try container.encode(type, forKey: .type)
        try container.encode(evalReason, forKey: .evalReason)
        if let boolValue = value as? Bool {
            try container.encode(boolValue, forKey: .value)
        } else if let stringValue = value as? String {
            try container.encode(stringValue, forKey: .value)
        } else if let numValue = value as? Float {
            try container.encode(numValue, forKey: .value)
        } else if let jsonValue = value as? [String: Any] {
            let data = try JSONSerialization.data(withJSONObject: jsonValue, options: [.fragmentsAllowed])
            try container.encode(data, forKey: .value)
        }
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: VariablesCodingKeys.self)
        self._id = try container.decode(String.self, forKey: ._id)
        self.key = try container.decode(String.self, forKey: ._id)
        self.type = try container.decode(String.self, forKey: ._id)
        
        if let stringValue = try? container.decode(String.self, forKey: .value) {
            self.value = stringValue
        } else if let numValue = try? container.decode(Float.self, forKey: .value) {
            self.value = numValue
        } else if let boolValue = try? container.decode(Bool.self, forKey: .value) {
            self.value = boolValue
        } else if let jsonValue = try? container.decode(Data.self, forKey: .value) {
            self.value = jsonValue
        } else {
            throw UserConfigError.MissingProperty("value in variable: \(key)")
        }
    }
    
    init (from dictionary: [String: Any]) throws {
        guard let id = dictionary["_id"] as? String else { throw UserConfigError.MissingProperty("_id in Variable object") }
        guard let key = dictionary["key"] as? String else { throw UserConfigError.MissingProperty("key in Variable object") }
        guard let type = dictionary["type"] as? String else { throw UserConfigError.MissingProperty("type in Variable object") }
        guard let value = dictionary["value"] else { throw UserConfigError.MissingProperty("value in Variable object") }
        self._id = id
        self.key = key
        self.type = type
        self.evalReason = dictionary["evalReason"] as? String
        
        if (type == "Boolean") {
            self.value = value as? Bool ?? value
        } else if type == "JSON" {
            let decoder = JSONDecoder()
            self.value = (value as! String).data(using: .utf8)
//            self.value = try decoder.decode([String: Any].self, from: data)
//            decoder.decode(String.self, from: data)
            self.value = value
        } else {
            self.value = value
        }
    }
}

struct AnyEncodable: Encodable {
    let value: Encodable

    func encode(to encoder: Encoder) throws {
        try value.encode(to: encoder)
    }
}
