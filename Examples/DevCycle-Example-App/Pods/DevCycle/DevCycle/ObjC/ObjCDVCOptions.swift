//
//  ObjCDVCOptions.swift
//  DevCycle
//
//  Copyright © 2022 Taplytics. All rights reserved.
//

import Foundation

@objc(LogLevel)
public class ObjCLogLevel: NSObject {
    @objc public static let debug = NSNumber(0)
    @objc public static let info = NSNumber(1)
    @objc public static let error = NSNumber(2)
}

@objc(DVCOptions)
public class ObjCOptions: NSObject {
    @objc public var flushEventsIntervalMs: NSNumber?
    @objc public var disableEventLogging: NSNumber?
    @objc public var logLevel: NSNumber?
    
    func buildDVCOptions() -> DVCOptions {
        var optionsBuilder = DVCOptions.builder()
        if let flushEventsIntervalMs = self.flushEventsIntervalMs,
           let interval = flushEventsIntervalMs as? Int {
            optionsBuilder = optionsBuilder.flushEventsIntervalMs(interval)
        }
        
        if let disableEventLogging = self.disableEventLogging,
           let disable = disableEventLogging as? Bool {
            optionsBuilder = optionsBuilder.disableEventLogging(disable)
        }
        if let logLevel = self.logLevel,
           let level = logLevel as? Int {
            var setLogLevel = LogLevel.error
            switch level {
            case 0:
                setLogLevel = .debug
            case 1:
                setLogLevel = .info
            case 2:
                setLogLevel = .error
            default:
                setLogLevel = .error
            }
            optionsBuilder = optionsBuilder.logLevel(setLogLevel)
        }
        return optionsBuilder.build()
    }
}

