//
//  DVCClient.swift
//  DevCycleTests
//
//

import XCTest
import UIKit

@testable import DevCycle


class DVCClientTest: XCTestCase {
    private var service: MockService!
    private var user: DVCUser!
    private var builder: DVCClient.ClientBuilder!
    
    override func setUp() {
        self.service = MockService()
        self.user = try! DVCUser.builder()
                    .userId("my_user")
                    .build()
        self.builder = DVCClient.builder().service(service)
    }
    
    func testBuilderReturnsNilIfNoEnvKey() {
        XCTAssertNil(try? self.builder.user(self.user).build(onInitialized: nil))
    }
    
    func testBuilderReturnsNilIfNoUser() {
        XCTAssertNil(try? self.builder.environmentKey("my_env_key").build(onInitialized: nil))
    }
    
    func testBuilderReturnsClient() {
        let client = try! self.builder.user(self.user).environmentKey("my_env_key").build(onInitialized: nil)
        XCTAssertNotNil(client)
        XCTAssertNotNil(client.user)
        XCTAssertNotNil(client.environmentKey)
        XCTAssertNil(client.options)
    }
    
    func testSetupCallsGetConfig() {
        let client = DVCClient()
        let service = MockService() // will assert if getConfig was called
        client.setEnvironmentKey("")
        client.setUser(self.user)
        client.setup(service: service)
    }
    
    func testBuilderReturnsClientWithOptions() {
        let options = DVCOptions.builder().disableEventLogging(false).flushEventsIntervalMs(100).build()
        let client = try! self.builder.user(self.user).environmentKey("my_env_key").options(options).build(onInitialized: nil)
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
        let options = DVCOptions.builder().disableEventLogging(false).flushEventsIntervalMs(10000).build()
        let service = MockService() // will assert if publishEvents was called

        let client = try! self.builder.user(self.user).environmentKey("my_env_key").options(options).service(service).build(onInitialized: nil)
        
        let event: DVCEvent = try! DVCEvent.builder().type("test").clientDate(Date()).build()
        
        client.track(event)
        client.flushEvents()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            XCTAssertTrue(service.publishCallCount == 1)
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 1.0)
    }
    
    func testCloseFlushesRemainingEvents() {
        let expectation = XCTestExpectation(description: "Close flushes remaining events")
        let options = DVCOptions.builder().disableEventLogging(false).flushEventsIntervalMs(10000).build()
        let client = try! self.builder.user(self.user).environmentKey("my_env_key").options(options).build(onInitialized: nil)
        let service = MockService() // will assert if publishEvents was called
        client.setup(service: service)
        let event: DVCEvent = try! DVCEvent.builder().type("test").clientDate(Date()).build()
        
        client.track(event)
        client.close(callback: {
            DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                XCTAssertEqual(service.publishCallCount, 1)

                XCTAssertEqual(service.eventPublishCount, 1)
                
                client.flushEvents(callback: { error in
                    // test that later tracked events are ignored
                    XCTAssertEqual(service.publishCallCount, 1)
                    XCTAssertEqual(service.eventPublishCount, 1)
                    expectation.fulfill()
                })
            }
        })
        // this one should be prevented
        client.track(event)
        // this variable evaluated event should be prevented as well
        client.variable(key: "test-key", defaultValue: false)
        
        wait(for: [expectation], timeout: 6.0)
    }
    
    func testVariableReturnsDefaultForUnsupportedVariableKeys() {
        let client = try! self.builder.user(self.user).environmentKey("my_env_key").build(onInitialized: nil)
        let variable = client.variable(key: "UNSUPPORTED\\key%$", defaultValue: true)
        XCTAssertTrue(variable.value)
    }
    
    func testVariableFunctionWorksIfVariableKeyHasSupportedCharacters() {
        let client = try! self.builder.user(self.user).environmentKey("my_env_key").build(onInitialized: nil)
        let variable = client.variable(key: "supported-keys_here", defaultValue: true)
        XCTAssertTrue(variable.value)
    }

    func testRefetchConfigUsesTheCorrectUser() {
        let service = MockService()
        let user1 = try! DVCUser.builder().userId("user1").build()
        let client = try! DVCClient.builder().user(user1).environmentKey("my_env_key").build(onInitialized: nil)
        client.setup(service: service)
        client.initialized = true

        XCTAssertEqual(client.lastIdentifiedUser?.userId, user1.userId)
        client.refetchConfig(sse: true, lastModified: 123)
        XCTAssertEqual(service.numberOfConfigCalls, 2)

        let user2 = try! DVCUser.builder().userId("user2").build()
        try! client.identifyUser(user: user2)
        XCTAssertEqual(client.lastIdentifiedUser?.userId, user2.userId)
        client.refetchConfig(sse: true, lastModified: 456)
        XCTAssertEqual(service.numberOfConfigCalls, 4)

        let user3 = try! DVCUser.builder().userId("user3").build()
        try! client.identifyUser(user: user3)
        XCTAssertEqual(client.lastIdentifiedUser?.userId, user3.userId)
        client.refetchConfig(sse: true, lastModified: 789)
        XCTAssertEqual(service.numberOfConfigCalls, 6)
    }
    
    func testSseCloseGetsCalledWhenBackgrounded() {
        let client = try! self.builder.user(self.user).environmentKey("my_env_key").build(onInitialized: nil)
        client.initialized = true
        
        let mockSSEConnection = MockSSEConnection()
        client.sseConnection = mockSSEConnection
        client.inactivityDelayMS = 0
        NotificationCenter.default.post(name: UIApplication.willResignActiveNotification, object: nil)
        
        let expectation = XCTestExpectation(description: "close gets called when backgrounded")
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            XCTAssert(mockSSEConnection.closeCalled)
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 2.0)
    }

    func testSseReopenGetsCalledWhenForegrounded() {
        let client = try! self.builder.user(self.user).environmentKey("my_env_key").build(onInitialized: nil)

        client.initialized = true
        
        let mockSSEConnection = MockSSEConnection()
        mockSSEConnection.connected = false
        client.sseConnection = mockSSEConnection
        NotificationCenter.default.post(name: UIApplication.willEnterForegroundNotification, object: nil)
        
        let expectation = XCTestExpectation(description: "reopen gets called when foregrounded")
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            XCTAssert(mockSSEConnection.reopenCalled)
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 2.0)
    }
    
    func testSseReopenDoesntGetCalledWhenForegroundedBeforeInactivityDelay() {
        let client = try! self.builder.user(self.user).environmentKey("my_env_key").build(onInitialized: nil)
        client.initialized = true
        
        let mockSSEConnection = MockSSEConnection()
        mockSSEConnection.connected = true
        client.sseConnection = mockSSEConnection
        client.inactivityDelayMS = 120000
        NotificationCenter.default.post(name: UIApplication.willEnterForegroundNotification, object: nil)
        
        let expectation = XCTestExpectation(description: "reopen doesn't called when foregrounded")
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            XCTAssertFalse(mockSSEConnection.reopenCalled)
            XCTAssertFalse(mockSSEConnection.closeCalled)
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 2.0)
    }
}

extension DVCClientTest {
    private class MockService: DevCycleServiceProtocol {
        public var publishCallCount: Int = 0
        public var userForGetConfig: DVCUser?
        public var numberOfConfigCalls: Int = 0
        public var eventPublishCount: Int = 0

        func getConfig(user: DVCUser, enableEdgeDB: Bool, extraParams: RequestParams?, completion: @escaping ConfigCompletionHandler) {
            self.userForGetConfig = user
            self.numberOfConfigCalls += 1

            XCTAssert(true)
        }

        func publishEvents(events: [DVCEvent], user: DVCUser, completion: @escaping PublishEventsCompletionHandler) {
            self.publishCallCount += 1
            self.eventPublishCount += events.count
            XCTAssert(true)
            Timer.scheduledTimer(withTimeInterval: 0.1, repeats: false, block: { timer in
                completion((data: nil, urlResponse: nil, error: nil))
            })
        }
        
        func saveEntity(user: DVCUser, completion: @escaping SaveEntityCompletionHandler) {
            XCTAssert(true)
        }
        
        func makeRequest(request: URLRequest, completion: @escaping DevCycle.CompletionHandler) {
            XCTAssert(true)
        }
    }
    
    private class MockSSEConnection: SSEConnectionProtocol {
        var connected: Bool
        var reopenCalled: Bool
        var closeCalled: Bool
        
        init() {
            self.connected = false
            self.reopenCalled = false
            self.closeCalled = false
        }
        
        func openConnection() {}
        
        func close() {
            self.closeCalled = true
        }
        
        func reopen() {
            self.reopenCalled = true
        }
    }
}
