//
//  DevCycleEventTests.swift
//  DevCycleTests
//
//

import XCTest

@testable import DevCycle

class DevCycleEventTests: XCTestCase {
    
    func testCreateEventWithMinimumRequiredFields() throws {
        // Test creating an event with just the required type field
        let event = try DevCycleEvent.builder()
            .type("test_event")
            .build()
        
        XCTAssertEqual(event.type, "test_event")
        XCTAssertNil(event.target)
        XCTAssertNil(event.clientDate)
        XCTAssertNil(event.value)
        XCTAssertNil(event.metaData)
    }
    
    func testCreateEventWithAllFields() throws {
        // Test creating an event with all fields populated
        let date = Date()
        let metaData: [String: Any] = ["key1": "value1", "key2": 123, "key3": true]
        
        let event = try DevCycleEvent.builder()
            .type("test_event")
            .target("test_target")
            .clientDate(date)
            .value(42.5)
            .metaData(metaData)
            .build()
        
        XCTAssertEqual(event.type, "test_event")
        XCTAssertEqual(event.target, "test_target")
        XCTAssertEqual(event.clientDate, date)
        XCTAssertEqual(event.value, 42.5)
        XCTAssertEqual(event.metaData?["key1"] as? String, "value1")
        XCTAssertEqual(event.metaData?["key2"] as? Int, 123)
        XCTAssertEqual(event.metaData?["key3"] as? Bool, true)
    }
    
    func testCreateEventWithMissingType() {
        // Test that creating an event without a type throws an error
        XCTAssertThrowsError(try DevCycleEvent.builder().build()) { error in
            XCTAssertEqual(error as? EventError, EventError.MissingEventType)
        }
    }
    
    func testCreateEventWithBuilderReuse() throws {
        // Test that the builder can be reused after building an event
        let builder = DevCycleEvent.builder()
        
        let event1 = try builder
            .type("event1")
            .build()
        
        let event2 = try builder
            .type("event2")
            .build()
        
        XCTAssertEqual(event1.type, "event1")
        XCTAssertEqual(event2.type, "event2")
    }
    
    func testCreateEventWithNilValues() throws {
        // Test creating an event with explicit nil values
        let event = try DevCycleEvent.builder()
            .type("test_event")
            .target(nil)
            .clientDate(nil)
            .value(nil)
            .metaData(nil)
            .build()
        
        XCTAssertEqual(event.type, "test_event")
        XCTAssertNil(event.target)
        XCTAssertNil(event.clientDate)
        XCTAssertNil(event.value)
        XCTAssertNil(event.metaData)
    }
}
