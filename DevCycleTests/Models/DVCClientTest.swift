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
        let expectation = XCTestExpectation(description: "EventQueue has one event")
        let client = DVCClient()
        let event: DVCEvent = try! DVCEvent.builder().type("test").build()
        
        client.track(event)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            XCTAssertTrue(client.eventQueue.events.count == 1)
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 1.0)
    }
    
    func testTrackWithValidDVCEventWithAllParamsDefined() {
        let expectation = XCTestExpectation(description: "EventQueue has one fully defined event")
        let client = DVCClient()
        let metaData: [String:Any] = ["test1": "key", "test2": 2, "test3": false]
        let event: DVCEvent = try! DVCEvent.builder().type("test").target("test").clientDate(Date()).value(1).metaData(metaData).build()
        
        client.track(event)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            XCTAssertTrue(client.eventQueue.events.count == 1)
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 1.0)
    }
    
    func testFlushEventsWithOneEventInQueue() {
        let expectation = XCTestExpectation(description: "EventQueue publishes an event")
        let user = getTestUser()
        let options = DVCOptions.builder().disableEventLogging(false).flushEventsIntervalMs(10000).build()
        let client = try! DVCClient.builder().user(user).environmentKey("my_env_key").options(options).build(onInitialized: nil)
        let service = MockService() // will assert if publishEvents was called
        client.setup(service: service)
        let event: DVCEvent = try! DVCEvent.builder().type("test").clientDate(Date()).build()
        
        client.track(event)
        client.flushEvents()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            XCTAssertTrue(service.publishCallCount == 1)
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 1.0)
    }
    
    func testVariableReturnsDefaultForUnsupportedVariableKeys() {
        let user = getTestUser()
        let client = try! DVCClient.builder().user(user).environmentKey("my_env_key").build(onInitialized: nil)
        let variable = client.variable(key: "UNSUPPORTED\\key%$", defaultValue: true)
        XCTAssertEqual(client.configCompletionHandlers.count, 0)
        XCTAssertTrue(variable.value)
    }
    
    func testVariableFunctionWorksIfVariableKeyHasSupportedCharacters() {
        let user = getTestUser()
        let client = try! DVCClient.builder().user(user).environmentKey("my_env_key").build(onInitialized: nil)
        let variable = client.variable(key: "supported-keys_here", defaultValue: true)
        XCTAssertEqual(client.configCompletionHandlers.count, 1)
    }

}

extension DVCClientTest {
    private class MockService: DevCycleServiceProtocol {
        public var publishCallCount: Int = 0
        
        func getConfig(user: DVCUser, enableEdgeDB: Bool, completion: @escaping ConfigCompletionHandler) {
            XCTAssert(true)
        }

        func publishEvents(events: [DVCEvent], user: DVCUser, completion: @escaping PublishEventsCompletionHandler) {
            self.publishCallCount += 1
            XCTAssert(true)
            completion((data: nil, urlResponse: nil, error: nil))
        }
        
        func saveEntity(user: DVCUser, completion: @escaping SaveEntityCompletionHandler) {
            XCTAssert(true)
        }
        
        func makeRequest(request: URLRequest, completion: @escaping DevCycle.CompletionHandler) {
            XCTAssert(true)
        }
    }
    
    func getTestUser() -> DVCUser {
        return try! DVCUser.builder()
            .userId("my_user")
            .build()
    }
}