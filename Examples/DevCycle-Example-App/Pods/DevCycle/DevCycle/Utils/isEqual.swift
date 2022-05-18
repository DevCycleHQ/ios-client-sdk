//
//  isEqual.swift
//  DevCycle
//
//  Copyright © 2022 Taplytics. All rights reserved.
//

import Foundation

internal func isEqual<T>(_ lhs: T, _ rhs: T) -> Bool {
    if let lhs = lhs as? [String: Any], let rhs = rhs as? [String: Any] {
        return NSDictionary(dictionary: lhs).isEqual(to: rhs)
    } else if let lhs = lhs as? Double, let rhs = rhs as? Double {
        return lhs == rhs
    } else if let lhs = lhs as? Float, let rhs = rhs as? Float {
        return lhs == rhs
    } else if let lhs = lhs as? Int, let rhs = rhs as? Int {
        return lhs == rhs
    } else if let lhs = lhs as? String, let rhs = rhs as? String {
        return lhs == rhs
    } else if let lhs = lhs as? Bool, let rhs = rhs as? Bool {
        return lhs == rhs
    } else {
        Log.error("Unrecognized type, lhs: \(type(of: lhs)), rhs: \(type(of: rhs))")
    }
    return false
}
