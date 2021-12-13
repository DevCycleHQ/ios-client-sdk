//
//  UserConfig.swift
//  DevCycle
//
//

import Foundation

public struct UserConfig: Decodable {
    var environment: KeyedProperty
    var featureVariationMap: [String: String]
    var features: [String: Feature]
    var variables: [String: Variable]
    var project: KeyedProperty
}

public struct KeyedProperty: Decodable {
    var key: String
    var _id: String
}

public struct Feature: Decodable {
    var _id: String
    var _variation: String
    var key: String
    var type: String
}

public struct Variable: Decodable {
    var _id: String
    var key: String
    var type: String
    var value: Any
    
    enum CodingKeys: String, CodingKey {
        case _id
        case key
        case type
        case value
    }
    
    enum JSONValue: Decodable {
        case string(String)
        case bool(Bool)
        case number(Int)
        case json([String: JSONValue])
        public init(from decoder: Decoder) throws {
            let container = try decoder.singleValueContainer()
            if let intValue = try? container.decode(Int.self) {
                self = .number(intValue)
                return
            }
            if let stringValue = try? container.decode(String.self) {
                self = .string(stringValue)
                return
            }
            if let boolValue = try? container.decode(Bool.self) {
                self = .bool(boolValue)
                return
            }
            if let jsonValue = try? container.decode([String:JSONValue].self) {
                self = .json(jsonValue)
                return
            }
            throw DecodingError.typeMismatch(JSONValue.self, DecodingError.Context.init(codingPath: [CodingKeys.value], debugDescription: "Couldn't find type to cast JSON value to", underlyingError: nil))
        }

    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        _id = try container.decode(String.self, forKey: ._id)
        key = try container.decode(String.self, forKey: .key)
        type = try container.decode(String.self, forKey: .type)
        
        switch type {
        case "JSON":
            value = try container.decode([String:JSONValue].self, forKey: .value)
        case "Boolean":
            value = try container.decode(Bool.self, forKey: .value)
        case "Number":
            value = try container.decode(Int.self, forKey: .value)
        case "String":
            value = try container.decode(String.self, forKey: .value)
        default:
            value = try container.decode(String.self, forKey: .value)
        }
    }
}
