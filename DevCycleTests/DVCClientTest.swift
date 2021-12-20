//
//  DVCClient.swift
//  DevCycleTests
//
//

import XCTest
@testable import DevCycle

class DVCClientTest: XCTestCase {
    func testBuilderReturnsNilIfNoEnvKey() {
        let user = try! DVCUser.builder()
                    .userId("my_user")
                    .build()
        XCTAssertNil(try? DVCClient.builder().user(user).build(onInitialized: nil))
    }
    
    func testBuilderReturnsNilIfNoUser() {
        XCTAssertNil(try? DVCClient.builder().environmentKey("my_env_key").build(onInitialized: nil))
    }
    
    func testBuilderReturnsClient() {
        let user = try! DVCUser.builder()
                    .userId("my_user")
                    .build()
        let client = try! DVCClient.builder().user(user).environmentKey("my_env_key").build(onInitialized: nil)
        XCTAssertNotNil(client)
        XCTAssertNotNil(client.user)
        XCTAssertNotNil(client.environmentKey)
        XCTAssertNil(client.options)
    }
    
    func testSetupCallsGetConfig() {
        let client = DVCClient()
        let service = MockService() // will assert if getConfig was called
        client.setEnvironmentKey("")
        client.setUser(getTestUser())
        client.setup(service: service)
    }
    
    func testBuilderReturnsClientWithOptions() {
        let user = getTestUser()
        let options = DVCOptions.builder().disableEventLogging(false).flushEventsIntervalMs(100).build()
        let client = try! DVCClient.builder().user(user).environmentKey("my_env_key").options(options).build(onInitialized: nil)
        XCTAssertNotNil(client)
        XCTAssertNotNil(client.options)
        XCTAssertNotNil(client.user)
        XCTAssertNotNil(client.environmentKey)
    }
    
    func testTrackWithValidDVCEventNoOptionals() {
        let client = DVCClient()
        let event: DVCEvent = DVCEvent(type: "test")
        
        client.track(event)
        XCTAssertTrue(client.eventQueue.count == 1)
    }
    
    func testTrackWithValidDVCEventWithAllParamsDefined() {
        let client = DVCClient()
        let data: [String:Any] = ["test1": "key", "test2": 2, "test3": false]
        let event: DVCEvent = DVCEvent(type: "test", target: "test", clientDate: Date(), value: 1, metaData: data)
        
        client.track(event)
        XCTAssertTrue(client.eventQueue.count == 1)
    }
    
    func testFlushEventsWithOneEventInQueue() {
        let user = getTestUser()
        let options = DVCOptions.builder().disableEventLogging(false).flushEventsIntervalMs(10000).build()
        let client = try! DVCClient.builder().user(user).environmentKey("my_env_key").options(options).build()
        let service = MockService() // will assert if publishEvents was called
        client.setEnvironmentKey("")
        client.setUser(getTestUser())
        client.setup(service: service)
        let event: DVCEvent = DVCEvent(type: "test")
        
        client.track(event)
        XCTAssertTrue(client.eventQueue.count == 1)
        client.flushEvents()
        XCTAssertTrue(service.publishCallCount == 1)
    }
    
    func testPeriodicFlushEventsWithSomeEventsInQueue() {
        let user = getTestUser()
        let options = DVCOptions.builder().disableEventLogging(false).flushEventsIntervalMs(500).build()
        let client = try! DVCClient.builder().user(user).environmentKey("my_env_key").options(options).build()
        let service = MockService() // will assert if publishEvents was called
        client.setEnvironmentKey("")
        client.setUser(getTestUser())
        client.setup(service: service)
        let event: DVCEvent = DVCEvent(type: "test")
        
        client.track(event)
        client.track(event)
        client.track(event)
        XCTAssertTrue(client.eventQueue.count == 3)
        let expec = expectation(description: "Timer expectation") // create an expectation
        service.publishEvents(events: client.eventQueue, user: user, completion: { data, response, error in
            expec.fulfill()
        })
        // wait for fulfilling every expectation (in this case only one), timeout must be greater than the timer interval
        wait(for: [expec], timeout: 1.0)
        XCTAssertTrue(service.publishCallCount == 1)
    }
}

extension DVCClientTest {
    class MockService: DevCycleServiceProtocol {
        public var publishCallCount: Int = 0
        
        func getConfig(completion: @escaping ConfigCompletionHandler) {
            XCTAssert(true)
        }

        func publishEvents(events: [DVCEvent], user: DVCUser, completion: @escaping PublishEventsCompletionHandler) {
            self.publishCallCount += 1
            XCTAssert(true)
            completion((data: nil, urlResponse: nil, error: nil))
        }
    }
    
    func getTestUser() -> DVCUser {
        return try! DVCUser.builder()
            .userId("my_user")
            .build()
    }
}
