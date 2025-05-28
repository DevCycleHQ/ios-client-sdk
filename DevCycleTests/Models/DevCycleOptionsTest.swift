//
//  DevCycleOptionsTest.swift
//  DevCycleTests
//

import XCTest
@testable import DevCycle

class DevCycleOptionsTest: XCTestCase {
    func testOptionsAreNil() {
        let options = DevCycleOptions()
        XCTAssertNil(options.disableEventLogging)
        XCTAssertNil(options.eventFlushIntervalMS)
    }
    
    func testBuilderReturnsOptions() {
        let options = DevCycleOptions.builder()
                .disableEventLogging(false)
                .eventFlushIntervalMS(1000)
                .enableEdgeDB(true)
                .configCacheTTL(172800000)
                .disableConfigCache(true)
                .disableRealtimeUpdates(true)
                .disableCustomEventLogging(true)
                .disableAutomaticEventLogging(true)
                .apiProxyURL("localhost:4000")
                .eventsApiProxyURL("localhost:4001")
                .build()
        XCTAssertNotNil(options)
        XCTAssert(options.eventFlushIntervalMS == 1000)
        XCTAssertFalse(options.disableEventLogging!)
        XCTAssert(options.enableEdgeDB)
        XCTAssert(options.configCacheTTL == 172800000)
        XCTAssert(options.disableConfigCache)
        XCTAssert(options.disableRealtimeUpdates)
        XCTAssert(options.disableCustomEventLogging)
        XCTAssert(options.disableAutomaticEventLogging)
        XCTAssert(options.apiProxyURL == "localhost:4000")
        XCTAssert(options.eventsApiProxyURL == "localhost:4001")
    }
    
    func testBuilderReturnsOptionsAndSomeAreNil() {
        let options = DevCycleOptions.builder()
                .disableEventLogging(false)
                .build()
        XCTAssertNotNil(options)
        XCTAssertNil(options.eventFlushIntervalMS)
        XCTAssertFalse(options.disableEventLogging!)
        XCTAssertFalse(options.enableEdgeDB)
        XCTAssertFalse(options.disableRealtimeUpdates)
    }
    
    func testDeprecatedDVCOptions() {
        let options = DVCOptions.builder()
                .disableEventLogging(false)
                .flushEventsIntervalMs(2000)
                .build()
        XCTAssertNotNil(options)
        XCTAssert(options.eventFlushIntervalMS == 2000)
        XCTAssertFalse(options.disableEventLogging!)
        XCTAssertFalse(options.enableEdgeDB)
        XCTAssertFalse(options.disableRealtimeUpdates)
    }
    
    func testDefaultConfigCacheTTL() {
        let options = DevCycleOptions()
        // Default TTL should be 30 days (2,592,000,000 milliseconds)
        XCTAssertEqual(options.configCacheTTL, 2_592_000_000, "Default config cache TTL should be 30 days")
    }
    
    func testConfigCacheTTLCustomization() {
        let customTTL = 86400000 // 1 day in milliseconds
        let options = DevCycleOptions.builder()
                .configCacheTTL(customTTL)
                .build()
        XCTAssertEqual(options.configCacheTTL, customTTL, "Custom config cache TTL should be respected")
    }
}
