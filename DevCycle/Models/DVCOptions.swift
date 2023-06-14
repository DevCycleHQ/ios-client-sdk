//
//  DVCOptions.swift
//  DevCycle
//
//

import Foundation

public class DVCOptions {
    var flushEventsIntervalMs: Int?
    var disableEventLogging: Bool?
    var logLevel: LogLevel = .error
    var enableEdgeDB: Bool = false
    var disableConfigCache: Bool = false
    var configCacheTTL: Int = 604800000
    var disableRealtimeUpdates: Bool = false
    var disableAutomaticEventLogging: Bool = false
    var disableCustomEventLogging: Bool = false
    
    public class OptionsBuilder {
        var options: DVCOptions
        
        init () {
            self.options = DVCOptions()
        }
        
        public func flushEventsIntervalMs(_ interval: Int? = 10000) -> OptionsBuilder {
            self.options.flushEventsIntervalMs = interval
            return self
        }
        
        @available(*, deprecated, message: "Use disableAutomaticEventLogging or disableCustomEventLogging")
        public func disableEventLogging(_ disable: Bool) -> OptionsBuilder {
            self.options.disableEventLogging = disable
            return self
        }
        
        public func disableAutomaticEventLogging(_ disable: Bool) -> OptionsBuilder{
            self.options.disableAutomaticEventLogging = disable
            return self
        }
        
        public func disableCustomEventLogging(_ disable: Bool) -> OptionsBuilder{
            self.options.disableCustomEventLogging = disable
            return self
        }
        
        public func logLevel(_ level: LogLevel) -> OptionsBuilder {
            self.options.logLevel = level
            return self
        }
        
        public func enableEdgeDB(_ enable: Bool) -> OptionsBuilder {
            self.options.enableEdgeDB = enable
            return self
        }
        
        public func disableConfigCache(_ disable: Bool) -> OptionsBuilder {
            self.options.disableConfigCache = disable
            return self
        }
        
        public func configCacheTTL(_ ttl: Int = 604800000) -> OptionsBuilder {
            self.options.configCacheTTL = ttl
            return self
        }

        public func disableRealtimeUpdates(_ disable: Bool) -> OptionsBuilder {
            self.options.disableRealtimeUpdates = disable
            return self
        }
        
        public func build() -> DVCOptions {
            let result = self.options
            self.options = DVCOptions()
            return result
        }
    }
    
    public static func builder() -> OptionsBuilder {
        return OptionsBuilder()
    }
}
