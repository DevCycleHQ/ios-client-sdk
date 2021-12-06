//
//  DVCOptions.swift
//  DevCycle
//
//

import Foundation

public class DVCOptions {
    var flushEventsIntervalMs: Int?
    var disableEventLogging: Bool?
    
    public class OptionsBuilder {
        var options: DVCOptions
        
        init () {
            self.options = DVCOptions()
        }
        
        public func flushEventsIntervalMs(_ interval: Int) -> OptionsBuilder {
            self.options.flushEventsIntervalMs = interval
            return self
        }
        
        public func disableEventLogging(_ disable: Bool) -> OptionsBuilder {
            self.options.disableEventLogging = disable
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
