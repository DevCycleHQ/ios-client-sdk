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
        let client = DVCClient.builder().user(user).environmentKey("my_env_key").build()
        XCTAssertNotNil(client)
    }
    
    func testSetupCallsGetConfig() {
        let client = DVCClient()
        let service = MockService() // will assert if getConfig was called
        client.setEnvironmentKey("")
        client.setUser(getTestUser())
        client.setup(service: service)
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
