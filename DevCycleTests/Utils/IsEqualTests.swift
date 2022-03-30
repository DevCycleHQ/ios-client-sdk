//
//  IsEqualTests.swift
//  DevCycleTests
//
//  Copyright © 2022 Taplytics. All rights reserved.
//

import XCTest
import DevCycle

class IsEqualTests: XCTestCase {

    func testDictionaryIsEqual() {
        let dictionary = [
            "key1": "value",
            "key2": 3,
            "key3": false,
            "key4": ["nestedKey": "value2"],
        ] as [String : Any]
        XCTAssert(DevCycle.isEqual(dictionary, dictionary))
    }
    
    func testDictionaryIsNotEqual() {
        let dictionary1 = [
            "key1": "value",
            "key2": 3,
            "key3": false,
            "key4": ["nestedKey": "different_value"],
        ] as [String : Any]
        let dictionary2 = [
            "key1": "value",
            "key2": 4,
            "key3": true,
            "key4": ["nestedKey": "different_value"],
        ] as [String : Any]
        XCTAssertFalse(DevCycle.isEqual(dictionary1, dictionary2))
    }
    
    func testDoubleIsEqual() {
        let double = Double(4.5)
        XCTAssert(DevCycle.isEqual(double, double))
    }
    
    func testDoubleIsNotEqual() {
        let double = Double(4.5)
        XCTAssertFalse(DevCycle.isEqual(double, Double(4.6)))
    }
    
    func testFloatIsEqual() {
        let float = Float(4.5)
        XCTAssert(DevCycle.isEqual(float, float))
    }
    
    func testFloatIsNotEqual() {
        let float = Float(4.5)
        XCTAssertFalse(DevCycle.isEqual(float, Float(4.6)))
    }
    
    func testIntIsEqual() {
        let intVar = Int(4)
        XCTAssert(DevCycle.isEqual(intVar, intVar))
    }
    
    func testIntIsNotEqual() {
        let intVar = Int(4)
        XCTAssertFalse(DevCycle.isEqual(intVar, Int(5)))
    }
    
    func testStringIsEqual() {
        let string = "my_string"
        XCTAssert(DevCycle.isEqual(string, string))
    }
    
    func testStringIsNotEqual() {
        let string = "my_string"
        XCTAssertFalse(DevCycle.isEqual(string, "my_other_string"))
    }
    
    func testBoolIsEqual() {
        XCTAssert(DevCycle.isEqual(true, true))
    }
    
    func testBoolIsNotEqual() {
        XCTAssertFalse(DevCycle.isEqual(true, false))
    }
}
