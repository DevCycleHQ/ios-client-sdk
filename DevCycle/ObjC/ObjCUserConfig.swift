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
    private(set) var variationKey: String
    private(set) var variationName: String
    private(set) var eval: EvalReason?
    
    init(_ feature: Feature) {
        self._id = feature._id
        self._variation = feature._variation
        self.key = feature.key
        self.type = feature.type
        self.variationKey = feature.variationKey
        self.variationName = feature.variationName
        self.eval = feature.eval
    }
    
    override public var description: String {
        return "Feature(key:\(self.key), type: \(self.type), _variation: \(self._variation), _id: \(self._id), variationKey: \(self.variationKey), variationName: \(self.variationName), eval: \(String(describing: self.eval)))"
    }
}


@objc(Variable)
public class ObjCVariable: NSObject {
    private(set) var _id: String
    private(set) var key: String
    private(set) var type: String
    private(set) var value: Any
    private(set) var eval: EvalReason?
    
    init(_ variable: Variable) {
        self._id = variable._id
        self.key = variable.key
        self.type = variable.type.rawValue
        self.value = variable.value
        self.eval = variable.eval
    }
    
    override public var description: String {
        return "Variable(key:\(self.key), type: \(self.type), value: \(self.value), _id: \(self._id), eval: \(String(describing: self.eval)))"
    }
}


@objc(EvalReason)
public class ObjCEvalReason: NSObject {
    @objc public private(set) var reason: String
    @objc public private(set) var details: String?
    @objc public private(set) var targetId: String?

    init?(_ evalReason: EvalReason?) {
        guard let eval = evalReason else {
            return nil
        }
         
        self.reason = eval.reason
        self.details = eval.details
        self.targetId = eval.targetId
    }

    override public var description: String {
        return "EvalReason(reason: \(self.reason), details: \(String(describing: self.details)), targetId: \(String(describing: self.targetId)))"
    }
}
