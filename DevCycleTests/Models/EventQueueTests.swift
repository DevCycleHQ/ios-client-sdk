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
        let user = try! DevCycleUser.builder().userId("user1").build()
        eventQueue.queue(event)
        eventQueue.flush(service: MockService(), user: user, callback: nil)
        eventQueue.flush(service: MockService(), user: user) { error in
            XCTAssertNotNil(error)
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 3.0)
    }
    
    func testFlushRequeuesIfErrorRetryable() {
        let eventQueue = EventQueue()
        let expectation = XCTestExpectation(description: "Flush Requeues Retryable Event")
        let event = try! DVCEvent.builder().type("event1").build()
        let user = try! DevCycleUser.builder().userId("user1").build()
        eventQueue.queue(event)
        eventQueue.flush(service: MockWithErrorCodeService(errorCode: 500), user: user, callback: nil)
        let result = XCTWaiter.wait(for: [expectation], timeout: 2.0)
        if result == XCTWaiter.Result.timedOut {
            XCTAssertEqual(eventQueue.events.count, 1)
        }
    }
    
    func testFlushDoesntRequeueIfErrorNotRetryable() {
        let eventQueue = EventQueue()
        let expectation = XCTestExpectation(description: "Subsequent flushes are cancelled")
        let event = try! DVCEvent.builder().type("event1").build()
        let user = try! DevCycleUser.builder().userId("user1").build()
        eventQueue.queue(event)
        eventQueue.flush(service: MockWithErrorCodeService(errorCode: 403), user: user, callback: nil)
        let result = XCTWaiter.wait(for: [expectation], timeout: 2.0)
        if result == XCTWaiter.Result.timedOut {
            XCTAssertEqual(eventQueue.events.count, 0)
        }
    }
}

private class MockService: DevCycleServiceProtocol {
    func getConfig(user: DevCycleUser, enableEdgeDB: Bool, extraParams: RequestParams?, completion: @escaping ConfigCompletionHandler) {}
    
    func publishEvents(events: [DVCEvent], user: DevCycleUser, completion: @escaping PublishEventsCompletionHandler) {
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            completion((nil, nil, nil))
        }
    }
    
    func saveEntity(user: DevCycleUser, completion: @escaping SaveEntityCompletionHandler) {}
    
    func makeRequest(request: URLRequest, completion: @escaping DevCycle.CompletionHandler) {}
}

class MockWithErrorCodeService: DevCycleServiceProtocol {
    var errorCode: Int
    init(errorCode: Int) {
        self.errorCode = errorCode
    }
    
    func getConfig(user: DevCycleUser, enableEdgeDB: Bool, extraParams: RequestParams?, completion: @escaping ConfigCompletionHandler) {}
    func publishEvents(events: [DVCEvent], user: DevCycleUser, completion: @escaping PublishEventsCompletionHandler) {
        let error = NSError(domain: "api.devcycle.com", code: self.errorCode)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            completion((nil, nil, error))
        }
    }
    func saveEntity(user: DevCycleUser, completion: @escaping SaveEntityCompletionHandler) {}
    func makeRequest(request: URLRequest, completion: @escaping DevCycle.CompletionHandler) {}
}
