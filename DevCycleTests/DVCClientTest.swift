//
//  DVCClient.swift
//  DevCycleTests
//
//

import XCTest
@testable import DevCycle

class DVCClientTest: XCTestCase {
    func testBuilderReturnsNilIfNoEnvKey() {
        let user = DVCUser.builder()
                    .userId("my_user")
                    .build()!
        XCTAssertNil(DVCClient.builder().user(user).build())
    }
    
    func testBuilderReturnsNilIfNoUser() {
        XCTAssertNil(DVCClient.builder().environmentKey("my_env_key").build())
    }
    
    func testBuilderReturnsClient() {
        let user = DVCUser.builder()
                    .userId("my_user")
                    .build()!
        let client = DVCClient.builder().user(user).environmentKey("my_env_key").build()!
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
        let user = DVCUser.builder()
                    .userId("my_user")
                    .build()!
        let options = DVCOptions.builder().disableEventLogging(false).flushEventsIntervalMs(100).build()
        let client = DVCClient.builder().user(user).environmentKey("my_env_key").options(options).build()!
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
    }
    
    func getTestUser() -> DVCUser {
        return DVCUser.builder()
            .userId("my_user")
            .build()!
    }
}
