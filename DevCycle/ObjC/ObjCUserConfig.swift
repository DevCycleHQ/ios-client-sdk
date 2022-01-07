//
//  ObjCUserConfig.swift
//  DevCycle
//
//  Copyright © 2022 Taplytics. All rights reserved.
//

import Foundation

@objc(Feature)
public class ObjCFeature: NSObject {
    private(set) var _id: String
    private(set) var _variation: String
    private(set) var key: String
    private(set) var type: String
    
    @objc init(id: String,
                  variation: String,
                  key: String,
                  type: String) {
        self._id = id
        self._variation = variation
        self.key = key
        self.type = type
    }
    
    static func create(from feature: Feature) -> ObjCFeature {
        return ObjCFeature(
            id: feature._id,
            variation: feature._variation,
            key: feature.key,
            type: feature.type
        )
    }
    
    override public var description: String {
        return "Feature(key:\(self.key), type: \(self.type), _variation: \(self._variation), _id: \(self._id))"
    }
}


@objc(Variable)
public class ObjCVariable: NSObject {
    private(set) var _id: String
    private(set) var key: String
    private(set) var type: String
    private(set) var value: Any
    private(set) var evalReason: String?
    
    @objc init(id: String,
                  key: String,
                  type: String,
                  value: Any,
                  evalReason: String?) {
        self._id = id
        self.key = key
        self.type = type
        self.value = value
        self.evalReason = evalReason
    }
    
    static func create(from variable: Variable) -> ObjCVariable {
        return ObjCVariable(
            id: variable._id,
            key: variable.key,
            type: variable.type,
            value: variable.value,
            evalReason: variable.evalReason
        )
    }
    
    override public var description: String {
        return "Variable(key:\(self.key), type: \(self.type), value: \(self.value), _id: \(self._id), evalReason: \(self.evalReason ?? "None"))"
    }
}
