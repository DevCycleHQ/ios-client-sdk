//
//  ObjCDVCOptions.swift
//  DevCycle
//
//  Copyright © 2022 Taplytics. All rights reserved.
//

import Foundation

@objc(DVCOptions)
public class ObjCDVCOptions: NSObject {
    var options: DVCOptions?
    
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
        let options = optionsBuilder.build()
        self.options = options
    }
    
    @objc(DVCOptionsBuilder)
    public class ObjCOptionsBuilder: NSObject {
        @objc public var flushEventsIntervalMs: NSNumber?
        @objc public var disableEventLogging: NSNumber?
    }
    
    @objc(build:block:) public static func build(_ block: ((ObjCOptionsBuilder) -> Void)) throws -> ObjCDVCOptions {
        let builder = ObjCOptionsBuilder()
        block(builder)
        let options = try ObjCDVCOptions(builder: builder)
        return options
    }
}
