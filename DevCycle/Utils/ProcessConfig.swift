//
//  ProcessConfig.swift
//  DevCycle
//
//  Copyright © 2022 Taplytics. All rights reserved.
//

internal func processConfig(_ responseData: Data?) -> UserConfig? {
    guard let data = responseData else {
        Log.error("No response data from request", tags: ["service", "request"])
        return nil
    }
    do {
        let dictionary = try JSONSerialization.jsonObject(with: data, options: .fragmentsAllowed) as! [String:Any]
        return try UserConfig(from: dictionary)
    } catch {
        Log.error("Failed to decode config: \(error)", tags: ["service", "request"])
    }
    return nil
}
