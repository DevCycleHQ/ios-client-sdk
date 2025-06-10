//
//  ProcessConfig.swift
//  DevCycle
//
//  Copyright © 2022 Taplytics. All rights reserved.
//

import Foundation

internal func processConfig(_ responseData: Data?) -> UserConfig? {
    guard let data = responseData else {
        Log.error("No response data from request", tags: ["service", "request"])
        return nil
    }
    do {
        guard let dictionary = try JSONSerialization.jsonObject(with: data, options: .fragmentsAllowed) as? [String:Any] else {
            throw UserConfigError.InvalidJson("Error with serializing config data to JSON")
        }
        return try UserConfig(from: dictionary)
    } catch {
        Log.error("Failed to decode config: \(error)", tags: ["service", "request"])
    }
    return nil
}
