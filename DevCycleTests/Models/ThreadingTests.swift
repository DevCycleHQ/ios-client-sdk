//
//  ThreadingTests.swift
//  DevCycleTests
//
//  Copyright © 2023 Taplytics. All rights reserved.
//

import XCTest
@testable import DevCycle

final class ThreadingTests: XCTestCase {
    private var service: MockService!
    private var user: DVCUser!
    private var builder: DevCycleClient.ClientBuilder!
    private var userConfig: UserConfig!
    
    override func setUpWithError() throws {
        self.service = MockService()
        self.user = try! DVCUser.builder()
                    .userId("my_user")
                    .build()
        self.builder = DevCycleClient.builder().service(service)

        let data = getConfigData(name: "test_config")
        let dictionary = try! JSONSerialization.jsonObject(with: data, options: .fragmentsAllowed) as! [String:Any]
        self.userConfig = try! UserConfig(from: dictionary)
    }

    func testVariableWorksInASyncBlockOnMainThread() throws {
        let client = try! self.builder.user(self.user).sdkKey("my_sdk_key").build(onInitialized: nil)
        let expectation = expectation(description: "Expect calling variable in a sync block on the main thread doesn't crash")
        DispatchQueue.global(qos: .userInitiated).async {
            DispatchQueue.main.sync {
                client.variable(key: "test-key", defaultValue: false)
                expectation.fulfill()
            }
        }
        wait(for: [expectation], timeout: 1.0)
    }

}

private class MockService: DevCycleServiceProtocol {
    func getConfig(user: DVCUser, enableEdgeDB: Bool, extraParams: RequestParams?, completion: @escaping ConfigCompletionHandler) {}
    
    func publishEvents(events: [DVCEvent], user: DVCUser, completion: @escaping PublishEventsCompletionHandler) {}
    
    func saveEntity(user: DVCUser, completion: @escaping SaveEntityCompletionHandler) {}
    
    func makeRequest(request: URLRequest, completion: @escaping DevCycle.CompletionHandler) {}
}
