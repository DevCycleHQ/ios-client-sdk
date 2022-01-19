//
//  ObjCDVCOptions.swift
//  DevCycle
//
//  Copyright © 2022 Taplytics. All rights reserved.
//

import Foundation

@objc(DVCOptionsBuilder)
public class ObjCOptionsBuilder: NSObject {
    @objc public var flushEventsIntervalMs: NSNumber?
    @objc public var disableEventLogging: NSNumber?
    @objc public var logLevel: NSNumber?
}

@objc(LogLevel)
public class ObjCLogLevel: NSObject {
    @objc public static let debug = NSNumber(0)
    @objc public static let info = NSNumber(1)
    @objc public static let error = NSNumber(2)
}

@objc(DVCOptions)
public class ObjCDVCOptions: NSObject {
    var options: DVCOptions?
    
    @objc(build:block:)
    public static func build(_ block: ((ObjCOptionsBuilder) -> Void)) throws -> ObjCDVCOptions {
        let builder = ObjCOptionsBuilder()
        block(builder)
        let options = ObjCDVCOptions(builder: builder)
        return options
    }
    
    init(builder: ObjCOptionsBuilder) {
        var optionsBuilder = DVCOptions.builder()
        if let flushEventsIntervalMs = builder.flushEventsIntervalMs,
           let interval = flushEventsIntervalMs as? Int {
            optionsBuilder = optionsBuilder.flushEventsIntervalMs(interval)
        }
        
        if let disableEventLogging = builder.disableEventLogging,
           let disable = disableEventLogging as? Bool {
            optionsBuilder = optionsBuilder.disableEventLogging(disable)
        }
        if let logLevel = builder.logLevel,
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
        let options = optionsBuilder.build()
        self.options = options
    }
}
