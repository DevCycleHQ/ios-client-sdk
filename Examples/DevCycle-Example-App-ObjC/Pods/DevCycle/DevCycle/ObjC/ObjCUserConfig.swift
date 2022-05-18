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
    
    init(_ feature: Feature) {
        self._id = feature._id
        self._variation = feature._variation
        self.key = feature.key
        self.type = feature.type
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
    
    init(_ variable: Variable) {
        self._id = variable._id
        self.key = variable.key
        self.type = variable.type
        self.value = variable.value
        self.evalReason = variable.evalReason
    }
    
    override public var description: String {
        return "Variable(key:\(self.key), type: \(self.type), value: \(self.value), _id: \(self._id), evalReason: \(self.evalReason ?? "None"))"
    }
}
