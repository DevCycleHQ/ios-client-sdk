//
//  DVCVariable.swift
//  DevCycle
//
//  Copyright © 2021 Taplytics. All rights reserved.
//

import Foundation

public typealias VariableValueHandler<T> = (T) -> Void

open class DVCVariable<T> {
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
        addNotificationObserver()
    }
    
    init(from variable: Variable, defaultValue: T) {
        var defaulted = false
        if let value = variable.value as? T {
            self.value = value
        } else {
            Log.warn("Variable \(variable.key) does not match type of default value \(T.self))")
            self.value = defaultValue
            defaulted = true
        }
        
        self.key = variable.key
        self.defaultValue = defaultValue
        self.type = variable.type
        self.isDefaulted = defaulted
        self.evalReason = variable.evalReason
        addNotificationObserver()
    }
    
    func update(from variable: Variable) {
        self.type = variable.type
        self.evalReason = variable.evalReason
        
        if let value = variable.value as? T {
            let oldValue = self.value
            self.value = value
            self.isDefaulted = false
            if let handler = self.handler,
               !isEqual(oldValue, variable.value)
            {
                handler(value)
            }
        } else {
            Log.warn("Variable \(variable.key) does not match type of default value \(T.self))")
        }
    }
    
    @objc func propertyChange(notification: Notification) {
        guard let userConfig = notification.userInfo?["new-user-config"] as? UserConfig else {
            return
        }
        if let variableFromApi = userConfig.variables[key] {
            self.update(from: variableFromApi)
        } else if (!isEqual(self.value, self.defaultValue)) {
            self.resetToDefault()
            self.handler?(value)
        } else if (!self.isDefaulted) {
            self.isDefaulted = true
        }
    }
    
    private func resetToDefault() {
        self.value = self.defaultValue
        self.isDefaulted = true
    }
    
    private func addNotificationObserver() {
        NotificationCenter.default.addObserver(self, selector: #selector(propertyChange(notification:)), name: Notification.Name(NotificationNames.NewUserConfig), object: nil)
    }
    
    public func onUpdate(handler: @escaping VariableValueHandler<T>) -> DVCVariable {
        self.handler = handler
        return self
    }
}

