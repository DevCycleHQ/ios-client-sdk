//
//  DevCycleProvider.swift
//  DevCycle-iOS-SDK
//
//

import Combine
import Foundation
import OpenFeature

public struct DevCycleProviderMetadata: ProviderMetadata {
    public var name: String? = "DevCycle Provider"
}

public final class DevCycleProvider: FeatureProvider {
    public func observe() -> AnyPublisher<OpenFeature.ProviderEvent?, Never> {
        // Return an empty publisher for now
        return Just(nil).eraseToAnyPublisher()
    }

    /**
        Provider hooks
     */
    public var hooks: [any Hook] = []

    /**
        Provider metadata
     */
    public var metadata: ProviderMetadata = DevCycleProviderMetadata()

    /**
        The DevCycle client instance
     */
    private(set) public var devcycleClient: DevCycleClient?

    /**
        The SDK key for DevCycle
     */
    private let sdkKey: String

    /**
        Options for DevCycle client
     */
    private let options: DevCycleOptions?

    /**
        Initializes a new instance of the DevCycleProvider
        - Parameters:
          - sdkKey: The DevCycle SDK key
          - options: Optional configuration options
     */
    public init(sdkKey: String, options: DevCycleOptions? = nil) {
        self.sdkKey = sdkKey
        self.options = options
    }

    /**
        Initializes the provider with the given context
        - Parameter initialContext: The initial evaluation context
     */
    public func initialize(initialContext: EvaluationContext?) async throws {
        if initialContext == nil {
            Log.warn(
                "DevCycleProvider initialized without context being set. "
                    + "It is highly recommended to set a context using `OpenFeature.setContext()` "
                    + "before setting an OpenFeature Provider using `OpenFeature.setProvider()` "
                    + "to avoid multiple API fetch calls."
            )
        }

        do {
            // If initialContext is nil, use anonymous user
            // Otherwise, convert context to user and throw any errors
            let user: DevCycleUser
            if let context = initialContext {
                user = try dvcUserFromContext(context)
            } else {
                user = try DevCycleUser.builder().userId("anonymous").build()
            }

            // Initialize client
            try await initializeDevCycleClient(with: user)
        } catch {
            throw OpenFeatureError.providerFatalError(
                message: "DevCycle client initialization error: \(error)")
        }
    }

    /**
        Creates and initializes the DevCycle client
        - Parameter user: The DevCycle user to initialize with
     */
    private func initializeDevCycleClient(with user: DevCycleUser) async throws {
        try await withCheckedThrowingContinuation {
            (continuation: CheckedContinuation<Void, Error>) in
            do {
                self.devcycleClient = try DevCycleClient.builder()
                    .sdkKey(sdkKey)
                    .user(user)
                    .options(options ?? DevCycleOptions())
                    .build { error in
                        if let error = error {
                            continuation.resume(
                                throwing: OpenFeatureError.providerFatalError(
                                    message: "DevCycle client initialization error: \(error)"))
                        } else {
                            continuation.resume()
                        }
                    }

                // TODO: add support for `ConfigurationChanged` and `Error` events to OF
            } catch {
                continuation.resume(throwing: error)
            }
        }
    }

    /**
        Called when the evaluation context changes
        - Parameters:
          - oldContext: The previous evaluation context
          - newContext: The new evaluation context
     */
    public func onContextSet(oldContext: EvaluationContext?, newContext: EvaluationContext)
        async throws
    {
        do {
            guard let client = self.devcycleClient else {
                Log.warn(
                    "Context set before DevCycleProvider was fully initialized. "
                        + "The context will be ignored until initialization completes."
                )
                return
            }

            let user = try dvcUserFromContext(newContext)

            try await withCheckedThrowingContinuation {
                (continuation: CheckedContinuation<Void, Error>) in
                do {
                    try client.identifyUser(user: user) { error, _ in
                        if let error = error {
                            Log.error("DevCycle identify user error: \(error)")
                            continuation.resume(throwing: error)
                        } else {
                            continuation.resume()
                        }
                    }
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        } catch {
            throw OpenFeatureError.generalError(message: "Error setting context: \(error)")
        }
    }

    /**
        Converts OpenFeature evaluation context to DevCycle user
        - Parameter context: The evaluation context
        - Returns: The DevCycle user
     */
    private func dvcUserFromContext(_ context: EvaluationContext) throws -> DevCycleUser {
        // Get the user ID from targeting key or user_id
        guard let userId = context.getTargetingKey() ?? context.asMap()["user_id"] as? String else {
            throw OpenFeatureError.targetingKeyMissingError
        }

        let userBuilder = DevCycleUser.builder()
            .userId(userId)

        // Extract attributes from context
        let attributes = context.asMap()

        // Create dictionaries to collect custom data
        var customData: [String: Any] = [:]
        var privateCustomData: [String: Any] = [:]

        for (key, value) in attributes {
            // Skip targetingKey and user_id as they're handled separately
            if key == "targetingKey" || key == "user_id" {
                continue
            }

            // Handle known DevCycleUser properties
            if key == "email" || key == "name" || key == "language" || key == "country" {
                if let stringValue = value as? String {
                    switch key {
                    case "email":
                        _ = userBuilder.email(stringValue)
                    case "name":
                        _ = userBuilder.name(stringValue)
                    case "language":
                        _ = userBuilder.language(stringValue)
                    case "country":
                        _ = userBuilder.country(stringValue)
                    default:
                        break
                    }
                } else {
                    Log.warn(
                        "Expected DevCycleUser property \"\(key)\" to be \"String\" but got \"\(type(of: value))\" in EvaluationContext. Ignoring value."
                    )
                }
            } else if key == "privateCustomData", let objectValue = value as? [String: Any] {
                privateCustomData = convertToDVCCustomData(objectValue)
            } else if key == "customData", let objectValue = value as? [String: Any] {
                let newData = convertToDVCCustomData(objectValue)
                for (dataKey, dataValue) in newData {
                    customData[dataKey] = dataValue
                }
            } else {
                // Add any other property to customData if it can be converted
                if let validValue = convertToValidCustomDataValue(value) {
                    customData[key] = validValue
                } else {
                    Log.warn(
                        "Unknown EvaluationContext property \"\(key)\" type. "
                            + "DevCycleUser only supports flat customData properties of type string / number / boolean / null"
                    )
                }
            }
        }

        // Add custom data to user
        if !customData.isEmpty {
            _ = userBuilder.customData(customData)
        }

        // Add private custom data to user
        if !privateCustomData.isEmpty {
            _ = userBuilder.privateCustomData(privateCustomData)
        }

        return try userBuilder.build()
    }

    /**
        Converts a dictionary to DevCycle CustomData
        - Parameter data: Dictionary to convert
        - Returns: Dictionary with valid custom data values
     */
    private func convertToDVCCustomData(_ data: [String: Any]) -> [String: Any] {
        var customData: [String: Any] = [:]

        for (key, value) in data {
            if let validValue = convertToValidCustomDataValue(value) {
                switch validValue {
                case .string(let stringValue):
                    customData[key] = stringValue
                case .number(let numberValue):
                    customData[key] = numberValue
                case .boolean(let boolValue):
                    customData[key] = boolValue
                }
            } else {
                Log.warn(
                    "Custom data property \"\(key)\" has unsupported type \(type(of: value)). "
                        + "DevCycleUser only supports flat customData properties of type "
                        + "string / number / boolean / null"
                )
            }
        }

        return customData
    }

    /**
        Creates a CustomDataValue from any value if possible
        - Parameter value: The value to convert
        - Returns: A valid CustomDataValue or nil if not convertible
     */
    private func convertToValidCustomDataValue(_ value: Any) -> CustomDataValue? {
        // Try to convert to valid CustomDataValue types
        if let stringValue = value as? String {
            return CustomDataValue.string(stringValue)
        } else if let boolValue = value as? Bool {
            return CustomDataValue.boolean(boolValue)
        } else if let numberValue = value as? NSNumber {
            if CFGetTypeID(numberValue) == CFBooleanGetTypeID() {
                return CustomDataValue.boolean(numberValue.boolValue)
            } else {
                return CustomDataValue.number(numberValue.doubleValue)
            }
        }

        return nil
    }

    /**
        Evaluates a boolean feature flag
        - Parameters:
          - key: The feature flag key
          - defaultValue: The default value to return if evaluation fails
          - context: The evaluation context
        - Returns: The provider evaluation with flag value and metadata
     */
    public func getBooleanEvaluation(
        key: String,
        defaultValue: Bool,
        context: EvaluationContext?
    ) throws -> ProviderEvaluation<Bool> {
        let variable = devcycleClient?.variable(key: key, defaultValue: defaultValue)

        return ProviderEvaluation(
            value: variable?.value ?? defaultValue,
            reason: variable?.isDefaulted == true
                ? Reason.defaultReason.rawValue : Reason.targetingMatch.rawValue
        )
    }

    /**
        Evaluates a string feature flag
        - Parameters:
          - key: The feature flag key
          - defaultValue: The default value to return if evaluation fails
          - context: The evaluation context
        - Returns: The provider evaluation with flag value and metadata
     */
    public func getStringEvaluation(
        key: String,
        defaultValue: String,
        context: EvaluationContext?
    ) throws -> ProviderEvaluation<String> {
        let variable = devcycleClient?.variable(key: key, defaultValue: defaultValue)

        return ProviderEvaluation(
            value: variable?.value ?? defaultValue,
            reason: variable?.isDefaulted == true
                ? Reason.defaultReason.rawValue : Reason.targetingMatch.rawValue
        )
    }

    /**
        Evaluates an integer feature flag
        - Parameters:
          - key: The feature flag key
          - defaultValue: The default value to return if evaluation fails
          - context: The evaluation context
        - Returns: The provider evaluation with flag value and metadata
     */
    public func getIntegerEvaluation(
        key: String,
        defaultValue: Int64,
        context: EvaluationContext?
    ) throws -> ProviderEvaluation<Int64> {
        // DevCycle doesn't have a dedicated integer type, so we need to use Double
        let doubleValue = Double(defaultValue)
        let variable = devcycleClient?.variable(key: key, defaultValue: doubleValue)

        return ProviderEvaluation(
            value: variable?.value != nil ? Int64(variable!.value) : defaultValue,
            reason: variable?.isDefaulted == true
                ? Reason.defaultReason.rawValue : Reason.targetingMatch.rawValue
        )
    }

    /**
        Evaluates a double feature flag
        - Parameters:
          - key: The feature flag key
          - defaultValue: The default value to return if evaluation fails
          - context: The evaluation context
        - Returns: The provider evaluation with flag value and metadata
     */
    public func getDoubleEvaluation(
        key: String,
        defaultValue: Double,
        context: EvaluationContext?
    ) throws -> ProviderEvaluation<Double> {
        let variable = devcycleClient?.variable(key: key, defaultValue: defaultValue)

        return ProviderEvaluation(
            value: variable?.value ?? defaultValue,
            reason: variable?.isDefaulted == true
                ? Reason.defaultReason.rawValue : Reason.targetingMatch.rawValue
        )
    }

    /**
        Evaluates an object feature flag
        - Parameters:
          - key: The feature flag key
          - defaultValue: The default value to return if evaluation fails
          - context: The evaluation context
        - Returns: The provider evaluation with flag value and metadata
     */
    public func getObjectEvaluation(
        key: String,
        defaultValue: Value,
        context: EvaluationContext?
    ) throws -> ProviderEvaluation<Value> {
        var dictionaryValue: [String: Any] = [:]

        // Convert Value to Dictionary if possible
        if case .structure(let attributes) = defaultValue {
            for (key, value) in attributes {
                switch value {
                case .string(let stringValue):
                    dictionaryValue[key] = stringValue
                case .boolean(let boolValue):
                    dictionaryValue[key] = boolValue
                case let .double(doubleValue):
                    dictionaryValue[key] = doubleValue
                case let .integer(intValue):
                    dictionaryValue[key] = intValue
                case .structure(let structValue):
                    dictionaryValue[key] = structValue
                default:
                    // Skip unsupported types
                    break
                }
            }
        }

        let variable = devcycleClient?.variable(key: key, defaultValue: dictionaryValue)

        return ProviderEvaluation(
            value: convertDictionaryToValue(variable?.value ?? [:]),
            reason: variable?.isDefaulted == true
                ? Reason.defaultReason.rawValue : Reason.targetingMatch.rawValue
        )
    }

    /**
        Converts a Dictionary to OpenFeature Value
        - Parameter dictionary: The dictionary to convert
        - Returns: The converted Value
     */
    private func convertDictionaryToValue(_ dictionary: [String: Any]) -> Value {
        var attributes: [String: Value] = [:]

        for (key, value) in dictionary {
            if let stringValue = value as? String {
                attributes[key] = .string(stringValue)
            } else if let boolValue = value as? Bool {
                attributes[key] = .boolean(boolValue)
            } else if let numberValue = value as? Double {
                attributes[key] = .double(numberValue)  // Use .double for numeric values
            } else if let numberValue = value as? Int {
                attributes[key] = .double(Double(numberValue))  // Convert Int to Double and use .double
            } else if let nestedDict = value as? [String: Any] {
                if let structValue = convertDictionaryToValue(nestedDict).asStructure() {
                    attributes[key] = .structure(structValue)
                }
            } else if value is [Any] {
                // Log a warning instead of trying to convert arrays
                Log.warn(
                    "Arrays are not directly supported in OpenFeature Value. Skipping array value for key '\(key)'."
                )
            }
        }

        return .structure(attributes)
    }
}
