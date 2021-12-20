//
//  DVCVariable.swift
//  DevCycle
//
//  Copyright © 2021 Taplytics. All rights reserved.
//

import Foundation

public typealias VariableValueHandler<T> = (T) -> Void

public enum VariableError: Error {
    case DefaultValueAndValueTypeMismatch
}

public class DVCVariable<T> {
    public var key: String
    public var type: String
    public var handler: VariableValueHandler<T>?
    public var evalReason: String?
    public var isDefaulted: Bool
    
    public var value: T
    public var defaultValue: T
    
    init (key: String, type: String, value: T?, defaultValue: T, evalReason: String?) {
        self.key = key
        self.type = type
        self.value = value ?? defaultValue
        self.defaultValue = defaultValue
        self.isDefaulted = value == nil
        self.evalReason = evalReason
    }
    
    init (from variable: Variable, defaultValue: T) throws {
        guard let value = variable.value as? T else {
            throw VariableError.DefaultValueAndValueTypeMismatch
        }
        self.key = variable.key
        self.value = value
        self.defaultValue = defaultValue
        self.type = variable.type
        self.isDefaulted = false
        self.evalReason = variable.evalReason
    }
    
    func update(from variable: Variable) throws {
        guard let value = variable.value as? T else {
            throw VariableError.DefaultValueAndValueTypeMismatch
        }
        self.value = value
        self.type = variable.type
        self.evalReason = variable.evalReason
        self.isDefaulted = false
    }
    
    public func onUpdate(handler: @escaping VariableValueHandler<T>) -> DVCVariable {
        self.handler = handler
        return self
    }
}
