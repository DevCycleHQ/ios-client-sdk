//
//  ObjCDVCVariable.swift
//  DevCycle
//
//  Copyright © 2021 Taplytics. All rights reserved.
//

import Foundation

@objc(DVCVariable)
public class ObjCDVCVariable: NSObject {
    @objc public var key: String
    @objc public var type: String?
    @objc public var evalReason: String?
    
    @objc public var value: Any
    @objc public var defaultValue: Any
    
    init (key: String, type: String?, evalReason: String?, value: Any?, defaultValue: Any) {
        self.key = key
        self.type = type
        self.evalReason = evalReason
        self.defaultValue = defaultValue
        self.value = value != nil ? value! : defaultValue
    }
}
