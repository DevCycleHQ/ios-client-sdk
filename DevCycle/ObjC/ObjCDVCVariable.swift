//
//  ObjCDVCVariable.swift
//  DevCycle
//
//  Copyright © 2021 Taplytics. All rights reserved.
//

import Foundation

enum ObjCVariableError: Error {
    case VariableValueDoesntMatchDefaultValueType(String)
}

@objc(DVCVariable)
public class ObjCDVCVariable: NSObject {
    @objc public var key: String
    @objc public var type: String?
    @objc public var evalReason: String?
    @objc public var isDefaulted: Bool
    
    @objc public var value: Any
    @objc public var defaultValue: Any
    
    
    init<T>(dvcVariable: DVCVariable<T>) {
        self.key = dvcVariable.key
        self.type = dvcVariable.type
        self.evalReason = dvcVariable.evalReason
        self.isDefaulted = dvcVariable.isDefaulted
        self.value = dvcVariable.value
        self.defaultValue = dvcVariable.defaultValue
        
        //TODO handle updates
    }
    
//    @objc public init (key: String, type: String?, evalReason: String?, value: Any?, defaultValue: Any) throws {
//        if (value != nil && Swift.type(of: defaultValue) != Swift.type(of: value!)) {
//            throw ObjCVariableError.VariableValueDoesntMatchDefaultValueType("For variable: \(key)")
//        }
//        self.key = key
//        self.type = type
//        self.evalReason = evalReason
//        self.defaultValue = defaultValue
//        self.value = value ?? defaultValue
//        self.isDefaulted = value == nil
//    }
    
//    func update(from variable: Variable) throws {
//        guard Swift.type(of: self.defaultValue) != Swift.type(of: variable.value) else {
//            Log.error("Variable value of type \(Swift.type(of: variable.value)) doesn't match default value type: \(self.defaultValue)", tags: ["variable", "objc"])
//            return
//        }
//        self.value = variable.value
//        self.type = variable.type
//        self.evalReason = variable.evalReason
//        self.isDefaulted = false
//    }
}
