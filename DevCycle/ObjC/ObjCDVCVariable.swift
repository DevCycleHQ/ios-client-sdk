//
//  ObjCDVCVariable.swift
//  DevCycle
//
//  Copyright © 2021 Taplytics. All rights reserved.
//

import Foundation

public typealias DVCVariableValueHandler = (Any) -> Void

@objc(DVCVariable)
public class ObjCDVCVariable: NSObject {
    @objc public var key: String
    @objc public var type: String?
    @objc public var evalReason: String?
    @objc public var isDefaulted: Bool
    @objc public var handler: DVCVariableValueHandler?
    
    @objc public var value: Any
    @objc public var defaultValue: Any
    private let dvcVariable: Any
    
    init<T>(_ dvcVariable: DVCVariable<T>) {
        self.dvcVariable = dvcVariable
        self.key = dvcVariable.key
        self.type = dvcVariable.type
        self.evalReason = dvcVariable.evalReason
        self.isDefaulted = dvcVariable.isDefaulted
        self.value = dvcVariable.value
        self.defaultValue = dvcVariable.defaultValue
        super.init()
        
        dvcVariable.onUpdate { [weak self] _ in
            if let weakSelf = self {
                weakSelf.setValues(dvcVariable: dvcVariable)
                weakSelf.handler?(weakSelf)
            }
        }
    }
    
    func setValues<T>(dvcVariable: DVCVariable<T>) {
        self.key = dvcVariable.key
        self.type = dvcVariable.type
        self.evalReason = dvcVariable.evalReason
        self.isDefaulted = dvcVariable.isDefaulted
        self.value = dvcVariable.value
        self.defaultValue = dvcVariable.defaultValue
    }
    
    @objc public func onUpdate(handler: @escaping DVCVariableValueHandler) -> ObjCDVCVariable {
        self.handler = handler
        return self
    }
}
