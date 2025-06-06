//
//  UserConfigTests.swift
//  DevCycleTests
//
//

import XCTest

@testable import DevCycle

class UserConfigTests: XCTestCase {
    func testCreatesConfigFromData() throws {
        let data = getConfigData(name: "test_config")
        let dictionary =
            try JSONSerialization.jsonObject(with: data, options: .fragmentsAllowed)
            as! [String: Any]
        let config = try UserConfig(from: dictionary)
        XCTAssertNotNil(config)
        XCTAssertNotNil(config.project)
        XCTAssertNotNil(config.environment)
        XCTAssertNotNil(config.variables)
        XCTAssertNotNil(config.featureVariationMap)
        XCTAssertNotNil(config.features)
        XCTAssertNotNil(config.sse)
    }

    func testDoesntCreateConfigFromDataIfProjectOrEnvironmentMissing() throws {
        let data = """
            {
                "project": {},
                "environment": {},
                "features": {},
                "featureVariationMap": {},
                "knownVariableKeys": [],
                "variables": {}
            }

            """.data(using: .utf8)!
        let dictionary =
            try JSONSerialization.jsonObject(with: data, options: .fragmentsAllowed)
            as! [String: Any]
        let config = try? UserConfig(from: dictionary)
        XCTAssertNil(config)
    }

    func testCreatesConfigFromDataIfNoFeaturesOrVariables() throws {
        let data = """
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
                "variables": {}
            }

            """.data(using: .utf8)!
        let dictionary =
            try JSONSerialization.jsonObject(with: data, options: .fragmentsAllowed)
            as! [String: Any]
        let config = try UserConfig(from: dictionary)
        XCTAssertNotNil(config)
        XCTAssertNotNil(config.project)
        XCTAssertNotNil(config.environment)
        XCTAssertNotNil(config.variables)
        XCTAssertNotNil(config.featureVariationMap)
        XCTAssertNotNil(config.features)
    }

    func testConfigVariableBool() throws {
        let data = getConfigData(name: "test_config")
        let dictionary =
            try JSONSerialization.jsonObject(with: data, options: .fragmentsAllowed)
            as! [String: Any]
        let config = try UserConfig(from: dictionary)
        let variable = config.variables["bool-var"]
        XCTAssert(variable?.key == "bool-var")
        XCTAssertEqual(variable?.type, DVCVariableTypes.Boolean)
        XCTAssert((variable?.value as! Bool))
    }

    func testConfigVariableString() throws {
        let data = getConfigData(name: "test_config")
        let dictionary =
            try JSONSerialization.jsonObject(with: data, options: .fragmentsAllowed)
            as! [String: Any]
        let config = try UserConfig(from: dictionary)
        let variable = config.variables["string-var"]
        XCTAssert(variable?.key == "string-var")
        XCTAssertEqual(variable?.type, DVCVariableTypes.String)
        XCTAssert((variable?.value as! String) == "string1")
    }

    func testConfigVariableNumber() throws {
        let data = getConfigData(name: "test_config")
        let dictionary =
            try JSONSerialization.jsonObject(with: data, options: .fragmentsAllowed)
            as! [String: Any]
        let config = try UserConfig(from: dictionary)
        let variable = config.variables["num-var"]
        XCTAssert(variable?.key == "num-var")
        XCTAssertEqual(variable?.type, DVCVariableTypes.Number)
        XCTAssert((variable?.value as! Double) == 4)
    }

    func testConfigVariableJson() throws {
        let data = getConfigData(name: "test_config")
        let dictionary =
            try JSONSerialization.jsonObject(with: data, options: .fragmentsAllowed)
            as! [String: Any]
        let config = try UserConfig(from: dictionary)
        let variable = config.variables["json-var"]
        let json = (variable?.value as! [String: Any])
        let nestedJson = json["key2"]
        XCTAssert(variable?.key == "json-var")
        XCTAssertEqual(variable?.type, DVCVariableTypes.JSON)
        XCTAssertNotNil(json)
        XCTAssertNotNil(nestedJson)
    }
    
    
    func testSuccessfulConfigParsingWithNonStringValuesOnFeatures() throws {
        let data = getConfigData(name: "test_config_eval_reason")
        let dictionary = try JSONSerialization.jsonObject(with: data, options: .fragmentsAllowed) as! [String:Any]
        let config = try UserConfig(from: dictionary)
        let features = config.features
        XCTAssertNotNil(config)
        XCTAssertNotNil(features)
    }
}
