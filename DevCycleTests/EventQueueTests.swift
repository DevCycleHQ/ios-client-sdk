//
//  EventQueueTests.swift
//  DevCycleTests
//
//  Copyright © 2022 Taplytics. All rights reserved.
//

import XCTest
@testable import DevCycle

class EventQueueTests: XCTestCase {
    
    func testSerialOrderOfEvents() {
        let eventQueue = EventQueue()
        let expectation = XCTestExpectation(description: "Events are serially queued")
        let event1 = try! DVCEvent.builder().type("event1").build()
        let event2 = try! DVCEvent.builder().type("event2").build()
        eventQueue.queue(event1)
        eventQueue.queue(event2)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            XCTAssert(eventQueue.events.first?.type == "event1")
            XCTAssert(eventQueue.events.last?.type == "event2")
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 3.0)
    }

    func testFlushCancelsIfFlushInProgress() {
        let eventQueue = EventQueue()
        let expectation = XCTestExpectation(description: "Subsequent flushes are cancelled")
        let event = try! DVCEvent.builder().type("event1").build()
        let user = try! DVCUser.builder().userId("user1").build()
        eventQueue.queue(event)
        eventQueue.flush(service: MockService(), user: user, callback: nil)
        eventQueue.flush(service: MockService(), user: user) { error in
            XCTAssertNotNil(error)
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 3.0)
    }
}

class MockService: DevCycleServiceProtocol {
    func getConfig(user: DVCUser, completion: @escaping ConfigCompletionHandler) {}
    
    func publishEvents(events: [DVCEvent], user: DVCUser, completion: @escaping PublishEventsCompletionHandler) {
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            completion((nil, nil, nil))
        }
    }
    
}
