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
        let variable = DVCVariable(key: "key", type: "String", value: nil, defaultValue: "default_value", evalReason: nil)
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
        let variableDict = try JSONSerialization.jsonObject(with: data, options: .fragmentsAllowed) as! [String: Any]
        let variableFromApi = try Variable(from: variableDict)
        let variable = DVCVariable(key: "my_key", type: "String", value: nil, defaultValue: "my_default", evalReason: nil)
        XCTAssertNotNil(variable)
        
        try variable.update(from: variableFromApi)
        XCTAssertNotNil(variable)
        XCTAssertEqual(variable.key, "my_key")
        XCTAssertEqual(variable.value, "my_value")
        XCTAssertEqual(variable.type, "String")
        XCTAssertEqual(variable.defaultValue, "my_default")
        XCTAssertFalse(variable.isDefaulted)
        XCTAssertNil(variable.evalReason)
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
        let variableDict = try JSONSerialization.jsonObject(with: data, options: .fragmentsAllowed) as! [String: Any]
        let variableFromApi = try Variable(from: variableDict)
        let variable = try DVCVariable(from: variableFromApi, defaultValue: "my_default")
        XCTAssertNotNil(variable)
        XCTAssertEqual(variable.key, "my_key")
        XCTAssertEqual(variable.value, "my_value")
        XCTAssertEqual(variable.type, "String")
        XCTAssertEqual(variable.defaultValue, "my_default")
        XCTAssertFalse(variable.isDefaulted)
        XCTAssertNil(variable.evalReason)
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
        let variableDict = try JSONSerialization.jsonObject(with: data, options: .fragmentsAllowed) as! [String: Any]
        let variableFromApi = try Variable(from: variableDict)
        let variable = try DVCVariable(from: variableFromApi, defaultValue: false)
        XCTAssertNotNil(variable)
        XCTAssertEqual(variable.key, "my_key")
        XCTAssertEqual(variable.value, true)
        XCTAssertEqual(variable.type, "Boolean")
        XCTAssertEqual(variable.defaultValue, false)
        XCTAssertFalse(variable.isDefaulted)
        XCTAssertNil(variable.evalReason)
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
        let variableDict = try JSONSerialization.jsonObject(with: data, options: .fragmentsAllowed) as! [String: Any]
        let variableFromApi = try Variable(from: variableDict)
        let variable = try DVCVariable(from: variableFromApi, defaultValue: 1.1)
        XCTAssertNotNil(variable)
        XCTAssertEqual(variable.key, "my_key")
        XCTAssertEqual(variable.value, 2.3)
        XCTAssertEqual(variable.type, "Number")
        XCTAssertEqual(variable.defaultValue, 1.1)
        XCTAssertFalse(variable.isDefaulted)
        XCTAssertNil(variable.evalReason)
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
        let variableDict = try JSONSerialization.jsonObject(with: data, options: .fragmentsAllowed) as! [String: Any]
        let variableFromApi = try Variable(from: variableDict)
        let defaultValue = ["key1": "value2"]
        let variable = try DVCVariable(from: variableFromApi, defaultValue: defaultValue as [String:Any])
        XCTAssertNotNil(variable)
        XCTAssertEqual(variable.key, "my_key")
        XCTAssertNotNil(variable.value)
        XCTAssertEqual(variable.type, "JSON")
        XCTAssertEqual(variable.defaultValue["key1"] as! String, "value2")
        XCTAssertFalse(variable.isDefaulted)
        XCTAssertNil(variable.evalReason)
    }
    
    func testThrowsIfValueDoesntMatchDefaultValue() throws {
        let data = """
        {
            "_id": "variable_id",
            "key": "my_key",
            "type": "String",
            "value": "my_value"
        }
        """.data(using: .utf8)!
        let variableDict = try JSONSerialization.jsonObject(with: data, options: .fragmentsAllowed) as! [String: Any]
        let variableFromApi = try Variable(from: variableDict)
        XCTAssertThrowsError(try DVCVariable(from: variableFromApi, defaultValue: 4))
    }
    
    func testThrowsIfValueFromUpdateDoesntMatchDefaultValue() throws {
        let data = """
        {
            "_id": "variable_id",
            "key": "my_key",
            "type": "String",
            "value": "my_value"
        }
        """.data(using: .utf8)!
        let variableDict = try JSONSerialization.jsonObject(with: data, options: .fragmentsAllowed) as! [String: Any]
        let variableFromApi = try Variable(from: variableDict)
        let variable = DVCVariable(key: "my_key", type: "Number", value: nil, defaultValue: 4, evalReason: nil)
        XCTAssertThrowsError(try variable.update(from: variableFromApi))
    }

}
