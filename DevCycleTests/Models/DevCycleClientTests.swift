//
//  DevCycleClient.swift
//  DevCycleTests
//
//

import XCTest

@testable import DevCycle

#if os(iOS) || os(tvOS)
    import UIKit
#elseif os(watchOS)
    import WatchKit
#endif

class DevCycleClientTest: XCTestCase {
    private var service: MockService!
    private var user: DevCycleUser!
    private var builder: DevCycleClient.ClientBuilder!
    private var userConfig: UserConfig!

    override func setUp() {
        let data = getConfigData(name: "test_config")
        let dictionary =
            try! JSONSerialization.jsonObject(with: data, options: .fragmentsAllowed)
            as! [String: Any]
        self.userConfig = try! UserConfig(from: dictionary)
        self.service = MockService(userConfig: self.userConfig)
        self.user = try! DevCycleUser.builder()
            .userId("my_user")
            .build()
        self.builder = DevCycleClient.builder().service(service)
    }

    func testBuilderReturnsNilIfNoSDKKey() {
        XCTAssertNil(try? self.builder.user(self.user).build(onInitialized: nil))
    }

    func testBuilderReturnsNilIfNoUser() {
        XCTAssertNil(try? self.builder.sdkKey("my_sdk_key").build(onInitialized: nil))
    }

    func testBuilderReturnsClient() {
        let client = try! self.builder.user(self.user).sdkKey("my_sdk_key").build(
            onInitialized: nil)
        XCTAssertNotNil(client)
        XCTAssertNotNil(client.user)
        XCTAssertNotNil(client.sdkKey)
        XCTAssertNil(client.options)
        client.close(callback: nil)
    }

    func testBuilderReturnsClientUsingEnvironmentKey() {
        let client = try! self.builder.user(self.user).environmentKey("my_sdk_key").build(
            onInitialized: nil)
        XCTAssertNotNil(client)
        XCTAssertNotNil(client.user)
        XCTAssertNotNil(client.sdkKey)
        XCTAssertNil(client.options)
        client.close(callback: nil)
    }

    func testDeprecatedDVCClientWorks() {
        let builder = DVCClient.builder().service(service)
        let client = try! builder.user(self.user).environmentKey("my_sdk_key").build(
            onInitialized: nil)
        XCTAssertNotNil(client)
        XCTAssertNotNil(client.user)
        XCTAssertNotNil(client.sdkKey)
        XCTAssertNil(client.options)
        client.close(callback: nil)
    }

    func testSetupCallsGetConfig() {
        let client = DevCycleClient()
        let service = MockService(userConfig: self.userConfig)  // will assert if getConfig was called
        client.setSDKKey("")
        client.setUser(self.user)
        client.setup(service: service)
        client.close(callback: nil)
    }

    func testBuilderReturnsClientWithOptions() {
        let options = DevCycleOptions.builder().disableEventLogging(false).flushEventsIntervalMs(
            100
        ).build()
        let client = try! self.builder.user(self.user).sdkKey("my_sdk_key").options(options).build(
            onInitialized: nil)
        XCTAssertNotNil(client)
        XCTAssertNotNil(client.options)
        XCTAssertNotNil(client.user)
        XCTAssertNotNil(client.sdkKey)
        client.close(callback: nil)
    }

    func testTrackWithValidDevCycleEventNoOptionals() {
        let expectation = XCTestExpectation(description: "EventQueue has one event")
        let client = DevCycleClient()
        let event: DevCycleEvent = try! DevCycleEvent.builder().type("test").build()

        client.track(event)

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            XCTAssertTrue(client.eventQueue.events.count == 1)
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 1.0)
    }

    func testTrackWithValidDevCycleEventWithAllParamsDefined() {
        let expectation = XCTestExpectation(description: "EventQueue has one fully defined event")
        let client = DevCycleClient()
        let metaData: [String: Any] = ["test1": "key", "test2": 2, "test3": false]
        let event: DevCycleEvent = try! DevCycleEvent.builder().type("test").target("test")
            .clientDate(Date()).value(1).metaData(metaData).build()

        client.track(event)

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            XCTAssertTrue(client.eventQueue.events.count == 1)
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 1.0)
    }

    func testTrackWithValidDevCycleEventWithAllParamsDefinedAndDoubleValue() {
        let expectation = XCTestExpectation(description: "EventQueue has one fully defined event")
        let client = DevCycleClient()
        let metaData: [String: Any] = ["test1": "key", "test2": 2, "test3": false]
        let event: DevCycleEvent = try! DevCycleEvent.builder().type("test").target("test")
            .clientDate(Date()).value(364.25).metaData(metaData).build()

        client.track(event)

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            XCTAssertTrue(client.eventQueue.events.count == 1)
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 1.0)
    }

    func testFlushEventsWithOneEventInQueue() {
        let expectation = XCTestExpectation(description: "EventQueue publishes an event")
        let options = DevCycleOptions.builder().flushEventsIntervalMs(100).build()
        let service = MockService(userConfig: self.userConfig)  // will assert if publishEvents was called

        let client = try! self.builder.user(self.user).sdkKey("my_sdk_key").options(options)
            .service(service).build(onInitialized: nil)

        let event: DevCycleEvent = try! DevCycleEvent.builder().type("test").clientDate(Date())
            .build()

        client.track(event)
        client.flushEvents()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.01) {
            XCTAssertTrue(service.publishCallCount == 1)
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 2.0)
        client.close(callback: nil)
    }

    func testFlushEventsWithEvalReasons() throws {
        let data = getConfigData(name: "test_config_eval_reason")
        let dictionary = try JSONSerialization.jsonObject(with: data, options: .fragmentsAllowed) as! [String:Any]
        let evalReasonConfig = try UserConfig(from: dictionary)

        let options = DevCycleOptions.builder().eventFlushIntervalMS(100).build()
        let service = MockService(userConfig: evalReasonConfig)

        let client = try! DevCycleClient.builder().user(self.user).sdkKey("my_sdk_key").options(options).build(
            onInitialized: nil)
        client.setup(service: service)
        client.config?.userConfig = evalReasonConfig
        client.initialized = true

        XCTAssertTrue(client.initialized)

        let variable1 = client.variable(key: "string-var", defaultValue: "test_string")
        XCTAssertEqual(variable1.value, "string1")
        XCTAssertEqual(variable1.eval?.reason, "TARGETING_MATCH")
        XCTAssertEqual(variable1.eval?.details, "Platform AND App Version")
        XCTAssertEqual(variable1.eval?.targetId, "target_id_1")
        
        let variable2Value = client.variableValue(key: "bool-var", defaultValue: false)
        XCTAssertTrue(variable2Value)
        
        let defaultVariable = client.variable(key: "title_text", defaultValue: "Default")
        XCTAssertEqual(defaultVariable.value, "Default")
        XCTAssertEqual(defaultVariable.eval?.reason, "DEFAULT")
        XCTAssertEqual(defaultVariable.eval?.details, "User Not Targeted")
        XCTAssertNil(defaultVariable.eval?.targetId)
        
        // This variable call returns early and does not trigger any variable defaulted event
        let invalidVariable = client.variable(key: "INVALID Variable!", defaultValue: "fail")
        XCTAssertEqual(invalidVariable.value, "fail")
        XCTAssertEqual(invalidVariable.eval?.reason, "DEFAULT")
        XCTAssertEqual(invalidVariable.eval?.details, "Invalid Variable Key")
        XCTAssertNil(invalidVariable.eval?.targetId)
        
        let expectation = XCTestExpectation(description: "EventQueue has events with Eval metadata")
        // Add a slight delay to ensure events are queued correctly
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.01) {
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 0.5)
        
        let variableEvaluatedEvents = client.eventQueue.aggregateEventQueue.variableEvaluated
        XCTAssertEqual(variableEvaluatedEvents.count, 2)
        
        let variableDefaultedEvents = client.eventQueue.aggregateEventQueue.variableDefaulted
        XCTAssertEqual(variableDefaultedEvents.count, 1)
        
        let expectedEvaluatedMetadata = ["eval": ["reason": "TARGETING_MATCH", "details": "Platform AND App Version", "target_id": "target_id_1"]]
        XCTAssertEqual(variableEvaluatedEvents["bool-var"]?.metaData as! [String: [String:String]], expectedEvaluatedMetadata)
        XCTAssertEqual(variableEvaluatedEvents["string-var"]?.metaData as! [String: [String:String]], expectedEvaluatedMetadata)
        
        let expectedDefaultedMetadata = ["eval": ["reason": "DEFAULT", "details": "User Not Targeted"]]
        XCTAssertEqual(variableDefaultedEvents["title_text"]?.metaData as! [String : [String : String?]], expectedDefaultedMetadata)
        
        client.flushEvents()
        
        let publishExpectation = XCTestExpectation(description: "EventQueue publishes an event")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.01) {
            XCTAssertTrue(service.publishCallCount == 1)
            publishExpectation.fulfill()
        }
        wait(for: [publishExpectation], timeout: 0.5)
        client.close(callback: nil)
    }

    func testFlushEventsWithOneEventInQueueAndCallback() {
        let expectation = XCTestExpectation(description: "EventQueue publishes an event")
        let options = DevCycleOptions.builder().flushEventsIntervalMs(100).build()
        let service = MockService(userConfig: self.userConfig)  // will assert if publishEvents was called

        let client = try! self.builder.user(self.user).sdkKey("my_sdk_key").options(options)
            .service(service).build(onInitialized: nil)

        let event: DevCycleEvent = try! DevCycleEvent.builder().type("test").clientDate(Date())
            .build()

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
        let options = DevCycleOptions.builder().flushEventsIntervalMs(10000).build()
        let client = try! self.builder.user(self.user).sdkKey("my_sdk_key").options(options).build(
            onInitialized: nil)
        let service = MockService(userConfig: self.userConfig)  // will assert if publishEvents was called
        client.setup(service: service)
        let event: DevCycleEvent = try! DevCycleEvent.builder().type("test").clientDate(Date())
            .build()

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

    func testVariableDeprecatedMethod() {
        let client = try! self.builder.user(self.user).sdkKey("my_sdk_key").build(
            onInitialized: nil)
        let defaultVal: Int = 1
        let variable = client.variable(key: "key", defaultValue: defaultVal)
        XCTAssertTrue(variable.value == defaultVal)
        XCTAssertTrue(variable.isDefaulted)
        let variableValue = client.variableValue(key: "key", defaultValue: defaultVal)
        XCTAssertTrue(variableValue == defaultVal)
        client.close(callback: nil)
    }

    func testVariableReturnsDefaultForUnsupportedVariableKeys() {
        let client = try! self.builder.user(self.user).sdkKey("my_sdk_key").build(
            onInitialized: nil)
        let variable = client.variable(key: "UNSUPPORTED\\key%$", defaultValue: true)
        XCTAssertTrue(variable.value)
        let variableValue = client.variableValue(key: "UNSUPPORTED\\key%$", defaultValue: true)
        XCTAssertTrue(variableValue)
        client.close(callback: nil)
    }

    func testVariableFunctionWorksIfVariableKeyHasSupportedCharacters() {
        let client = try! self.builder.user(self.user).sdkKey("my_sdk_key").build(
            onInitialized: nil)
        let variable = client.variable(key: "supported-keys_here", defaultValue: true)
        XCTAssertTrue(variable.value)
        let variableValue = client.variableValue(key: "supported-keys_here", defaultValue: true)
        XCTAssertTrue(variableValue)
        client.close(callback: nil)
    }

    func testVariableKeyWithDotsIsValid() {
        let client = try! self.builder.user(self.user).sdkKey("my_sdk_key").build(
            onInitialized: nil)
        let variable1 = client.variable(key: "key.with.dots", defaultValue: true)
        XCTAssertTrue(variable1.value)
        XCTAssertEqual(variable1.eval?.reason, "DEFAULT")
        XCTAssertEqual(variable1.eval?.details, "User Not Targeted")
        
        let variable2 = client.variable(key: "test.key_123", defaultValue: "default")
        XCTAssertEqual(variable2.value, "default")
        XCTAssertEqual(variable2.eval?.reason, "DEFAULT")
        
        let variable3 = client.variable(key: "a.b.c.d.e", defaultValue: 42)
        XCTAssertEqual(variable3.value, 42)
        client.close(callback: nil)
    }

    func testVariableKeyWithInvalidCharactersReturnsDefault() {
        let client = try! self.builder.user(self.user).sdkKey("my_sdk_key").build(
            onInitialized: nil)
        
        let invalidKeys = [
            "UPPERCASE",
            "MixedCase",
            "key with spaces",
            "key@special",
            "key#hash",
            "key$dollar",
            "key%percent",
            "key^caret",
            "key&",
            "key*asterisk",
            "key(open",
            "key)close",
            "key+plus",
            "key=equals",
            "key[open",
            "key]close",
            "key{open",
            "key}close",
            "key|pipe",
            "key\\backslash",
            "key/slash",
            "key:colon",
            "key;semcolon",
            "key\"quote",
            "key'apostrophe",
            "key<less",
            "key>greater",
            "key?question",
            "key~tilde",
            "key`backtick"
        ]
        
        for invalidKey in invalidKeys {
            let variable = client.variable(key: invalidKey, defaultValue: "default")
            XCTAssertEqual(variable.value, "default")
            XCTAssertEqual(variable.eval?.reason, "DEFAULT")
            XCTAssertEqual(variable.eval?.details, "Invalid Variable Key")
            XCTAssertTrue(variable.isDefaulted)
        }
        client.close(callback: nil)
    }

    func testVariableKeyLengthValidation() {
        let client = try! self.builder.user(self.user).sdkKey("my_sdk_key").build(
            onInitialized: nil)
        
        let emptyKey = client.variable(key: "", defaultValue: "default")
        XCTAssertEqual(emptyKey.value, "default")
        XCTAssertEqual(emptyKey.eval?.reason, "DEFAULT")
        XCTAssertEqual(emptyKey.eval?.details, "Invalid Variable Key")
        XCTAssertTrue(emptyKey.isDefaulted)
        
        let singleChar = client.variable(key: "a", defaultValue: "default")
        XCTAssertEqual(singleChar.value, "default")
        XCTAssertEqual(singleChar.eval?.reason, "DEFAULT")
        XCTAssertEqual(singleChar.eval?.details, "User Not Targeted")
        
        let maxLengthKey = String(repeating: "a", count: 100)
        let maxKey = client.variable(key: maxLengthKey, defaultValue: "default")
        XCTAssertEqual(maxKey.value, "default")
        XCTAssertEqual(maxKey.eval?.reason, "DEFAULT")
        XCTAssertEqual(maxKey.eval?.details, "User Not Targeted")
        
        let tooLongKey = String(repeating: "a", count: 101)
        let longKey = client.variable(key: tooLongKey, defaultValue: "default")
        XCTAssertEqual(longKey.value, "default")
        XCTAssertEqual(longKey.eval?.reason, "DEFAULT")
        XCTAssertEqual(longKey.eval?.details, "Invalid Variable Key")
        XCTAssertTrue(longKey.isDefaulted)
        
        client.close(callback: nil)
    }

    func testVariableKeyWithValidCharacters() {
        let client = try! self.builder.user(self.user).sdkKey("my_sdk_key").build(
            onInitialized: nil)
        
        let validKeys = [
            "lowercase",
            "with123numbers",
            "with-hyphens",
            "with_underscores",
            "with.dots",
            "mixed-123_key.test",
            "a1.b2_c3-d4",
            "test.key_123-value"
        ]
        
        for validKey in validKeys {
            let variable = client.variable(key: validKey, defaultValue: "default")
            XCTAssertEqual(variable.value, "default")
            XCTAssertEqual(variable.eval?.reason, "DEFAULT")
            XCTAssertEqual(variable.eval?.details, "User Not Targeted")
        }
        client.close(callback: nil)
    }

    func testVariableMethodReturnsDefaultedVariableWhenKeyIsNotInConfig() {
        let client = try! self.builder.user(self.user).sdkKey("my_sdk_key").build(
            onInitialized: nil)
        client.setup(service: self.service)
        client.config?.userConfig = self.userConfig
        client.initialize(callback: nil)

        let variable = client.variable(key: "some_non_existent_variable", defaultValue: false)
        XCTAssertFalse(variable.value)
        XCTAssertTrue(variable.isDefaulted)
        XCTAssertFalse(variable.defaultValue)

        let variableValue = client.variableValue(
            key: "some_non_existent_variable", defaultValue: false)
        XCTAssertFalse(variableValue)
    }

    func testVariableStringDefaultValue() {
        let client = try! self.builder.user(self.user).sdkKey("my_sdk_key").build(
            onInitialized: nil)
        client.config?.userConfig = self.userConfig
        client.initialize(callback: nil)

        let variable = client.variable(key: "some_non_existent_variable", defaultValue: "string")
        XCTAssertEqual(variable.value, "string")
        XCTAssert(variable.isDefaulted)
        XCTAssertEqual(variable.defaultValue, "string")
        XCTAssertEqual(variable.type, DVCVariableTypes.String)

        let nsString: NSString = "nsString"
        let varNSString = client.variable(key: "some_non_existent_variable", defaultValue: nsString)
        XCTAssertEqual(varNSString.defaultValue, nsString)
        XCTAssertEqual(varNSString.type, DVCVariableTypes.String)
    }

    func testVariableBooleanDefaultValue() {
        let client = try! self.builder.user(self.user).sdkKey("my_sdk_key").build(
            onInitialized: nil)
        client.config?.userConfig = self.userConfig
        client.initialize(callback: nil)

        let variable = client.variable(key: "some_non_existent_variable", defaultValue: true)
        XCTAssertEqual(variable.value, true)
        XCTAssert(variable.isDefaulted)
        XCTAssertEqual(variable.defaultValue, true)
        XCTAssertEqual(variable.type, DVCVariableTypes.Boolean)
    }

    func testVariableNumberDefaultValue() {
        let client = try! self.builder.user(self.user).sdkKey("my_sdk_key").build(
            onInitialized: nil)
        client.config?.userConfig = self.userConfig
        client.initialize(callback: nil)

        let double: Double = 10.1
        let variable = client.variable(key: "some_non_existent_variable", defaultValue: double)
        XCTAssertEqual(variable.value, double)
        XCTAssert(variable.isDefaulted)
        XCTAssertEqual(variable.defaultValue, double)
        XCTAssertEqual(variable.type, DVCVariableTypes.Number)

        let nsNum: NSNumber = 10.1
        let variableNum = client.variable(key: "some_non_existent_variable", defaultValue: nsNum)
        XCTAssertEqual(variableNum.defaultValue, nsNum)
        XCTAssertEqual(variableNum.type, DVCVariableTypes.Number)
    }

    func testVariableJSONDefaultValue() {
        let client = try! self.builder.user(self.user).sdkKey("my_sdk_key").build(
            onInitialized: nil)
        client.config?.userConfig = self.userConfig
        client.initialize(callback: nil)

        let defaultVal: [String: Any] = ["key": "val"]
        let variable = client.variable(key: "some_non_existent_variable", defaultValue: defaultVal)
        XCTAssertEqual(variable.value.keys, defaultVal.keys)
        XCTAssertEqual(variable.value["key"] as! String, defaultVal["key"] as! String)
        XCTAssert(variable.isDefaulted)
        XCTAssertEqual(variable.defaultValue["key"] as! String, defaultVal["key"] as! String)
        XCTAssertEqual(variable.type, DVCVariableTypes.JSON)

        let nsDicDefault: NSDictionary = ["key": "val"]
        let variable2 = client.variable(
            key: "some_non_existent_variable", defaultValue: nsDicDefault)
        XCTAssertEqual(variable2.defaultValue, nsDicDefault)
        XCTAssertEqual(variable2.type, DVCVariableTypes.JSON)
    }

    func testVariableMethodReturnsCorrectVariableForKey() {
        let client = try! self.builder.user(self.user).sdkKey("my_sdk_key").build(
            onInitialized: nil)
        client.initialize(callback: nil)
        client.setup(service: self.service)
        client.config?.userConfig = self.userConfig

        let boolVar = client.variable(key: "bool-var", defaultValue: false)
        XCTAssertTrue(boolVar.value)
        let boolValue = client.variableValue(key: "bool-var", defaultValue: false)
        XCTAssertTrue(boolValue)

        let numVar = client.variable(key: "num-var", defaultValue: 0.0)
        XCTAssertEqual(numVar.value, 4)
        let numValue = client.variableValue(key: "num-var", defaultValue: 0.0)
        XCTAssertEqual(numValue, 4)

        let stringVar = client.variable(key: "string-var", defaultValue: "default-string")
        XCTAssertEqual(stringVar.value, "string1")
        let stringValue = client.variableValue(key: "string-var", defaultValue: "default-string")
        XCTAssertEqual(stringValue, "string1")

        let defaultDict: NSDictionary = ["some_key": "some_value"]
        let jsonVar = client.variable(key: "json-var", defaultValue: defaultDict)
        XCTAssertEqual(jsonVar.value["key1"] as! String, "value1")
        XCTAssertEqual(
            (jsonVar.value["key2"] as! NSDictionary)["nestedKey1"] as! String, "nestedValue1")
        let jsonValue = client.variableValue(key: "json-var", defaultValue: defaultDict)
        XCTAssertEqual(jsonValue["key1"] as! String, "value1")
        XCTAssertEqual(
            (jsonValue["key2"] as! NSDictionary)["nestedKey1"] as! String, "nestedValue1")
        client.close(callback: nil)
    }

    func testVariableMethodReturnSameInstanceOfVariable() {
        let client = try! self.builder.user(self.user).sdkKey("my_sdk_key").build(
            onInitialized: nil)
        client.initialize(callback: nil)
        client.setup(service: self.service)
        client.config?.userConfig = self.userConfig

        let boolVar = client.variable(key: "bool-var", defaultValue: false)
        XCTAssert(client.variable(key: "bool-var", defaultValue: false) === boolVar)

        let numVar = client.variable(key: "num-var", defaultValue: 0.0)
        XCTAssert(client.variable(key: "num-var", defaultValue: 0.0) === numVar)

        let stringVar = client.variable(key: "string-var", defaultValue: "default-string")
        XCTAssert(client.variable(key: "string-var", defaultValue: "default-string") === stringVar)

        let defaultDict: NSDictionary = ["some_key": "some_value"]
        let jsonVar = client.variable(key: "json-var", defaultValue: defaultDict)
        XCTAssert(client.variable(key: "json-var", defaultValue: defaultDict) === jsonVar)
        client.close(callback: nil)
    }

    func testVariableMethodReturnsDifferentVariableForANewDefaultValue() {
        let client = try! self.builder.user(self.user).sdkKey("my_sdk_key").build(
            onInitialized: nil)
        client.initialize(callback: nil)
        client.setup(service: self.service)
        client.config?.userConfig = self.userConfig

        var stringVar = client.variable(key: "string-var", defaultValue: "default value")
        XCTAssert(client.variable(key: "string-var", defaultValue: "default value") === stringVar)

        stringVar = client.variable(key: "string-var", defaultValue: "new default value")
        XCTAssert(
            client.variable(key: "string-var", defaultValue: "new default value") === stringVar)
        client.close(callback: nil)
    }

    func testRefetchConfigUsesTheCorrectUser() {
        let service = MockService(userConfig: self.userConfig)
        let user1 = try! DevCycleUser.builder().userId("user1").build()
        let client = try! DevCycleClient.builder().user(user1).sdkKey("my_sdk_key").build(
            onInitialized: nil)
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
        let client = try! self.builder.user(self.user).sdkKey("my_sdk_key").build(
            onInitialized: nil)
        client.initialized = true

        let mockSSEConnection = MockSSEConnection()
        client.sseConnection = mockSSEConnection
        client.inactivityDelayMS = 0
        #if os(iOS) || os(tvOS)
            NotificationCenter.default.post(
                name: UIApplication.willResignActiveNotification, object: nil)
        #elseif os(watchOS)
            NotificationCenter.default.post(
                name: WKExtension.applicationWillResignActiveNotification, object: nil)
        #elseif os(macOS)
            NotificationCenter.default.post(
                name: NSApplication.willResignActiveNotification, object: nil)
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
        let client = try! self.builder.user(self.user).sdkKey("my_sdk_key").build(
            onInitialized: nil)

        client.initialized = true

        let mockSSEConnection = MockSSEConnection()
        mockSSEConnection.connected = false
        client.sseConnection = mockSSEConnection
        #if os(iOS) || os(tvOS)
            NotificationCenter.default.post(
                name: UIApplication.willEnterForegroundNotification, object: nil)
        #elseif os(watchOS)
            NotificationCenter.default.post(
                name: WKExtension.applicationWillEnterForegroundNotification, object: nil)
        #elseif os(macOS)
            NotificationCenter.default.post(
                name: NSApplication.willBecomeActiveNotification, object: nil)
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
        let client = try! self.builder.user(self.user).sdkKey("my_sdk_key").build(
            onInitialized: nil)
        client.initialized = true

        let mockSSEConnection = MockSSEConnection()
        mockSSEConnection.connected = true
        client.sseConnection = mockSSEConnection
        client.inactivityDelayMS = 120000
        #if os(iOS) || os(tvOS)
            NotificationCenter.default.post(
                name: UIApplication.willEnterForegroundNotification, object: nil)
        #elseif os(watchOS)
            NotificationCenter.default.post(
                name: WKExtension.applicationWillEnterForegroundNotification, object: nil)
        #elseif os(macOS)
            NotificationCenter.default.post(
                name: NSApplication.willBecomeActiveNotification, object: nil)
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

        // Add expectations to wait for both callbacks
        let onInitializedExpectation = XCTestExpectation(description: "onInitialized called")
        let identifyUserExpectation = XCTestExpectation(description: "identifyUser callback called")

        // Call Identify with a NOT anonymous User, this should NOT erase the Cached UUID of anonUser1
        let client = try! self.builder.user(self.user).sdkKey("my_sdk_key").build(onInitialized: {
            [weak self] error in
            // Since the cached Anonymous User Id is only cleared on resetUser,
            // the anonUser3.userId should be the same as anonUser1.userId
            let anonUser3 = try! DevCycleUser.builder().isAnonymous(true).build()
            XCTAssertNotNil(anonUser3)
            XCTAssertEqual(anonUser3.userId, anonUser1.userId)
            onInitializedExpectation.fulfill()
        })
        client.config?.userConfig = self.userConfig

        try! client.identifyUser(
            user: self.user,
            callback: { [weak self] error, variables in
                // After identifyUser, the anon user ID should still be the same
                let anonUser2 = try! DevCycleUser.builder().isAnonymous(true).build()
                XCTAssertNotNil(anonUser2)
                XCTAssertEqual(anonUser2.userId, anonUser1.userId)
                identifyUserExpectation.fulfill()
            })
        client.close(callback: nil)

        // Wait for both callbacks to complete
        wait(for: [onInitializedExpectation, identifyUserExpectation], timeout: 1.0)
    }

    func testResetUserGeneratesANewAnonymousUserId() {
        let anonUser1 = try! DevCycleUser.builder().isAnonymous(true).build()
        XCTAssertNotNil(anonUser1)

        let client = try! self.builder.user(anonUser1).sdkKey("my_sdk_key").build(
            onInitialized: nil)
        client.initialize(callback: nil)
        client.config?.userConfig = self.userConfig

        try! client.resetUser()

        // client.lastIdentifiedUser is updated to be the anonymous user when `resetUser` is called
        XCTAssertNotEqual(anonUser1.userId, client.lastIdentifiedUser?.userId)
        client.close(callback: nil)
    }

    func testDisableCustomEventLogging() {
        let expectation = XCTestExpectation(description: "test disableCustomEventLogging")
        let options = DevCycleOptions.builder().disableCustomEventLogging(true)
            .flushEventsIntervalMs(100).build()
        let service = MockService(userConfig: self.userConfig)  // will assert if publishEvents was called

        let client = try! self.builder.user(self.user).sdkKey("my_sdk_key").options(options)
            .service(service).build(onInitialized: nil)

        let event: DevCycleEvent = try! DevCycleEvent.builder().type("test").clientDate(Date())
            .build()

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
        let options = DevCycleOptions.builder().disableAutomaticEventLogging(true)
            .flushEventsIntervalMs(10000).build()
        let service = MockService(userConfig: self.userConfig)  // will assert if publishEvents was called

        let client = try! self.builder.user(self.user).sdkKey("my_sdk_key").options(options)
            .service(service).build(onInitialized: nil)

        let event: DevCycleEvent = try! DevCycleEvent.builder().type("test").clientDate(Date())
            .build()

        client.variable(key: "test-key", defaultValue: false)
        client.flushEvents()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            XCTAssertTrue(service.publishCallCount == 0)
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 1.0)
        client.close(callback: nil)
    }

    @available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.0, *)
    func testAsyncIdentifyUser() async throws {
        let client = try await self.builder.user(self.user).sdkKey("my_sdk_key").service(service)
            .build()
        client.config = DVCConfig(sdkKey: "my_sdk_key", user: self.user)

        let variables = try await client.identifyUser(user: self.user)
        XCTAssertNotNil(variables)
        client.close(callback: nil)
    }

    @available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.0, *)
    func testAsyncResetUser() async throws {
        let client = try await self.builder.user(self.user).sdkKey("my_sdk_key").service(service)
            .build()
        client.config = DVCConfig(sdkKey: "my_sdk_key", user: self.user)

        let variables = try await client.resetUser()
        XCTAssertNotNil(variables)
        client.close(callback: nil)
    }

    @available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.0, *)
    func testAsyncFlushEvents() async throws {
        let client = try await self.builder.user(self.user).sdkKey("my_sdk_key").service(service)
            .build()
        let event: DevCycleEvent = try! DevCycleEvent.builder().type("test").clientDate(Date())
            .build()
        client.track(event)
        try await client.flushEvents()
        XCTAssertEqual(service.publishCallCount, 1)
        client.close(callback: nil)
    }

    @available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.0, *)
    func testAsyncClose() async throws {
        let client = try await self.builder.user(self.user).sdkKey("my_sdk_key").service(service)
            .build()
        await client.close()
    }

    func testFailedConfigFetch() {
        let expectation = XCTestExpectation(description: "Config fetch fails")
        let failedService = MockFailedConnectionService()
        let client = try! self.builder.user(self.user).sdkKey("dvc_mobile_my_sdk_key").service(
            failedService
        ).build(onInitialized: nil)

        client.setup(
            service: failedService,
            callback: { error in
                XCTAssertNotNil(error)
                // Test that the client's state is initialized
                XCTAssertTrue(client.initialized)

                // Test that functions that depend on a config fetch behave appropriately even if it fails to get
                let variable = client.variable(
                    key: "some_non_existent_variable", defaultValue: false)
                XCTAssertTrue(variable.isDefaulted)
                XCTAssertFalse(variable.value)

                _ = client.allFeatures()
                _ = client.allVariables()

                do {
                    let user = try DevCycleUser.builder().userId("user1").build()

                    try client.identifyUser(user: user)
                    try client.resetUser()

                    client.track(
                        DevCycleEvent(
                            type: nil, target: nil, clientDate: nil, value: nil, metaData: nil))
                    client.flushEvents()
                } catch {

                }
                expectation.fulfill()
            })

        wait(for: [expectation], timeout: 1.0)
        client.close(callback: nil)
    }

    func testIdentifyUserWithCacheAvailableDoesNotReturnError() {
        let expectation = XCTestExpectation(
            description: "identifyUser with cache available should not return error")
        let failedService = MockFailedConnectionService()

        // Create a mock cache service that returns a cached config
        let mockCacheService = MockCacheServiceWithConfig(userConfig: self.userConfig)

        let client = try! self.builder.user(self.user).sdkKey("dvc_mobile_my_sdk_key").service(
            failedService
        ).build(onInitialized: nil)

        // Replace the cache service with our mock that has a cached config
        client.cacheService = mockCacheService

        // Initialize the client's config object
        client.config = DVCConfig(sdkKey: "dvc_mobile_my_sdk_key", user: self.user)

        client.setup(
            service: failedService,
            callback: { error in
                // Build process should work with cache
                XCTAssertNil(error, "Build should not return error when cache is available")

                do {
                    let newUser = try DevCycleUser.builder().userId("new_user").build()

                    // identifyUser should work with cached config even when network fails
                    try client.identifyUser(
                        user: newUser,
                        callback: { error, variables in
                            XCTAssertNil(
                                error,
                                "identifyUser should not return error when cache is available")
                            XCTAssertNotNil(
                                variables,
                                "identifyUser should return variables when cache is available")
                            XCTAssertEqual(
                                client.user?.userId, newUser.userId,
                                "User should be updated to new user")
                            expectation.fulfill()
                        })
                } catch {
                    XCTFail("identifyUser should not throw when cache is available")
                    expectation.fulfill()
                }
            })

        wait(for: [expectation], timeout: 100.0)
        client.close(callback: nil)
    }

    func testIdentifyUserWithInvalidCachedConfigDoesNotReturnError() {
        let expectation = XCTestExpectation(
            description: "identifyUser with invalid cached config should not return error and delete the invalid cached config")
        let failedService = MockFailedConnectionService()

        let myUserCacheKey = "IDENTIFIED_CONFIG_my_user"
        let newUserCacheKey = "IDENTIFIED_CONFIG_new_user"

        let badConfigData = """
            {
                "project": {
                    "_id": "id1",
                    "key": "default"
                },
                "environment": {
                    "_id": "id2",
                    "key": "development"
                },
                "features": {},
                "featureVariationMap": {},
                "knownVariableKeys": [],
                "variables": [{
                    "invalid": {
                        "unexpected": "config_data"
                    }
                }],
            }
            """.data(using: .utf8)!

        let defaults = UserDefaults.standard

        defaults.set(getConfigData(name: "test_config_eval_reason"), forKey: myUserCacheKey)
        defaults.set(badConfigData, forKey: newUserCacheKey)

        let client = try! self.builder.user(self.user).sdkKey("dvc_mobile_my_sdk_key").service(
            failedService
        ).build(onInitialized: nil)

        // Initialize the client's config object
        client.config = DVCConfig(sdkKey: "dvc_mobile_my_sdk_key", user: self.user)

        client.setup(
            service: failedService,
            callback: { error in
                // Build process should work with cache
                XCTAssertNil(error, "Build should not return error when cache is available")

                do {
                    let newUser = try DevCycleUser.builder().userId("new_user").build()

                    // identifyUser should work with defaults even when network fails and the cached config is invalid
                    try client.identifyUser(
                        user: newUser,
                        callback: { error, variables in
                            XCTAssertEqual(
                                error?.localizedDescription,
                                "Failed to fetch config",
                                "identifyUser should throw failed to fetch config error"
                            )
                            XCTAssertNil(
                                variables,
                                "identifyUser should not change to the new User and continue to return variables for 'my_user'")
                            XCTAssertEqual(
                                client.user?.userId, self.user.userId,
                                "User should not be updated to new user")
                            XCTAssertNil(
                                client.cacheService.getConfig(user: newUser),
                                "Cached config should be cleared for the 'new_user'"
                            )
                            expectation.fulfill()
                        })
                } catch {
                    XCTFail("identifyUser should throw when the cached config is available but invalid")
                    expectation.fulfill()
                }
            })

        wait(for: [expectation], timeout: 10.0)
        client.close(callback: nil)

        // Cleanup explicitly configured cache entries
        defaults.removeObject(forKey: myUserCacheKey)
        defaults.removeObject(forKey: newUserCacheKey)
    }
}

extension DevCycleClientTest {
    private class MockService: DevCycleServiceProtocol {
        public var publishCallCount: Int = 0
        public var userForGetConfig: DevCycleUser?
        public var numberOfConfigCalls: Int = 0
        public var eventPublishCount: Int = 0
        public var userConfig: UserConfig?

        init(userConfig: UserConfig? = nil) {
            self.userConfig = userConfig
        }

        func getConfig(
            user: DevCycleUser,
            enableEdgeDB: Bool,
            extraParams: RequestParams?,
            completion: @escaping ConfigCompletionHandler
        ) {
            self.userForGetConfig = user
            self.numberOfConfigCalls += 1

            DispatchQueue.main.async {
                completion((self.userConfig, nil))
            }
        }

        func publishEvents(
            events: [DevCycleEvent], user: DevCycleUser,
            completion: @escaping PublishEventsCompletionHandler
        ) {
            self.publishCallCount += 1
            self.eventPublishCount += events.count
            XCTAssert(true)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                completion((data: nil, urlResponse: nil, error: nil))
            }
        }

        func saveEntity(user: DevCycleUser, completion: @escaping SaveEntityCompletionHandler) {
            DispatchQueue.main.async {
                completion((data: nil, urlResponse: nil, error: nil))
            }
        }

        func makeRequest(request: URLRequest, completion: @escaping DevCycle.CompletionHandler) {
            DispatchQueue.main.async {
                completion((data: nil, urlResponse: nil, error: nil))
            }
        }
    }

    private class MockFailedConnectionService: DevCycleServiceProtocol {
        public var userConfig: UserConfig?

        init(userConfig: UserConfig? = nil) {
            self.userConfig = userConfig
        }

        func getConfig(
            user: DevCycleUser,
            enableEdgeDB: Bool,
            extraParams: RequestParams?,
            completion: @escaping ConfigCompletionHandler
        ) {
            // Simulate a failed config fetch by returning an error
            let error = NSError(
                domain: "MockFailedConnectionService", code: 1,
                userInfo: [NSLocalizedDescriptionKey: "Failed to fetch config"])
            DispatchQueue.main.async {
                completion((nil, error))
            }
        }

        func publishEvents(
            events: [DevCycleEvent], user: DevCycleUser,
            completion: @escaping PublishEventsCompletionHandler
        ) {
            XCTAssert(true)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                completion((data: nil, urlResponse: nil, error: nil))
            }
        }

        func saveEntity(user: DevCycleUser, completion: @escaping SaveEntityCompletionHandler) {
            DispatchQueue.main.async {
                completion((data: nil, urlResponse: nil, error: nil))
            }
        }

        func makeRequest(request: URLRequest, completion: @escaping DevCycle.CompletionHandler) {
            DispatchQueue.main.async {
                completion((data: nil, urlResponse: nil, error: nil))
            }
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

    private class MockCacheServiceWithConfig: CacheServiceProtocol {
        private let userConfig: UserConfig

        init(userConfig: UserConfig) {
            self.userConfig = userConfig
        }

        func setAnonUserId(anonUserId: String) {}
        func getAnonUserId() -> String? { return nil }
        func clearAnonUserId() {}
        func saveConfig(user: DevCycleUser, configToSave: Data?) {}
        func getConfig(user: DevCycleUser) -> UserConfig? {
            return self.userConfig
        }
        func getOrCreateAnonUserId() -> String {
            return "mock-anon-id"
        }
        func migrateLegacyCache() {}
    }
}
