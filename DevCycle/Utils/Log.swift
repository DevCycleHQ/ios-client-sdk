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
    case warn
    case error
}

public class Log {
    public static var level = LogLevel.error
    static let tag = "DevCycle"

    static fileprivate func log(_ level: LogLevel, _ message: String, _ tags: [String] = []) {
        if level.rawValue >= Log.level.rawValue {
            let formatTags = tags.map { "[\($0)]" }
            let prefixTags = "[\(tag)]" + formatTags.joined(separator: "")
            print("\(prefixTags) \(message)")
        }
    }

    public static func debug(_ message: String, tags: [String] = []) {
        Log.log(.debug, message, ["debug"] + tags)
    }

    public static func info(_ message: String, tags: [String] = []) {
        Log.log(.info, message, ["info"] + tags)
    }

    public static func warn(_ message: String, tags: [String] = []) {
        Log.log(.warn, message, ["warn"] + tags)
    }

    public static func error(_ message: String, tags: [String] = []) {
        Log.log(.error, message, ["error"] + tags)
    }
}
