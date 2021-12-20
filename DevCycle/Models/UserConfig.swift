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

public struct UserConfig {
    var environment: KeyedProperty
    var featureVariationMap: [String: String]
    var features: [String: Feature]
    var variables: [String: Variable]
    var project: KeyedProperty
    
    init(from dictionary: [String:Any]) throws {
        guard let environment = dictionary["environment"] as? [String: String] else { throw UserConfigError.MissingInConfig("environment") }
        guard let project = dictionary["project"] as? [String: String] else { throw UserConfigError.MissingInConfig("project") }
        guard let featureVariationMap = dictionary["featureVariationMap"] as? [String: String] else { throw UserConfigError.MissingInConfig("featureVariationMap") }
        guard var featureMap = dictionary["features"] as? [String: Any] else { throw UserConfigError.MissingInConfig("features") }
        guard var variablesMap = dictionary["variables"] as? [String: Any] else { throw UserConfigError.MissingInConfig("variables") }
        self.environment = try KeyedProperty(from: environment, name: "environment")
        self.project = try KeyedProperty(from: project, name: "project")
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

public struct KeyedProperty {
    var key: String
    var _id: String
    
    init (from dictionary: [String: String], name: String) throws {
        guard let key = dictionary["key"] else { throw UserConfigError.MissingProperty("key in \(name)") }
        guard let id = dictionary["_id"] else { throw UserConfigError.MissingProperty("_id in \(name)") }
        self.key = key
        self._id = id
    }
}

public struct Feature {
    var _id: String
    var _variation: String
    var key: String
    var type: String
    
    init (from dictionary: [String: String]) throws {
        guard let id = dictionary["_id"] else { throw UserConfigError.MissingProperty("_id in Feature object") }
        guard let variation = dictionary["_variation"] else { throw UserConfigError.MissingProperty("_variation in Feature object") }
        guard let key = dictionary["key"] else { throw UserConfigError.MissingProperty("key in Feature object") }
        guard let type = dictionary["type"] else { throw UserConfigError.MissingProperty("type in Feature object") }
        self._id = id
        self._variation = variation
        self.key = key
        self.type = type
    }
}

public struct Variable {
    var _id: String
    var key: String
    var type: String
    var value: Any
    var evalReason: String?
    
    init (from dictionary: [String: Any]) throws {
        guard let id = dictionary["_id"] as? String else { throw UserConfigError.MissingProperty("_id in Variable object") }
        guard let key = dictionary["key"] as? String else { throw UserConfigError.MissingProperty("key in Variable object") }
        guard let type = dictionary["type"] as? String else { throw UserConfigError.MissingProperty("type in Variable object") }
        guard let value = dictionary["value"] else { throw UserConfigError.MissingProperty("value in Variable object") }
        self._id = id
        self.key = key
        self.type = type
        self.value = value
        self.evalReason = dictionary["evalReason"] as? String
    }
}
