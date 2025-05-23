//
//  DVCVariable.swift
//  DevCycle
//
//  Copyright © 2021 Taplytics. All rights reserved.
//

import Foundation

public typealias VariableValueHandler<T> = (T) -> Void

public enum DVCVariableTypes: String {
    case String = "String"
    case Boolean = "Boolean"
    case Number = "Number"
    case JSON = "JSON"
}

let StringTypes = Set(["String", "NSString"])
let NumberTypes = Set(["NSNumber", "Double"])

enum DVCVariableTypeError: Error {
    case invalidType(String)
}

func DVCVariableTypeFrom(classString: String) throws -> DVCVariableTypes {
    if StringTypes.contains(classString) {
        return .String
    } else if classString == "Bool" {
        return .Boolean
    } else if NumberTypes.contains(classString) {
        return .Number
    } else if classString.contains("Dictionary") {
        return .JSON
    } else {
        throw DVCVariableTypeError.invalidType("Unkown DVCVariableType from class: \(classString)")
    }
}

public class DVCVariable<T> {
    public var key: String
    public var type: DVCVariableTypes?
    public var handler: VariableValueHandler<T>?
    public var evalReason: String?
    public var isDefaulted: Bool

    public var value: T
    public var defaultValue: T

    public init(key: String, value: T?, defaultValue: T, evalReason: String?) {
        self.key = key
        self.value = value ?? defaultValue
        self.defaultValue = defaultValue
        self.isDefaulted = value == nil
        self.evalReason = evalReason

        let classString = String(describing: T.self)
        do {
            self.type = try DVCVariableTypeFrom(classString: classString)
        } catch {
            Log.warn(
                "Variable \(key) is of unsupported type: \(classString). Use variables of type: "
                    + "String / Boolean / NSNumber / Int / NSDictionary")
            self.value = defaultValue
            self.isDefaulted = true
        }

        addNotificationObserver()
    }

    public init(from variable: Variable, defaultValue: T) {
        var defaulted = false
        self.key = variable.key
        self.defaultValue = defaultValue
        self.evalReason = variable.evalReason

        let classString = String(describing: T.self)
        do {
            self.type = try DVCVariableTypeFrom(classString: classString)
        } catch {
            Log.warn(
                "Variable \(variable.key) defaultValue is of unsupported type: \(classString). "
                    + "Use variables of type: String / Boolean / NSNumber / Double / NSDictionary / Dictionary"
            )
            self.value = defaultValue
            self.isDefaulted = true
            addNotificationObserver()
            return
        }

        if let value = variable.value as? T {
            self.value = value
        } else {
            Log.warn("Variable \(variable.key) does not match type of default value \(T.self))")
            self.value = defaultValue
            defaulted = true
        }

        self.isDefaulted = defaulted
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
        } else if !isEqual(self.value, self.defaultValue) {
            self.resetToDefault()
            self.handler?(value)
        } else if !self.isDefaulted {
            self.isDefaulted = true
        }
    }

    private func resetToDefault() {
        self.value = self.defaultValue
        self.isDefaulted = true
    }

    private func addNotificationObserver() {
        NotificationCenter.default.addObserver(
            self, selector: #selector(propertyChange(notification:)),
            name: Notification.Name(NotificationNames.NewUserConfig), object: nil)
    }

    public func onUpdate(handler: @escaping VariableValueHandler<T>) -> DVCVariable {
        self.handler = handler
        return self
    }
}
