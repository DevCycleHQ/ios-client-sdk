//
//  DVCVariable.swift
//  DevCycle
//
//  Copyright © 2021 Taplytics. All rights reserved.
//

import Foundation

public typealias VariableValueHandler<T> = (T) -> Void

public class DVCVariable<T> {
    public var key: String
    public var type: String
    public var handler: VariableValueHandler<T>?
    public var evalReason: String?
    public var isDefaulted: Bool
    
    public var value: T
    public var defaultValue: T
    
    init(key: String, type: String, value: T?, defaultValue: T, evalReason: String?) {
        self.key = key
        self.type = type
        self.value = value ?? defaultValue
        self.defaultValue = defaultValue
        self.isDefaulted = value == nil
        self.evalReason = evalReason
    }
    
    init(from variable: Variable, defaultValue: T) {
        if let value = variable.value as? T {
            self.value = value
        } else {
            Log.warn("Variable \(variable.key) does not match type of default value \(T.self))")
            self.value = defaultValue
        }
        
        self.key = variable.key
        self.defaultValue = defaultValue
        self.type = variable.type
        self.isDefaulted = false
        self.evalReason = variable.evalReason
    }
    
    func update(from variable: Variable) {
        if let value = variable.value as? T {
            self.value = value
        } else {
            Log.warn("Variable \(variable.key) does not match type of default value \(T.self))")
        }
        self.type = variable.type
        self.evalReason = variable.evalReason
        self.isDefaulted = false
        
        if let handler = self.handler {
            handler(self.value)
        }
    }
    
    public func onUpdate(handler: @escaping VariableValueHandler<T>) -> DVCVariable {
        self.handler = handler
        return self
    }
}
