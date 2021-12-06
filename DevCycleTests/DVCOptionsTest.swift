//
//  DVCUser.swift
//  DevCycleTests
//
//

import XCTest
@testable import DevCycle

class DVCOptionsTest: XCTestCase {
    func testOptionsAreNil() {
        let options = DVCOptions()
        XCTAssertNil(options.disableEventLogging)
        XCTAssertNil(options.flushEventsIntervalMs)
    }
    
    func testBuilderReturnsOptions() {
        let options = DVCOptions.builder()
                .disableEventLogging(false)
                .flushEventsIntervalMs(1000)
                .build()
        XCTAssertNotNil(options)
        XCTAssert(options.flushEventsIntervalMs == 1000)
        XCTAssertFalse(options.disableEventLogging!)
    }
    
    func testBuilderReturnsOptionsAndSomeAreNil() {
        let options = DVCOptions.builder()
                .disableEventLogging(false)
                .build()
        XCTAssertNotNil(options)
        XCTAssertNil(options.flushEventsIntervalMs)
        XCTAssertFalse(options.disableEventLogging!)
    }
}
