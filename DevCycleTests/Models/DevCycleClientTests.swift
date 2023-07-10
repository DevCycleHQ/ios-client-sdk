//
//  DevCycleClient.swift
//  DevCycleTests
//
//

import XCTest
#if os(iOS) || os(tvOS)
import UIKit
#elseif os(watchOS)
import WatchKit
#endif

@testable import DevCycle


class DevCycleClientTest: XCTestCase {
    private var service: MockService!
    private var user: DevCycleUser!
    private var builder: DevCycleClient.ClientBuilder!
    private var userConfig: UserConfig!
    
    override func setUp() {
        self.service = MockService()
        self.user = try! DevCycleUser.builder()
                    .userId("my_user")
                    .build()
        self.builder = DevCycleClient.builder().service(service)

        let data = getConfigData(name: "test_config")
        let dictionary = try! JSONSerialization.jsonObject(with: data, options: .fragmentsAllowed) as! [String:Any]
        self.userConfig = try! UserConfig(from: dictionary)
    }
        
    func testBuilderReturnsNilIfNoSDKKey() {
        XCTAssertNil(try? self.builder.user(self.user).build(onInitialized: nil))
    }
    
    func testBuilderReturnsNilIfNoUser() {
        XCTAssertNil(try? self.builder.sdkKey("my_sdk_key").build(onInitialized: nil))
    }
    
    func testBuilderReturnsClient() {
        let client = try! self.builder.user(self.user).sdkKey("my_sdk_key").build(onInitialized: nil)
        XCTAssertNotNil(client)
        XCTAssertNotNil(client.user)
        XCTAssertNotNil(client.sdkKey)
        XCTAssertNil(client.options)
        client.close(callback: nil)
    }
    
    func testBuilderReturnsClientUsingEnvironmentKey() {
        let client = try! self.builder.user(self.user).environmentKey("my_sdk_key").build(onInitialized: nil)
        XCTAssertNotNil(client)
        XCTAssertNotNil(client.user)
        XCTAssertNotNil(client.sdkKey)
        XCTAssertNil(client.options)
        client.close(callback: nil)
    }
    
    func testDepracatedDVCClientWorks() {
        let builder = DevCycleClient.builder().service(service)
        let client = try! builder.user(self.user).environmentKey("my_sdk_key").build(onInitialized: nil)
        XCTAssertNotNil(client)
        XCTAssertNotNil(client.user)
        XCTAssertNotNil(client.sdkKey)
        XCTAssertNil(client.options)
        client.close(callback: nil)
    }
    
    func testSetupCallsGetConfig() {
        let client = DevCycleClient()
        let service = MockService() // will assert if getConfig was called
        client.setSDKKey("")
        client.setUser(self.user)
        client.setup(service: service)
        client.close(callback: nil)
    }
    
    func testBuilderReturnsClientWithOptions() {
        let options = DVCOptions.builder().disableEventLogging(false).flushEventsIntervalMs(100).build()
        let client = try! self.builder.user(self.user).sdkKey("my_sdk_key").options(options).build(onInitialized: nil)
        XCTAssertNotNil(client)
        XCTAssertNotNil(client.options)
        XCTAssertNotNil(client.user)
        XCTAssertNotNil(client.sdkKey)
        client.close(callback: nil)
    }
    
    func testTrackWithValidDVCEventNoOptionals() {
        let expectation = XCTestExpectation(description: "EventQueue has one event")
        let client = DevCycleClient()
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
        let client = DevCycleClient()
        let metaData: [String:Any] = ["test1": "key", "test2": 2, "test3": false]
        let event: DVCEvent = try! DVCEvent.builder().type("test").target("test").clientDate(Date()).value(1).metaData(metaData).build()

        client.track(event)

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            XCTAssertTrue(client.eventQueue.events.count == 1)
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 1.0)
    }
    
    func testTrackWithValidDVCEventWithAllParamsDefinedAndDoubleValue() {
        let expectation = XCTestExpectation(description: "EventQueue has one fully defined event")
        let client = DevCycleClient()
        let metaData: [String:Any] = ["test1": "key", "test2": 2, "test3": false]
        let event: DVCEvent = try! DVCEvent.builder().type("test").target("test").clientDate(Date()).value(364.25).metaData(metaData).build()
        
        client.track(event)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            XCTAssertTrue(client.eventQueue.events.count == 1)
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 1.0)
    }
    
    func testFlushEventsWithOneEventInQueue() {
        let expectation = XCTestExpectation(description: "EventQueue publishes an event")
        let options = DVCOptions.builder().flushEventsIntervalMs(100).build()
        let service = MockService() // will assert if publishEvents was called

        let client = try! self.builder.user(self.user).sdkKey("my_sdk_key").options(options).service(service).build(onInitialized: nil)
        
        let event: DVCEvent = try! DVCEvent.builder().type("test").clientDate(Date()).build()
        
        client.track(event)
        client.flushEvents()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.01) {
            XCTAssertTrue(service.publishCallCount == 1)
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 1.0)
        client.close(callback: nil)
    }
    
    func testFlushEventsWithOneEventInQueueAndCallback() {
        let expectation = XCTestExpectation(description: "EventQueue publishes an event")
        let options = DVCOptions.builder().flushEventsIntervalMs(100).build()
        let service = MockService() // will assert if publishEvents was called

        let client = try! self.builder.user(self.user).sdkKey("my_sdk_key").options(options).service(service).build(onInitialized: nil)
        
        let event: DVCEvent = try! DVCEvent.builder().type("test").clientDate(Date()).build()
        
        client.track(event)
        client.flushEvents(callback: { error in
            XCTAssertNil(error)
            // test that later tracked events are ignored
            XCTAssertEqual(service.publishCallCount, 1)
            XCTAssertEqual(service.eventPublishCount, 1)
            expectation.fulfill()
        })
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.01) {
            XCTAssertTrue(service.publishCallCount == 1)
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 2.0)
    }
    
    func testCloseFlushesRemainingEvents() {
        let expectation = XCTestExpectation(description: "Close flushes remaining events")
        let options = DVCOptions.builder().flushEventsIntervalMs(10000).build()
        let client = try! self.builder.user(self.user).sdkKey("my_sdk_key").options(options).build(onInitialized: nil)
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
        client.close(callback: nil)
    }
    
    func testVariableReturnsDefaultForUnsupportedVariableKeys() {
        let client = try! self.builder.user(self.user).sdkKey("my_sdk_key").build(onInitialized: nil)
        let variable = client.variable(key: "UNSUPPORTED\\key%$", defaultValue: true)
        XCTAssertTrue(variable.value)
        let variableValue = client.variableValue(key: "UNSUPPORTED\\key%$", defaultValue: true)
        XCTAssertTrue(variableValue)
        client.close(callback: nil)
    }
    
    func testVariableFunctionWorksIfVariableKeyHasSupportedCharacters() {
        let client = try! self.builder.user(self.user).sdkKey("my_sdk_key").build(onInitialized: nil)
        let variable = client.variable(key: "supported-keys_here", defaultValue: true)
        XCTAssertTrue(variable.value)
        let variableValue = client.variableValue(key: "supported-keys_here", defaultValue: true)
        XCTAssertTrue(variableValue)
        client.close(callback: nil)
    }

    func testVariableMethodReturnsDefaultedVariableWhenKeyIsNotInConfig() {
        let client = try! self.builder.user(self.user).sdkKey("my_sdk_key").build(onInitialized: nil)
        client.config?.userConfig = self.userConfig
        client.initialize(callback: nil)

        let variable = client.variable(key: "some_non_existent_variable", defaultValue: false)
        XCTAssertFalse(variable.value)
        XCTAssertTrue(variable.isDefaulted)
        XCTAssertFalse(variable.defaultValue)
        
        let variableValue = client.variableValue(key: "some_non_existent_variable", defaultValue: false)
        XCTAssertFalse(variableValue)
        client.close(callback: nil)
    }

    func testVariableMethodReturnsCorrectVariableForKey() {
        let client = try! self.builder.user(self.user).sdkKey("my_sdk_key").build(onInitialized: nil)
        client.initialize(callback: nil)
        client.config?.userConfig = self.userConfig

        let boolVar = client.variable(key: "bool-var", defaultValue: false)
        XCTAssertTrue(boolVar.value)
        let boolValue = client.variableValue(key: "bool-var", defaultValue: false)
        XCTAssertTrue(boolValue)

        let numVar = client.variable(key: "num-var", defaultValue: 0)
        XCTAssertEqual(numVar.value, 4)
        let numValue = client.variableValue(key: "num-var", defaultValue: 0)
        XCTAssertEqual(numValue, 4)

        let stringVar = client.variable(key: "string-var", defaultValue: "default-string")
        XCTAssertEqual(stringVar.value, "string1")
        let stringValue = client.variableValue(key: "string-var", defaultValue: "default-string")
        XCTAssertEqual(stringValue, "string1")

        let defaultDict: NSDictionary = ["some_key": "some_value"]
        let jsonVar = client.variable(key: "json-var", defaultValue: defaultDict)
        XCTAssertEqual(jsonVar.value["key1"] as! String, "value1")
        XCTAssertEqual((jsonVar.value["key2"] as! NSDictionary)["nestedKey1"] as! String, "nestedValue1")
        let jsonValue = client.variableValue(key: "json-var", defaultValue: defaultDict)
        XCTAssertEqual(jsonValue["key1"] as! String, "value1")
        XCTAssertEqual((jsonValue["key2"] as! NSDictionary)["nestedKey1"] as! String, "nestedValue1")
        client.close(callback: nil)
    }

    func testVariableMethodReturnSameInstanceOfVariable() {
        let client = try! self.builder.user(self.user).sdkKey("my_sdk_key").build(onInitialized: nil)
        client.initialize(callback: nil)
        client.config?.userConfig = self.userConfig

        let boolVar = client.variable(key: "bool-var", defaultValue: false)
        XCTAssert(client.variable(key: "bool-var", defaultValue: false) === boolVar)

        let numVar = client.variable(key: "num-var", defaultValue: 0)
        XCTAssert(client.variable(key: "num-var", defaultValue: 0) === numVar)

        let stringVar = client.variable(key: "string-var", defaultValue: "default-string")
        XCTAssert(client.variable(key: "string-var", defaultValue: "default-string") === stringVar)

        let defaultDict: NSDictionary = ["some_key": "some_value"]
        let jsonVar = client.variable(key: "json-var", defaultValue: defaultDict)
        XCTAssert(client.variable(key: "json-var", defaultValue: defaultDict) === jsonVar)
        client.close(callback: nil)
    }

    func testVariableMethodReturnsDifferentVariableForANewDefaultValue() {
        let client = try! self.builder.user(self.user).sdkKey("my_sdk_key").build(onInitialized: nil)
        client.initialize(callback: nil)
        client.config?.userConfig = self.userConfig

        var stringVar = client.variable(key: "string-var", defaultValue: "default value")
        XCTAssert(client.variable(key: "string-var", defaultValue: "default value") === stringVar)

        stringVar = client.variable(key: "string-var", defaultValue: "new default value")
        XCTAssert(client.variable(key: "string-var", defaultValue: "new default value") === stringVar)
        client.close(callback: nil)
    }

    func testRefetchConfigUsesTheCorrectUser() {
        let service = MockService()
        let user1 = try! DevCycleUser.builder().userId("user1").build()
        let client = try! DevCycleClient.builder().user(user1).sdkKey("my_sdk_key").build(onInitialized: nil)
        client.setup(service: service)
        client.initialized = true

        XCTAssertEqual(client.lastIdentifiedUser?.userId, user1.userId)
        client.refetchConfig(sse: true, lastModified: 123, etag: "etag")
        XCTAssertEqual(service.numberOfConfigCalls, 2)

        let user2 = try! DevCycleUser.builder().userId("user2").build()
        try! client.identifyUser(user: user2)
        XCTAssertEqual(client.lastIdentifiedUser?.userId, user2.userId)
        client.refetchConfig(sse: true, lastModified: 456, etag: "etag")
        XCTAssertEqual(service.numberOfConfigCalls, 4)

        let user3 = try! DevCycleUser.builder().userId("user3").build()
        try! client.identifyUser(user: user3)
        XCTAssertEqual(client.lastIdentifiedUser?.userId, user3.userId)
        client.refetchConfig(sse: true, lastModified: 789, etag: "etag")
        XCTAssertEqual(service.numberOfConfigCalls, 6)
        client.close(callback: nil)
    }
    
    func testSseCloseGetsCalledWhenBackgrounded() {
        let client = try! self.builder.user(self.user).sdkKey("my_sdk_key").build(onInitialized: nil)
        client.initialized = true

        let mockSSEConnection = MockSSEConnection()
        client.sseConnection = mockSSEConnection
        client.inactivityDelayMS = 0
        #if os(iOS) || os(tvOS)
            NotificationCenter.default.post(name: UIApplication.willResignActiveNotification, object: nil)
        #elseif os(watchOS)
            NotificationCenter.default.post(name: WKExtension.applicationWillResignActiveNotification, object: nil)
        #elseif os(macOS)
            NotificationCenter.default.post(name: NSApplication.willResignActiveNotification, object: nil)
        #endif

        let expectation = XCTestExpectation(description: "close gets called when backgrounded")

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.01) {
            XCTAssert(mockSSEConnection.closeCalled)
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 2.0)
        client.close(callback: nil)
    }

    func testSseReopenGetsCalledWhenForegrounded() {
        let client = try! self.builder.user(self.user).sdkKey("my_sdk_key").build(onInitialized: nil)

        client.initialized = true

        let mockSSEConnection = MockSSEConnection()
        mockSSEConnection.connected = false
        client.sseConnection = mockSSEConnection
        #if os(iOS) || os(tvOS)
            NotificationCenter.default.post(name: UIApplication.willEnterForegroundNotification, object: nil)
        #elseif os(watchOS)
            NotificationCenter.default.post(name: WKExtension.applicationWillEnterForegroundNotification, object: nil)
        #elseif os(macOS)
            NotificationCenter.default.post(name: NSApplication.willBecomeActiveNotification, object: nil)
        #endif

        let expectation = XCTestExpectation(description: "reopen gets called when foregrounded")

        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            XCTAssert(mockSSEConnection.reopenCalled)
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 2.0)
        client.close(callback: nil)
    }
    
    func testSseReopenDoesntGetCalledWhenForegroundedBeforeInactivityDelay() {
        let client = try! self.builder.user(self.user).sdkKey("my_sdk_key").build(onInitialized: nil)
        client.initialized = true

        let mockSSEConnection = MockSSEConnection()
        mockSSEConnection.connected = true
        client.sseConnection = mockSSEConnection
        client.inactivityDelayMS = 120000
        #if os(iOS) || os(tvOS)
            NotificationCenter.default.post(name: UIApplication.willEnterForegroundNotification, object: nil)
        #elseif os(watchOS)
            NotificationCenter.default.post(name: WKExtension.applicationWillEnterForegroundNotification, object: nil)
        #elseif os(macOS)
            NotificationCenter.default.post(name: NSApplication.willBecomeActiveNotification, object: nil)
        #endif

        let expectation = XCTestExpectation(description: "reopen doesn't called when foregrounded")

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            XCTAssertFalse(mockSSEConnection.reopenCalled)
            XCTAssertFalse(mockSSEConnection.closeCalled)
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 2.0)
    }
    
    func testIdentifyUserClearsCachedAnonymousUserId() {
        // Build Anon User, generates a new UUID
        let anonUser1 = try! DevCycleUser.builder().isAnonymous(true).build()
        XCTAssertNotNil(anonUser1)
        
        // Call Identify with a NOT anonymous User, this should erase the Cached UUID of anonUser1
        let client = try! self.builder.user(self.user).sdkKey("my_sdk_key").build(onInitialized: { [weak self] error in
            // Since the cached Anonymous User Id is only cleared on successful identify call,
            // the anonUser3.userId should be the same as anonUser1.userId
            let anonUser3 = try! DevCycleUser.builder().isAnonymous(true).build()
            XCTAssertNotNil(anonUser3)
            XCTAssertEqual(anonUser3.userId, anonUser1.userId)
        })
        client.config?.userConfig = self.userConfig
        client.initialize(callback: nil)
        
        try! client.identifyUser(user: self.user, callback: { [weak self] error, variables in
            // Wait for successful identifyUser callback, then build a new anonymous User, which SHOULD generate a new UUID
            let anonUser2 = try! DevCycleUser.builder().isAnonymous(true).build()
            XCTAssertNotNil(anonUser2)
            XCTAssertNotEqual(anonUser2.userId, anonUser1.userId)
        })
        client.close(callback: nil)
    }
    
    func testResetUserGeneratesANewAnonymousUserId() {
        let anonUser1 = try! DevCycleUser.builder().isAnonymous(true).build()
        XCTAssertNotNil(anonUser1)
        
        let client = try! self.builder.user(anonUser1).sdkKey("my_sdk_key").build(onInitialized: nil)
        client.initialize(callback: nil)
        client.config?.userConfig = self.userConfig
        
        try! client.resetUser()
        
        // client.lastIdentifiedUser is updated to be the anonymous user when `resetUser` is called
        XCTAssertNotEqual(anonUser1.userId, client.lastIdentifiedUser?.userId)
        client.close(callback: nil)
    }
    
        func testDisableCustomEventLogging() {
            let expectation = XCTestExpectation(description: "test disableCustomEventLogging")
            let options = DVCOptions.builder().disableCustomEventLogging(true).flushEventsIntervalMs(100).build()
            let service = MockService() // will assert if publishEvents was called

            let client = try! self.builder.user(self.user).sdkKey("my_sdk_key").options(options).service(service).build(onInitialized: nil)

            let event: DVCEvent = try! DVCEvent.builder().type("test").clientDate(Date()).build()

            client.track(event)
            client.flushEvents()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                XCTAssertTrue(service.publishCallCount == 0)
                expectation.fulfill()
            }

            wait(for: [expectation], timeout: 1)
            client.close(callback: nil)
        }
    
        func testDisableAutomaticEventLogging() {
            let expectation = XCTestExpectation(description: "test disableAutomaticEventLogging")
            let options = DVCOptions.builder().disableAutomaticEventLogging(true).flushEventsIntervalMs(10000).build()
            let service = MockService() // will assert if publishEvents was called
    
            let client = try! self.builder.user(self.user).sdkKey("my_sdk_key").options(options).service(service).build(onInitialized: nil)
    
            let event: DVCEvent = try! DVCEvent.builder().type("test").clientDate(Date()).build()
    
            client.variable(key: "test-key", defaultValue: false)
            client.flushEvents()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                XCTAssertTrue(service.publishCallCount == 0)
                expectation.fulfill()
            }
    
            wait(for: [expectation], timeout: 1.0)
            client.close(callback: nil)
        }

}

extension DevCycleClientTest {
    private class MockService: DevCycleServiceProtocol {
        public var publishCallCount: Int = 0
        public var userForGetConfig: DevCycleUser?
        public var numberOfConfigCalls: Int = 0
        public var eventPublishCount: Int = 0

        func getConfig(user: DevCycleUser, enableEdgeDB: Bool, extraParams: RequestParams?, completion: @escaping ConfigCompletionHandler) {
            self.userForGetConfig = user
            self.numberOfConfigCalls += 1

            XCTAssert(true)
        }

        func publishEvents(events: [DVCEvent], user: DevCycleUser, completion: @escaping PublishEventsCompletionHandler) {
            self.publishCallCount += 1
            self.eventPublishCount += events.count
            XCTAssert(true)
            Timer.scheduledTimer(withTimeInterval: 0.1, repeats: false, block: { timer in
                completion((data: nil, urlResponse: nil, error: nil))
            })
        }
        
        func saveEntity(user: DevCycleUser, completion: @escaping SaveEntityCompletionHandler) {
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
