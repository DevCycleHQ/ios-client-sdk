//
//  ObjCDevCycleOptions.swift
//  DevCycle
//

import Foundation

@objc(LogLevel)
public class ObjCLogLevel: NSObject {
    @objc public static let debug = NSNumber(0)
    @objc public static let info = NSNumber(1)
    @objc public static let error = NSNumber(2)
}

@objc(DevCycleOptions)
public class ObjCDevCycleOptions: NSObject {
    @available(*, deprecated, message: "Use eventFlushIntervalMS")
    @objc public var flushEventsIntervalMs: NSNumber?
    @objc public var eventFlushIntervalMS: NSNumber?
    @objc public var disableEventLogging: NSNumber?
    @objc public var logLevel: NSNumber?
    @objc public var enableEdgeDB: NSNumber?
    @objc public var disableConfigCache: NSNumber?
    @objc public var configCacheTTL: NSNumber?
    @objc public var disableRealtimeUpdates: NSNumber?
    @objc public var disableAutomaticEventLogging: NSNumber?
    @objc public var disableCustomEventLogging: NSNumber?
    @objc public var apiProxyURL: NSString?
    
    func buildDevCycleOptions() -> DevCycleOptions {
        var optionsBuilder = DevCycleOptions.builder()
        if let eventFlushIntervalMS = self.eventFlushIntervalMS,
           let interval = eventFlushIntervalMS as? Int {
            optionsBuilder = optionsBuilder.eventFlushIntervalMS(interval)
        } else if let flushEventsIntervalMs = self.flushEventsIntervalMs,
                  let interval = flushEventsIntervalMs as? Int {
            optionsBuilder = optionsBuilder.eventFlushIntervalMS(interval)
        }
        
        if let disableEventLogging = self.disableEventLogging,
           let disable = disableEventLogging as? Bool {
            optionsBuilder = optionsBuilder.disableEventLogging(disable)
        }
        
        if let enableEdgeDB = self.enableEdgeDB,
           let enable = enableEdgeDB as? Bool {
            optionsBuilder = optionsBuilder.enableEdgeDB(enable)
        }
        
        if let disableConfigCache = self.disableConfigCache,
           let disable = disableConfigCache as? Bool {
            optionsBuilder = optionsBuilder.disableConfigCache(disable)
        }
        
        if let configCacheTTL = self.configCacheTTL,
           let interval = configCacheTTL as? Int {
            optionsBuilder = optionsBuilder.configCacheTTL(interval)
        }
        
        if let disableRealtimeUpdates = self.disableRealtimeUpdates,
           let disable = disableRealtimeUpdates as? Bool {
            optionsBuilder = optionsBuilder.disableRealtimeUpdates(disable)
        }
        
        if let disableAutomaticEventLogging = self.disableAutomaticEventLogging,
           let disable = disableAutomaticEventLogging as? Bool {
            optionsBuilder = optionsBuilder.disableAutomaticEventLogging(disable)
        }
        
        if let disableCustomEventLogging = self.disableCustomEventLogging,
           let disable = disableCustomEventLogging as? Bool {
            optionsBuilder = optionsBuilder.disableCustomEventLogging(disable)
        }
        
        if let apiProxyURL = self.apiProxyURL,
           let proxyURL = apiProxyURL as? String {
            optionsBuilder = optionsBuilder.apiProxyURL(proxyURL)
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

@available(*, deprecated, message: "Use DevCycleOptions")
@objc(DVCOptions)
public class ObjCDVCOptions: ObjCDevCycleOptions {}
