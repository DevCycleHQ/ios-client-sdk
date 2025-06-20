//
//  DVCVariableTests.swift
//  DevCycleTests
//
//  Copyright © 2021 Taplytics. All rights reserved.
//

import XCTest

@testable import DevCycle

class DVCVariableTests: XCTestCase {
    func testVariableCreatedFromParams() {
        let variable = DVCVariable(
            key: "key", value: nil, defaultValue: "default_value", eval: nil)
        XCTAssertNotNil(variable)
    }

    func testVariableUpdatesFromVariable() throws {
        let data = """
            {
                "_id": "variable_id",
                "key": "my_key",
                "type": "String",
                "value": "my_value"
            }
            """.data(using: .utf8)!
        let variableDict =
            try JSONSerialization.jsonObject(with: data, options: .fragmentsAllowed)
            as! [String: Any]
        let variableFromApi = try Variable(from: variableDict)
        let variable = DVCVariable(
            key: "my_key", value: nil, defaultValue: "my_default", eval: nil)
        XCTAssertNotNil(variable)

        variable.update(from: variableFromApi)
        XCTAssertNotNil(variable)
        XCTAssertEqual(variable.key, "my_key")
        XCTAssertEqual(variable.value, "my_value")
        XCTAssertEqual(variable.type, DVCVariableTypes.String)
        XCTAssertEqual(variable.defaultValue, "my_default")
        XCTAssertFalse(variable.isDefaulted)
        XCTAssertNil(variable.eval)
    }

    func testStringVariableCreatedFromVariable() throws {
        let data = """
            {
                "_id": "variable_id",
                "key": "my_key",
                "type": "String",
                "value": "my_value"
            }
            """.data(using: .utf8)!
        let variableDict =
            try JSONSerialization.jsonObject(with: data, options: .fragmentsAllowed)
            as! [String: Any]
        let variableFromApi = try Variable(from: variableDict)
        let variable = DVCVariable(from: variableFromApi, defaultValue: "my_default")
        XCTAssertNotNil(variable)
        XCTAssertEqual(variable.key, "my_key")
        XCTAssertEqual(variable.value, "my_value")
        XCTAssertEqual(variable.type, DVCVariableTypes.String)
        XCTAssertEqual(variable.defaultValue, "my_default")
        XCTAssertFalse(variable.isDefaulted)
        XCTAssertNil(variable.eval)
    }

    func testBoolVariableCreatedFromVariable() throws {
        let data = """
            {
                "_id": "variable_id",
                "key": "my_key",
                "type": "Boolean",
                "value": true
            }
            """.data(using: .utf8)!
        let variableDict =
            try JSONSerialization.jsonObject(with: data, options: .fragmentsAllowed)
            as! [String: Any]
        let variableFromApi = try Variable(from: variableDict)
        let variable = DVCVariable(from: variableFromApi, defaultValue: false)
        XCTAssertNotNil(variable)
        XCTAssertEqual(variable.key, "my_key")
        XCTAssertEqual(variable.value, true)
        XCTAssertEqual(variable.type, DVCVariableTypes.Boolean)
        XCTAssertEqual(variable.defaultValue, false)
        XCTAssertFalse(variable.isDefaulted)
        XCTAssertNil(variable.eval)
    }

    func testNumberVariableCreatedFromVariable() throws {
        let data = """
            {
                "_id": "variable_id",
                "key": "my_key",
                "type": "Number",
                "value": 2.3
            }
            """.data(using: .utf8)!
        let variableDict =
            try JSONSerialization.jsonObject(with: data, options: .fragmentsAllowed)
            as! [String: Any]
        let variableFromApi = try Variable(from: variableDict)
        let variable = DVCVariable(from: variableFromApi, defaultValue: 1.1)
        XCTAssertNotNil(variable)
        XCTAssertEqual(variable.key, "my_key")
        XCTAssertEqual(variable.value, 2.3)
        XCTAssertEqual(variable.type, DVCVariableTypes.Number)
        XCTAssertEqual(variable.defaultValue, 1.1)
        XCTAssertFalse(variable.isDefaulted)
        XCTAssertNil(variable.eval)
    }

    func testNumberDoubleVariableCreatedFromVariable() throws {
        let data = """
            {
                "_id": "variable_id",
                "key": "my_key",
                "type": "Number",
                "value": 2.3
            }
            """.data(using: .utf8)!
        let variableDict =
            try JSONSerialization.jsonObject(with: data, options: .fragmentsAllowed)
            as! [String: Any]
        let variableFromApi = try Variable(from: variableDict)
        let defaultDouble: Double = 1.1
        let variable = DVCVariable(from: variableFromApi, defaultValue: defaultDouble)
        XCTAssertEqual(variable.value, 2.3)
        XCTAssertEqual(variable.type, DVCVariableTypes.Number)
        XCTAssertEqual(variable.defaultValue, defaultDouble)
    }

    func testNumberNSNumberVariableCreatedFromVariable() throws {
        let data = """
            {
                "_id": "variable_id",
                "key": "my_key",
                "type": "Number",
                "value": 2.3
            }
            """.data(using: .utf8)!
        let variableDict =
            try JSONSerialization.jsonObject(with: data, options: .fragmentsAllowed)
            as! [String: Any]
        let variableFromApi = try Variable(from: variableDict)
        let defaultInt: NSNumber = 1
        let variable = DVCVariable(from: variableFromApi, defaultValue: defaultInt)
        XCTAssertEqual(variable.value, 2.3)
        XCTAssertEqual(variable.type, DVCVariableTypes.Number)
        XCTAssertEqual(variable.defaultValue, defaultInt)
    }

    func testNumberFloatVariableDefaultsFromVariable() throws {
        let data = """
            {
                "_id": "variable_id",
                "key": "my_key",
                "type": "Number",
                "value": 2.3
            }
            """.data(using: .utf8)!
        let variableDict =
            try JSONSerialization.jsonObject(with: data, options: .fragmentsAllowed)
            as! [String: Any]
        let variableFromApi = try Variable(from: variableDict)
        let defaultFloat: Float = 1.1
        let variable = DVCVariable(from: variableFromApi, defaultValue: defaultFloat)
        XCTAssertEqual(variable.value, defaultFloat)
        XCTAssertEqual(variable.type, nil)
        XCTAssertTrue(variable.isDefaulted)
    }

    func testNumberIntVariableDefaultsFromVariable() throws {
        let data = """
            {
                "_id": "variable_id",
                "key": "my_key",
                "type": "Number",
                "value": 2.3
            }
            """.data(using: .utf8)!
        let variableDict =
            try JSONSerialization.jsonObject(with: data, options: .fragmentsAllowed)
            as! [String: Any]
        let variableFromApi = try Variable(from: variableDict)
        let defaultInt: Int = 1
        let variable = DVCVariable(from: variableFromApi, defaultValue: defaultInt)
        XCTAssertEqual(variable.value, defaultInt)
        XCTAssertEqual(variable.type, nil)
        XCTAssertTrue(variable.isDefaulted)
    }

    func testJsonVariableCreatedFromVariable() throws {
        let data = """
            {
                "_id": "variable_id",
                "key": "my_key",
                "type": "JSON",
                "value": {
                    "key1": "value1",
                    "key2": {
                        "nestedKey1": "nestedKey2"
                    }
                }
            }
            """.data(using: .utf8)!
        let variableDict =
            try JSONSerialization.jsonObject(with: data, options: .fragmentsAllowed)
            as! [String: Any]
        let variableFromApi = try Variable(from: variableDict)
        let defaultValue: [String: Any] = ["key1": "value2"]
        let variable = DVCVariable(from: variableFromApi, defaultValue: defaultValue)
        XCTAssertNotNil(variable)
        XCTAssertEqual(variable.key, "my_key")
        XCTAssertNotNil(variable.value)
        XCTAssertEqual(variable.value["key1"] as! String, "value1")
        XCTAssertEqual(variable.type, DVCVariableTypes.JSON)
        XCTAssertEqual(variable.defaultValue["key1"] as! String, "value2")
        XCTAssertFalse(variable.isDefaulted)
        XCTAssertNil(variable.eval)

        let nsDicDefault: NSDictionary = ["key1": "val"]
        let variable2 = DVCVariable(from: variableFromApi, defaultValue: nsDicDefault)
        XCTAssertEqual(variable2.value["key1"] as! String, "value1")
        XCTAssertEqual(variable2.type, DVCVariableTypes.JSON)
        XCTAssertEqual(variable2.defaultValue["key1"] as! String, "val")
    }

    func testReturnsDefaultValueIfValueDoesntMatchDefaultValue() throws {
        let data = """
            {
                "_id": "variable_id",
                "key": "my_key",
                "type": "String",
                "value": "my_value"
            }
            """.data(using: .utf8)!
        let variableDict =
            try JSONSerialization.jsonObject(with: data, options: .fragmentsAllowed)
            as! [String: Any]
        let variableFromApi = try Variable(from: variableDict)
        let variable = DVCVariable(from: variableFromApi, defaultValue: 4)
        XCTAssertEqual(variable.value, 4)
        XCTAssertTrue(variable.isDefaulted)
        XCTAssertEqual(variable.eval?.reason, "DEFAULT")
        XCTAssertEqual(variable.eval?.details, "Invalid Variable Type")
    }

    func testReturnsDefaultValueIfJSONObjectDoesntMatch() throws {
        let data = """
            {
                "_id": "variable_id",
                "key": "my_key",
                "type": "JSON",
                "value": {
                    "key1": "value1",
                    "key2": {
                        "nestedKey1": 610
                    }
                }
            }
            """.data(using: .utf8)!
        let variableDict =
            try JSONSerialization.jsonObject(with: data, options: .fragmentsAllowed)
            as! [String: Any]
        let variableFromApi = try Variable(from: variableDict)
        let defaultValue = ["key1": "value2"]
        let variable = DVCVariable(from: variableFromApi, defaultValue: defaultValue)
        XCTAssertNotNil(variable)
        XCTAssertEqual(variable.value, defaultValue)
        XCTAssertTrue(variable.isDefaulted)
        XCTAssertEqual(variable.eval?.reason, "DEFAULT")
        XCTAssertEqual(variable.eval?.details, "Variable Type Mismatch")
    }

    func testDefaultValueIfValueFromUpdateDoesntMatchDefaultValue() throws {
        let data = """
            {
                "_id": "variable_id",
                "key": "my_key",
                "type": "String",
                "value": "my_value"
            }
            """.data(using: .utf8)!
        let variableDict =
            try JSONSerialization.jsonObject(with: data, options: .fragmentsAllowed)
            as! [String: Any]
        let variableFromApi = try Variable(from: variableDict)
        let variable = DVCVariable(key: "my_key", value: nil, defaultValue: 4, eval: nil)
        variable.update(from: variableFromApi)
        XCTAssertEqual(variable.value, 4)
        XCTAssertTrue(variable.isDefaulted)
        XCTAssertEqual(variable.eval?.reason, "DEFAULT")
        XCTAssertEqual(variable.eval?.details, "Variable Type Mismatch")
    }

    func testOnUpdateGetsCalledIfValueChanges() throws {
        let data = """
            {
                "_id": "variable_id",
                "key": "my_key",
                "type": "String",
                "value": "my_value"
            }
            """.data(using: .utf8)!
        let variableDict =
            try JSONSerialization.jsonObject(with: data, options: .fragmentsAllowed)
            as! [String: Any]
        let variableFromApi = try Variable(from: variableDict)
        let variable = DVCVariable(
            key: "my_key", value: nil, defaultValue: "new_value", eval: nil)
        let exp = expectation(description: "On Update Called With New Value")
        variable.onUpdate { value in
            exp.fulfill()
        }
        variable.update(from: variableFromApi)
        waitForExpectations(timeout: 1)
    }

    func testOnUpdateDoesntGetCalledIfValueTheSame() throws {
        let data = """
            {
                "_id": "variable_id",
                "key": "my_key",
                "type": "String",
                "value": "my_value"
            }
            """.data(using: .utf8)!
        let variableDict =
            try JSONSerialization.jsonObject(with: data, options: .fragmentsAllowed)
            as! [String: Any]
        let variableFromApi = try Variable(from: variableDict)
        let variable = DVCVariable(
            key: "my_key", value: nil, defaultValue: "my_value", eval: nil)
        var onUpdateCalled = false
        let exp = expectation(description: "On Update Not Called")
        variable.onUpdate { value in
            onUpdateCalled = true
        }
        variable.update(from: variableFromApi)
        let result = XCTWaiter.wait(for: [exp], timeout: 1.0)
        if result == XCTWaiter.Result.timedOut {
            XCTAssertFalse(onUpdateCalled)
        }
    }
    
    func testVariableEvalReason() throws {
        let data = """
            {
                "_id": "variable_id",
                "key": "my_key",
                "type": "String",
                "value": "my_value",
                "eval": {
                    "reason": "TARGETING_MATCH",
                    "details": "Audience Match -> app AND appVersion",
                    "target_id": "test_target_id",
                }
            }
            """.data(using: .utf8)!
        let variableDict =
            try JSONSerialization.jsonObject(with: data, options: .fragmentsAllowed)
            as! [String: Any]
        let variableFromApi = try Variable(from: variableDict)
        let variable = DVCVariable(
            key: "my_key", value: nil, defaultValue: "my_default", eval: nil)
        XCTAssertNotNil(variable)

        variable.update(from: variableFromApi)
        XCTAssertNotNil(variable)
        XCTAssertEqual(variable.key, "my_key")
        XCTAssertEqual(variable.value, "my_value")
        XCTAssertEqual(variable.type, DVCVariableTypes.String)
        XCTAssertEqual(variable.defaultValue, "my_default")
        XCTAssertFalse(variable.isDefaulted)
        XCTAssertNotNil(variable.eval)
        XCTAssertEqual(variable.eval?.reason, "TARGETING_MATCH")
        XCTAssertEqual(variable.eval?.details, "Audience Match -> app AND appVersion")
        XCTAssertEqual(variable.eval?.targetId, "test_target_id")
    }
}
