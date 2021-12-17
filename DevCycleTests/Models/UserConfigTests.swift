//
//  UserConfigTests.swift
//  DevCycleTests
//
//  Created by Jason Salaber on 2021-12-14.
//

import XCTest
@testable import DevCycle;

class UserConfigTests: XCTestCase {
    func testCreatesConfigFromData() throws {
        let data = getConfigData(name: "test_config")
        let config = try JSONDecoder().decode(UserConfig.self, from: data)
        XCTAssertNotNil(config)
        XCTAssertNotNil(config.project)
        XCTAssertNotNil(config.environment)
        XCTAssertNotNil(config.variables)
        XCTAssertNotNil(config.featureVariationMap)
        XCTAssertNotNil(config.features)
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
        let config = try? JSONDecoder().decode(UserConfig.self, from: data)
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
        let config = try JSONDecoder().decode(UserConfig.self, from: data)
        XCTAssertNotNil(config)
        XCTAssertNotNil(config.project)
        XCTAssertNotNil(config.environment)
        XCTAssertNotNil(config.variables)
        XCTAssertNotNil(config.featureVariationMap)
        XCTAssertNotNil(config.features)
    }
    
    func testConfigVariableBool() throws {
        let data = getConfigData(name: "test_config")
        let config = try JSONDecoder().decode(UserConfig.self, from: data)
        let variable = config.variables["boolVar"]
        XCTAssert(variable?.key == "boolVar")
        XCTAssert(variable?.type == "Boolean")
        XCTAssert((variable?.value as! Bool))
    }
    
    func testConfigVariableString() throws {
        let data = getConfigData(name: "test_config")
        let config = try JSONDecoder().decode(UserConfig.self, from: data)
        let variable = config.variables["stringVar"]
        XCTAssert(variable?.key == "stringVar")
        XCTAssert(variable?.type == "String")
        XCTAssert((variable?.value as! String) == "string1")
    }
    
    func testConfigVariableNumber() throws {
        let data = getConfigData(name: "test_config")
        let config = try JSONDecoder().decode(UserConfig.self, from: data)
        let variable = config.variables["numVar"]
        XCTAssert(variable?.key == "numVar")
        XCTAssert(variable?.type == "Number")
        XCTAssert((variable?.value as! Double) == 4)
    }
    
    func testConfigVariableJson() throws {
        let data = getConfigData(name: "test_config")
        let config = try JSONDecoder().decode(UserConfig.self, from: data)
        let variable = config.variables["jsonVar"]
        let json = (variable?.value as! [String: Variable.JSONValue])
        let nestedJson = json["key2"]
        XCTAssert(variable?.key == "jsonVar")
        XCTAssert(variable?.type == "JSON")
        XCTAssertNotNil(json)
        XCTAssertNotNil(nestedJson)
    }
}

extension UserConfigTests {
    func getConfigData(name: String, withExtension: String = "json") -> Data {
        let bundle = Bundle(for: type(of: self))
        let fileUrl = bundle.url(forResource: name, withExtension: withExtension)
        let data = try! Data(contentsOf: fileUrl!)
        return data
    }
}
