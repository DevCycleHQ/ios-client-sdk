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
    var project: Project
    var environment: Environment
    var featureVariationMap: [String: String]
    var features: [String: Feature]
    var variables: [String: Variable]
    
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

public struct Project {
    var _id: String
    var key: String
    
    init (from dictionary: [String: Any]) throws {
        guard let key = dictionary["key"] as? String else { throw UserConfigError.MissingProperty("key in Project") }
        guard let id = dictionary["_id"] as? String else { throw UserConfigError.MissingProperty("_id in Project") }
        self._id = id
        self.key = key
    }
}

public struct Environment {
    var _id: String
    var key: String
    
    init (from dictionary: [String: Any]) throws {
        guard let key = dictionary["key"] as? String else { throw UserConfigError.MissingProperty("key in Environment") }
        guard let id = dictionary["_id"] as? String else { throw UserConfigError.MissingProperty("_id in Environment") }
        self._id = id
        self.key = key
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
        self.evalReason = dictionary["evalReason"] as? String
        
        if (type == "Boolean") {
            self.value = value as? Bool ?? value
        } else {
            self.value = value
        }
    }
}
