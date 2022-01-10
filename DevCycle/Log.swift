//
//  Log.swift
//  DevCycle
//
//  Copyright © 2022 Taplytics. All rights reserved.
//

import Foundation

public enum LogLevel: Int {
    case debug
    case info
    case error
}

class Log {
    static var level = LogLevel.error
    static let tag = "DevCycle"
    
    static fileprivate func log(_ level: LogLevel, _ message: String, _ tags: [String] = []) {
        if level.rawValue >= Log.level.rawValue {
            let formatTags = tags.map { "[\($0)]" }
            let prefixTags = "[\(tag)]" + formatTags.joined(separator: "")
            print("\(prefixTags) \(message)")
        }
    }
    
    static func debug(_ message: String, tags: [String] = []) {
        Log.log(.debug, message, tags)
    }
    
    static func info(_ message: String, tags: [String] = []) {
        Log.log(.info, message, tags)
    }
    
    static func error(_ message: String, tags: [String] = []) {
        Log.log(.error, message, tags)
    }
}
