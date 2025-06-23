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
    
    func testSuccessfulConfigParsingWithManyUnusedProperties() throws {
        let data = """
            {
                "project": {
                    "_id": "id1",
                    "key": "default",
                    "settings": {
                        "unused": "data"
                    }
                },
                "environment": {
                    "_id": "id2",
                    "key": "development",
                    "metadata": {
                        "testing": "unused data"
                    }
                },
                "features": {
                    "new-feature": {
                        "_id": "id3",
                        "key": "new-feature",
                        "type": "release",
                        "_variation": "id4",
                        "variationKey": "id4-key",
                        "variationName": "id4 name",
                        "eval": {
                            "reason": "TARGETING_MATCH",
                            "details": "Platform AND App Version",
                            "target_id": "test_target_id"
                        },
                        "evalReason": "we don't do this anymore"
                    }
                },
                "featureVariationMap": {
                    "id3": "id4"
                },
                "knownVariableKeys": [],
                "variables": {
                    "bool-var": {
                        "_id": "id5",
                        "key": "bool-var",
                        "type": "Boolean",
                        "value": true,
                        "eval": {
                            "reason": "TARGETING_MATCH",
                            "details": "Platform AND App Version",
                            "target_id": "test_target_id"
                        }
                    },
                    "json-var": {
                        "_id": "id6",
                        "key": "json-var",
                        "type": "JSON",
                        "value": {
                            "key1": "value1",
                            "key2": {
                                "nestedKey1": "nestedValue1"
                            }
                        },
                        "eval": {
                            "reason": "TARGETING_MATCH",
                            "details": "Platform AND App Version",
                            "target_id": "test_target_id"
                        }
                    },
                    "string-var": {
                        "_id": "id7",
                        "key": "string-var",
                        "type": "String",
                        "value": "string1",
                        "eval": {
                            "reason": "TARGETING_MATCH",
                            "details": "Platform AND App Version",
                            "target_id": "test_target_id"
                        },
                        "evalReason": "we really don't do this anymore"
                    },
                    "num-var": {
                        "_id": "id8",
                        "key": "num-var",
                        "type": "Number",
                        "value": 4,
                        "eval": {
                            "reason": "TARGETING_MATCH",
                            "details": "Platform AND App Version",
                            "target_id": "test_target_id"
                        }
                    }
                },
                "sse": {
                    "url": "https://example.com",
                    "inactivityDelay": 5,
                    "questionable": {
                        "unused": ["values", "here"]
                    }
                },
                "welcome": "to the future",
                "the_answer": 42,
                "hitchhiker": false
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
        XCTAssertNotNil(config.sse)
    }
    
    func testConfigWithFeatureKeyAsNumber() throws {
        // Feature feature-1 has a Number `key` instead of a String
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
                "features": {
                    "feature-1": {
                        "_id": "id3",
                        "key": 1,
                        "type": "release",
                        "_variation": "id4",
                        "variationKey": "id4-key",
                        "variationName": "id4 name",
                    }
                },
                "featureVariationMap": {},
                "knownVariableKeys": [],
                "variables": {
                    "bool-var": {
                        "_id": "id5",
                        "key": "bool-var",
                        "type": "Boolean",
                        "value": true,
                        "eval": {
                            "reason": "TARGETING_MATCH",
                            "details": "Platform AND App Version",
                            "target_id": "test_target_id"
                        }
                    }
                },
                "sse": {
                    "url": "https://example.com",
                    "inactivityDelay": 5
                }
            }
            """.data(using: .utf8)!
        let dictionary =
            try JSONSerialization.jsonObject(with: data, options: .fragmentsAllowed)
            as! [String: Any]
        do {
            _ = try UserConfig(from: dictionary)
        } catch {
            let stringError = String(describing: UserConfigError.MissingProperty("String: key in Feature object"))
            XCTAssertEqual(String(describing: error), stringError)
        }
    }
    
    func testConfigWithVariableIdMissing() throws {
        // Variable bool-var is missing the `_id` property
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
                "features": {
                    "feature-1": {
                        "_id": "id3",
                        "key": "feature-1",
                        "type": "release",
                        "_variation": "id4",
                        "variationKey": "id4-key",
                        "variationName": "id4 name",
                    }
                },
                "featureVariationMap": {},
                "knownVariableKeys": [],
                "variables": {
                    "bool-var": {
                        "key": "bool-var",
                        "type": "Boolean",
                        "value": true,
                        "eval": {
                            "reason": "TARGETING_MATCH",
                            "details": "Platform AND App Version",
                            "target_id": "test_target_id"
                        }
                    }
                },
                "sse": {
                    "url": "https://example.com",
                    "inactivityDelay": 5
                }
            }
            """.data(using: .utf8)!
        let dictionary =
            try JSONSerialization.jsonObject(with: data, options: .fragmentsAllowed)
            as! [String: Any]
        do {
            _ = try UserConfig(from: dictionary)
        } catch {
            let stringError = String(describing: UserConfigError.MissingProperty("_id in Variable object"))
            XCTAssertEqual(String(describing: error), stringError)
        }
    }
}
