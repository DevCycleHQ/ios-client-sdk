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
        let data: [String: Any] = ["test1": "key", "test2": 2, "test3": false]
        let event: DVCEvent = DVCEvent(type: "test", target: "test", date: Date(), value: 1, metaData: data)
        
        client.track(event)
        XCTAssertTrue(client.eventQueue.count == 1)
    }
}

extension DVCClientTest {
    class MockService: DevCycleServiceProtocol {
        func getConfig(completion: @escaping ConfigCompletionHandler) {
            XCTAssert(true)
        }

        func publishEvents(events: [DVCEvent], user: DVCUser, completion: @escaping ConfigCompletionHandler) {
            XCTAssert(true)
        }
    }
    
    func getTestUser() -> DVCUser {
        return try! DVCUser.builder()
            .userId("my_user")
            .build()
    }
}
