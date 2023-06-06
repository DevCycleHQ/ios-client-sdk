//
//  CustomData.swift
//  DevCycle
//

import Foundation

public enum CustomDataValue: Codable {
    case string(_ value: String)
    case number(_ value: Double)
    case boolean(_ value: Bool)
    
    public init(from decoder: Decoder) throws {
        let singleValueContainer = try decoder.singleValueContainer()

        do {
            let value = try singleValueContainer.decode(Double.self)
            self = .number(value)
            return
        } catch {}
        
        do {
            let value = try singleValueContainer.decode(Bool.self)
            self = .boolean(value)
            return
        } catch {}
        
        do {
            let value = try singleValueContainer.decode(String.self)
            self = .string(value)
            return
        } catch {}
        
        throw DecodingError.dataCorruptedError(
            in: singleValueContainer,
            debugDescription: "Invalid CustomDataValue, must be a String / Number / Boolean type"
        )
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .string(let value):
            return try container.encode(value)
        case .number(let value):
            return try container.encode(value)
        case .boolean(let value):
            return try container.encode(value)
        }
    }
}

open class CustomData: Codable {
    public var data: [String: CustomDataValue]
    
    public static func customDataFromDic(_ data: [String: Any]) throws -> CustomData {
        let data = try JSONSerialization.data(withJSONObject: data)
        let decoder = JSONDecoder()
        return try decoder.decode(CustomData.self, from: data)
    }
    
    required public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: DynamicCodingKeys.self)
        var tmpData = [String: CustomDataValue]()
        
        for key in container.allKeys {
            let decodedObject = try container.decode(
                CustomDataValue.self,
                forKey: DynamicCodingKeys(stringValue: key.stringValue)!
            )
            tmpData[key.stringValue] = decodedObject
        }
        self.data = tmpData
    }
    
    private struct DynamicCodingKeys: CodingKey {
        // Use for string-keyed dictionary
        var stringValue: String
        init?(stringValue: String) {
            self.stringValue = stringValue
        }

        // Use for integer-keyed dictionary
        var intValue: Int?
        init?(intValue: Int) {
            // We are not using this, thus just return nil
            return nil
        }
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: DynamicCodingKeys.self)
        
        for (key, value) in data {
            try container.encode(
                value,
                forKey: DynamicCodingKeys(stringValue: key)!
            )
        }
    }
}
