import Combine
import DevCycle
import OpenFeature
import XCTest

@testable import DevCycleOpenFeatureProvider

final class DevCycleProviderTests: XCTestCase {

    private var sdkKey: String!
    private var provider: DevCycleProvider!
    private var cancellables: Set<AnyCancellable>!

    override func setUp() async throws {
        sdkKey = "test-sdk-key"
        provider = DevCycleProvider(sdkKey: sdkKey)
        cancellables = []
    }

    override func tearDown() async throws {
        provider = nil
        cancellables = nil
    }

    // MARK: - Initialization Tests

    func testProviderInitialization() {
        XCTAssertEqual(provider.metadata.name, "DevCycle Provider")
        XCTAssertTrue(provider.hooks.isEmpty)
        XCTAssertNil(provider.devcycleClient)
    }

    func testProviderWithOptions() {
        let options = DevCycleOptions.builder().logLevel(.debug).build()

        let providerWithOptions: DevCycleProvider = DevCycleProvider(
            sdkKey: sdkKey, options: options)
        XCTAssertEqual(providerWithOptions.metadata.name, "DevCycle Provider")
        XCTAssertNil(providerWithOptions.devcycleClient)
    }

    // MARK: - Provider Setup Tests

    func testInitializeWithContext() async throws {
        // Skip actual initialization since we don't want to make real API calls in unit tests
        // This is a unit test for the provider's behavior, not for the actual API calls

        // Create a context with targeting key and attributes
        let _ = MutableContext(
            targetingKey: "test-user",
            structure: MutableStructure(attributes: [
                "email": .string("test@example.com"),
                "isPremium": .boolean(true),
                "loginCount": .double(5.0),
            ])
        )

        // We should be able to create a provider with this context
        // We won't actually initialize since it would make real API calls
        let testProvider = DevCycleProvider(sdkKey: sdkKey)
        XCTAssertNotNil(testProvider)
    }

    // MARK: - Event Observation Tests

    func testObserve() {
        let publisher = provider.observe()

        let expectation = XCTestExpectation(description: "Should receive nil event")

        publisher.sink { event in
            XCTAssertNil(event)
            expectation.fulfill()
        }.store(in: &cancellables)

        wait(for: [expectation], timeout: 1.0)
    }

    // MARK: - Flag Evaluation Tests

    func testFlagEvaluationDefaultValues() throws {
        // Since we don't have initialized provider with real variables,
        // we should get default values for all flag evaluations

        // Boolean evaluation
        let boolResult = try provider.getBooleanEvaluation(
            key: "test-bool", defaultValue: true, context: nil as EvaluationContext?)
        XCTAssertEqual(boolResult.value, true)
        XCTAssertEqual(boolResult.reason, Reason.defaultReason.rawValue)

        // String evaluation
        let stringResult = try provider.getStringEvaluation(
            key: "test-string", defaultValue: "default-value", context: nil as EvaluationContext?)
        XCTAssertEqual(stringResult.value, "default-value")
        XCTAssertEqual(stringResult.reason, Reason.defaultReason.rawValue)

        // Number evaluation
        let numberResult = try provider.getDoubleEvaluation(
            key: "test-number", defaultValue: 42.0, context: nil as EvaluationContext?)
        XCTAssertEqual(numberResult.value, 42.0)
        XCTAssertEqual(numberResult.reason, Reason.defaultReason.rawValue)

        // Integer evaluation
        let integerResult = try provider.getIntegerEvaluation(
            key: "test-integer", defaultValue: 42, context: nil as EvaluationContext?)
        XCTAssertEqual(integerResult.value, 42)
        XCTAssertEqual(integerResult.reason, Reason.defaultReason.rawValue)
    }

    // MARK: - Object Evaluation Tests

    func testObjectEvaluation() throws {
        // Test object evaluation with a complex structure
        let defaultValue = Value.structure([
            "name": .string("John"),
            "age": .double(30),
            "isActive": .boolean(true),
            "nestedObject": .structure([
                "property": .string("value")
            ]),
        ])

        let result = try provider.getObjectEvaluation(
            key: "test-object", defaultValue: defaultValue, context: nil as EvaluationContext?)

        XCTAssertEqual(result.reason, Reason.defaultReason.rawValue)

        if case .structure(let attributes) = result.value {
            XCTAssertEqual(attributes["name"], .string("John"))
            XCTAssertEqual(attributes["age"], .double(30))
            XCTAssertEqual(attributes["isActive"], .boolean(true))

            if case .structure(let nestedAttributes) = attributes["nestedObject"] {
                XCTAssertEqual(nestedAttributes["property"], .string("value"))
            } else {
                XCTFail("Expected nested structure value")
            }
        } else {
            XCTFail("Expected structure value")
        }
    }

    func testComplexObjectEvaluation() throws {
        // Test object evaluation with mixed types
        let defaultValue = Value.structure([
            "string": .string("text"),
            "integer": .integer(10),
            "double": .double(20.5),
            "boolean": .boolean(true),
        ])

        let result = try provider.getObjectEvaluation(
            key: "complex-object",
            defaultValue: defaultValue,
            context: nil as EvaluationContext?
        )

        XCTAssertEqual(result.reason, Reason.defaultReason.rawValue)

        if case .structure(let attributes) = result.value {
            XCTAssertEqual(attributes["string"], .string("text"))
            XCTAssertEqual(attributes["boolean"], .boolean(true))

            // Check that integer values are preserved in the result
            XCTAssertEqual(attributes["integer"], .integer(10))
            XCTAssertEqual(attributes["double"], .double(20.5))
        } else {
            XCTFail("Expected structure value")
        }
    }

    // MARK: - Dictionary to Value Conversion Tests

    func testConvertDictionaryToValueWithPrimitiveTypes() {
        // Test the internal method directly with primitive types
        let dictionary: [String: Any] = [
            "string": "hello world",
            "boolean": true,
            "integer": 123,
            "double": 45.67,
        ]

        let result = provider.convertDictionaryToValue(dictionary)

        // Validate the result
        if case .structure(let attributes) = result {
            XCTAssertEqual(attributes["string"], .string("hello world"))
            XCTAssertEqual(attributes["boolean"], .boolean(true))
            XCTAssertEqual(attributes["integer"], .double(123.0))  // Note: integers are converted to doubles
            XCTAssertEqual(attributes["double"], .double(45.67))
        } else {
            XCTFail("Expected structure value")
        }
    }

    func testConvertDictionaryToValueWithNestedStructure() {
        // Test the internal method with nested dictionaries
        let dictionary: [String: Any] = [
            "topLevel": true,
            "nestedDict": [
                "nestedString": "nested value",
                "nestedBool": false,
                "deeplyNested": [
                    "level3": "deeply nested value",
                    "number": 123.456,
                ],
            ],
        ]

        let result = provider.convertDictionaryToValue(dictionary)

        // Validate the result
        if case .structure(let attributes) = result {
            XCTAssertEqual(attributes["topLevel"], .boolean(true))

            // Check first level nesting
            if case .structure(let nestedAttrs) = attributes["nestedDict"] {
                XCTAssertEqual(nestedAttrs["nestedString"], .string("nested value"))
                XCTAssertEqual(nestedAttrs["nestedBool"], .boolean(false))

                // Check second level nesting
                if case .structure(let deeplyNested) = nestedAttrs["deeplyNested"] {
                    XCTAssertEqual(deeplyNested["level3"], .string("deeply nested value"))
                    XCTAssertEqual(deeplyNested["number"], .double(123.456))
                } else {
                    XCTFail("Expected deeply nested structure")
                }
            } else {
                XCTFail("Expected nested structure")
            }
        } else {
            XCTFail("Expected structure value")
        }
    }

    func testConvertDictionaryToValueWithArrays() {
        // Test how the method handles arrays (which aren't directly supported)
        let dictionary: [String: Any] = [
            "normalKey": "normal value",
            "arrayKey": ["item1", "item2", "item3"],
        ]

        let result = provider.convertDictionaryToValue(dictionary)

        // Only the normal key should be present, array should be skipped
        if case .structure(let attributes) = result {
            XCTAssertEqual(attributes["normalKey"], .string("normal value"))
            XCTAssertNil(attributes["arrayKey"], "Arrays should be skipped")
        } else {
            XCTFail("Expected structure value")
        }
    }

    func testConvertDictionaryToValueWithNilAndNSNull() {
        // Test how the method handles nil and NSNull values
        let dictionary: [String: Any] = [
            "normalKey": "normal value",
            "nullKey": NSNull(),
        ]

        let result = provider.convertDictionaryToValue(dictionary)

        // Only the normal key should be present
        if case .structure(let attributes) = result {
            XCTAssertEqual(attributes["normalKey"], .string("normal value"))
            // NSNull should be skipped as it's not a supported type
            XCTAssertNil(attributes["nullKey"])
        } else {
            XCTFail("Expected structure value")
        }
    }

    func testConvertDictionaryToValueWithEdgeCases() {
        // Test edge cases and special values
        let dictionary: [String: Any] = [
            "emptyString": "",
            "zero": 0,
            "negativeNumber": -99.99,
            "maxInt": Int.max,
            "emptyDict": [String: Any](),
        ]

        let result = provider.convertDictionaryToValue(dictionary)

        // Verify edge cases are handled correctly
        if case .structure(let attributes) = result {
            XCTAssertEqual(attributes["emptyString"], .string(""))
            XCTAssertEqual(attributes["zero"], .double(0))
            XCTAssertEqual(attributes["negativeNumber"], .double(-99.99))
            XCTAssertEqual(attributes["maxInt"], .double(Double(Int.max)))

            // Verify empty dictionary becomes empty structure
            if case .structure(let emptyStruct) = attributes["emptyDict"] {
                XCTAssertTrue(emptyStruct.isEmpty)
            } else {
                XCTFail("Expected empty structure")
            }
        } else {
            XCTFail("Expected structure value")
        }
    }

    // MARK: - User Context Conversion Tests

    func testDvcUserFromContext() throws {
        // Create a context with all supported user properties
        let context = MutableContext(
            targetingKey: "test-user-id",
            structure: MutableStructure(attributes: [
                "email": .string("test@example.com"),
                "name": .string("Test User"),
                "language": .string("en"),
                "country": .string("US"),
                "customData": .structure([
                    "plan": .string("premium"),
                    "visits": .double(10),
                ]),
                "privateCustomData": .structure([
                    "sensitive": .string("data")
                ]),
            ])
        )

        // Now we can actually call the method directly
        let user = try provider.dvcUserFromContext(context)

        // Verify all properties were set correctly
        XCTAssertEqual(user.userId, "test-user-id")
        XCTAssertEqual(user.email, "test@example.com")
        XCTAssertEqual(user.name, "Test User")
        XCTAssertEqual(user.language, "en")
        XCTAssertEqual(user.country, "US")

        // Verify custom data
        XCTAssertNotNil(user.customData)
        if let customData = user.customData?.data {
            if case .string(let value) = customData["plan"] {
                XCTAssertEqual(value, "premium")
            } else {
                XCTFail("Expected string value for 'plan'")
            }

            if case .number(let value) = customData["visits"] {
                XCTAssertEqual(value, 10)
            } else {
                XCTFail("Expected number value for 'visits'")
            }
        } else {
            XCTFail("Expected custom data")
        }

        // Verify private custom data
        XCTAssertNotNil(user.privateCustomData)
        if let privateData = user.privateCustomData?.data {
            if case .string(let value) = privateData["sensitive"] {
                XCTAssertEqual(value, "data")
            } else {
                XCTFail("Expected string value for 'sensitive'")
            }
        } else {
            XCTFail("Expected private custom data")
        }
    }

    func testDvcUserFromContextWithBasicInfo() throws {
        // Create a minimal context with just targeting key
        let context = MutableContext(targetingKey: "user-123")

        // Convert to DevCycleUser
        let user = try provider.dvcUserFromContext(context)

        // Verify basic user properties
        XCTAssertEqual(user.userId, "user-123")
        XCTAssertNil(user.email)
        XCTAssertNil(user.name)
        XCTAssertTrue(user.customData?.data.isEmpty ?? true)
        XCTAssertTrue(user.privateCustomData?.data.isEmpty ?? true)
    }

    func testDvcUserFromContextWithUserProperties() throws {
        // Create a context with all standard user properties
        let context = MutableContext(
            targetingKey: "user-456",
            structure: MutableStructure(attributes: [
                "email": .string("test@example.com"),
                "name": .string("Test User"),
                "language": .string("en-US"),
                "country": .string("US"),
            ])
        )

        // Convert to DevCycleUser
        let user = try provider.dvcUserFromContext(context)

        // Verify all properties were set correctly
        XCTAssertEqual(user.userId, "user-456")
        XCTAssertEqual(user.email, "test@example.com")
        XCTAssertEqual(user.name, "Test User")
        XCTAssertEqual(user.language, "en-US")
        XCTAssertEqual(user.country, "US")
    }

    func testDvcUserFromContextWithCustomAndPrivateData() throws {
        // Create a context with both custom data and private custom data
        let context = MutableContext(
            targetingKey: "user-combined",
            structure: MutableStructure(attributes: [
                "customData": .structure([
                    "stringValue": .string("string"),
                    "boolValue": .boolean(true),
                    "numberValue": .double(42.5),
                    "intValue": .integer(100),
                ]),
                "privateCustomData": .structure([
                    "sensitive": .string("sensitive-data"),
                    "privateFlag": .boolean(true),
                ]),
            ])
        )

        // Convert to DevCycleUser
        let user = try provider.dvcUserFromContext(context)

        // Verify user ID
        XCTAssertEqual(user.userId, "user-combined")

        // Verify custom data was set correctly
        XCTAssertNotNil(user.customData)
        if let customData = user.customData?.data {
            if case .string(let value) = customData["stringValue"] {
                XCTAssertEqual(value, "string")
            } else {
                XCTFail("Expected string value for 'stringValue'")
            }

            if case .boolean(let value) = customData["boolValue"] {
                XCTAssertEqual(value, true)
            } else {
                XCTFail("Expected boolean value for 'boolValue'")
            }

            if case .number(let value) = customData["numberValue"] {
                XCTAssertEqual(value, 42.5)
            } else {
                XCTFail("Expected number value for 'numberValue'")
            }

            if case .number(let value) = customData["intValue"] {
                XCTAssertEqual(value, 100)
            } else {
                XCTFail("Expected number value for 'intValue'")
            }
        }

        // Verify private custom data was set correctly
        XCTAssertNotNil(user.privateCustomData)
        if let privateData = user.privateCustomData?.data {
            if case .string(let value) = privateData["sensitive"] {
                XCTAssertEqual(value, "sensitive-data")
            } else {
                XCTFail("Expected string value for 'sensitive'")
            }

            if case .boolean(let value) = privateData["privateFlag"] {
                XCTAssertEqual(value, true)
            } else {
                XCTFail("Expected boolean value for 'privateFlag'")
            }
        }
    }

    func testDvcUserFromContextWithFlatPropertiesAsCustomData() throws {
        // Create a context with properties that should be added to customData
        let context = MutableContext(
            targetingKey: "user-flat",
            structure: MutableStructure(attributes: [
                "email": .string("user@example.com"),  // Standard property
                "plan": .string("premium"),  // Should go to customData
                "isActive": .boolean(true),  // Should go to customData
                "loginCount": .integer(15),  // Should go to customData
            ])
        )

        // Convert to DevCycleUser
        let user = try provider.dvcUserFromContext(context)

        // Verify standard properties
        XCTAssertEqual(user.userId, "user-flat")
        XCTAssertEqual(user.email, "user@example.com")

        // Verify non-standard properties went to customData
        XCTAssertNotNil(user.customData)
        if let customData = user.customData?.data {
            if case .string(let value) = customData["plan"] {
                XCTAssertEqual(value, "premium")
            } else {
                XCTFail("Expected string value for 'plan'")
            }

            if case .boolean(let value) = customData["isActive"] {
                XCTAssertEqual(value, true)
            } else {
                XCTFail("Expected boolean value for 'isActive'")
            }

            if case .number(let value) = customData["loginCount"] {
                XCTAssertEqual(value, 15)
            } else {
                XCTFail("Expected number value for 'loginCount'")
            }
        }
    }

    func testDvcUserFromContextWithInvalidTypes() throws {
        // Create a context with properties of incorrect types
        let context = MutableContext(
            targetingKey: "user-invalid",
            structure: MutableStructure(attributes: [
                "email": .integer(123),  // Should be ignored as email expects string
                "nestedObject": .structure([  // Complex objects can't be flat customData
                    "key": .string("value")
                ]),
            ])
        )

        // Convert to DevCycleUser - should not throw
        let user = try provider.dvcUserFromContext(context)

        // Email should be nil since we provided an invalid type
        XCTAssertEqual(user.userId, "user-invalid")
        XCTAssertNil(user.email)

        // Nested object should be ignored
        XCTAssertTrue(user.customData?.data.isEmpty ?? true)
    }

    func testDvcUserFromContextWithMissingTargetingKey() {
        // Create a context without a targeting key
        let context = MutableContext(targetingKey: "")

        // Converting should throw
        XCTAssertThrowsError(try provider.dvcUserFromContext(context)) { error in
            XCTAssertEqual(error as? OpenFeatureError, OpenFeatureError.targetingKeyMissingError)
        }
    }

    func testDvcUserFromContextWithAlternativeUserIdFields() throws {
        // Test that user_id and userId fields in attributes can be used as fallbacks

        // Test user_id field
        let context1 = MutableContext(
            targetingKey: "",  // Empty targeting key
            structure: MutableStructure(attributes: [
                "user_id": .string("alt-user-1")
            ])
        )

        let user1 = try provider.dvcUserFromContext(context1)
        XCTAssertEqual(user1.userId, "alt-user-1")

        // Test userId field
        let context2 = MutableContext(
            targetingKey: "",  // Empty targeting key
            structure: MutableStructure(attributes: [
                "userId": .string("alt-user-2")
            ])
        )

        let user2 = try provider.dvcUserFromContext(context2)
        XCTAssertEqual(user2.userId, "alt-user-2")

        // Test targeting key has priority
        let context3 = MutableContext(
            targetingKey: "primary-id",
            structure: MutableStructure(attributes: [
                "user_id": .string("alt-user-3")
            ])
        )

        let user3 = try provider.dvcUserFromContext(context3)
        XCTAssertEqual(user3.userId, "primary-id")
    }

    // MARK: - Value Unwrapping Tests

    func testUnwrapValues() {
        // Create a structure of OpenFeature Value types
        let valueMap: [String: Value] = [
            "string": .string("text value"),
            "boolean": .boolean(true),
            "double": .double(123.456),
            "integer": .integer(42),
            "nestedStructure": .structure([
                "nestedString": .string("nested text"),
                "nestedBoolean": .boolean(false),
            ]),
        ]

        // Unwrap the values to Swift native types
        let unwrapped = provider.unwrapValues(valueMap)

        // Verify all values were unwrapped correctly
        XCTAssertEqual(unwrapped["string"] as? String, "text value")
        XCTAssertEqual(unwrapped["boolean"] as? Bool, true)
        XCTAssertEqual(unwrapped["double"] as? Double, 123.456)
        XCTAssertEqual(unwrapped["integer"] as? Int64, 42)

        // Verify nested structure was also unwrapped correctly
        if let nestedDict = unwrapped["nestedStructure"] as? [String: Any] {
            XCTAssertEqual(nestedDict["nestedString"] as? String, "nested text")
            XCTAssertEqual(nestedDict["nestedBoolean"] as? Bool, false)
        } else {
            XCTFail("Expected nested dictionary")
        }
    }

    func testUnwrapValuesWithEmptyStructure() {
        // Test with empty structure
        let emptyMap: [String: Value] = [
            "emptyStruct": .structure([:])
        ]

        let unwrapped = provider.unwrapValues(emptyMap)

        // Verify the empty structure becomes an empty dictionary
        if let emptyDict = unwrapped["emptyStruct"] as? [String: Any] {
            XCTAssertTrue(emptyDict.isEmpty)
        } else {
            XCTFail("Expected empty dictionary")
        }
    }

    // MARK: - JSON Value Type Tests

    func testIsFlatJsonValue() {
        // Test supported flat JSON value types
        XCTAssertTrue(
            provider.isFlatJsonValue("string value"), "String should be a flat JSON value")
        XCTAssertTrue(provider.isFlatJsonValue(42), "Int should be a flat JSON value")
        XCTAssertTrue(provider.isFlatJsonValue(123.456), "Double should be a flat JSON value")
        XCTAssertTrue(provider.isFlatJsonValue(true), "Bool should be a flat JSON value")
        XCTAssertTrue(provider.isFlatJsonValue(NSNull()), "NSNull should be a flat JSON value")
        XCTAssertTrue(
            provider.isFlatJsonValue(NSNumber(value: 42)), "NSNumber should be a flat JSON value")

        // Test unsupported value types (not flat JSON values)
        XCTAssertFalse(
            provider.isFlatJsonValue(["array", "item"]), "Array should not be a flat JSON value")
        XCTAssertFalse(
            provider.isFlatJsonValue(["key": "value"]), "Dictionary should not be a flat JSON value"
        )
        XCTAssertFalse(provider.isFlatJsonValue(Date()), "Date should not be a flat JSON value")
        XCTAssertFalse(
            provider.isFlatJsonValue(URL(string: "https://example.com")!),
            "URL should not be a flat JSON value")
    }

    // MARK: - CustomData Conversion Tests

    func testConvertToDVCCustomDataWithValidValues() {
        // Create a dictionary with valid flat JSON values
        let validData: [String: Any] = [
            "string": "string value",
            "int": 123,
            "double": 45.67,
            "bool": true,
            "null": NSNull(),
        ]

        // Convert to DVC custom data
        let customData = provider.convertToDVCCustomData(validData)

        // Verify all values were preserved
        XCTAssertEqual(customData.count, 5, "Should have 5 entries")
        XCTAssertEqual(customData["string"] as? String, "string value")
        XCTAssertEqual(customData["int"] as? Int, 123)
        XCTAssertEqual(customData["double"] as? Double, 45.67)
        XCTAssertEqual(customData["bool"] as? Bool, true)
        XCTAssertTrue(customData["null"] is NSNull, "NSNull should be preserved")
    }

    func testConvertToDVCCustomDataWithMixedValues() {
        // Create a dictionary with mixed valid and invalid values
        let mixedData: [String: Any] = [
            "valid1": "string value",
            "valid2": 42,
            "valid3": true,
            "invalid1": ["array", "items"],  // Array should be skipped
            "invalid2": ["key": "value"],  // Dictionary should be skipped
            "invalid3": Date(),  // Date should be skipped
            "valid4": 123.456,
        ]

        // Convert to DVC custom data
        let customData = provider.convertToDVCCustomData(mixedData)

        // Verify only valid values were included
        XCTAssertEqual(customData.count, 4, "Should have 4 entries (only valid ones)")
        XCTAssertEqual(customData["valid1"] as? String, "string value")
        XCTAssertEqual(customData["valid2"] as? Int, 42)
        XCTAssertEqual(customData["valid3"] as? Bool, true)
        XCTAssertEqual(customData["valid4"] as? Double, 123.456)

        // Verify invalid values were skipped
        XCTAssertNil(customData["invalid1"], "Array should be skipped")
        XCTAssertNil(customData["invalid2"], "Dictionary should be skipped")
        XCTAssertNil(customData["invalid3"], "Date should be skipped")
    }

    func testConvertToDVCCustomDataWithEmptyInput() {
        // Test with empty input
        let emptyData: [String: Any] = [:]

        // Convert to DVC custom data
        let customData = provider.convertToDVCCustomData(emptyData)

        // Verify result is empty
        XCTAssertTrue(customData.isEmpty, "Result should be empty")
    }

    func testConvertToDVCCustomDataWithEdgeCases() {
        // Create dictionary with edge cases
        let edgeCaseData: [String: Any] = [
            "emptyString": "",
            "zero": 0,
            "maxInt": Int.max,
            "minInt": Int.min,
            "specialChars": "!@#$%^&*()_+{}:\"<>?|[];',./",
            "emoji": "😀🚀💻🔥",
        ]

        // Convert to DVC custom data
        let customData = provider.convertToDVCCustomData(edgeCaseData)

        // Verify all edge cases were handled correctly
        XCTAssertEqual(customData.count, 6, "Should have 6 entries")
        XCTAssertEqual(customData["emptyString"] as? String, "")
        XCTAssertEqual(customData["zero"] as? Int, 0)
        XCTAssertEqual(customData["maxInt"] as? Int, Int.max)
        XCTAssertEqual(customData["minInt"] as? Int, Int.min)
        XCTAssertEqual(customData["specialChars"] as? String, "!@#$%^&*()_+{}:\"<>?|[];',./")
        XCTAssertEqual(customData["emoji"] as? String, "😀🚀💻🔥")
    }

    // MARK: - Value to Dictionary Conversion Tests

    func testConvertValueToDictionaryWithPrimitiveTypes() {
        // Test the internal method directly with primitive types
        let value = Value.structure([
            "string": .string("hello world"),
            "boolean": .boolean(true),
            "integer": .integer(123),
            "double": .double(45.67),
        ])

        let result = provider.convertValueToDictionary(value)

        // Validate the result
        XCTAssertEqual(result.count, 4, "Should have 4 entries")
        XCTAssertEqual(result["string"] as? String, "hello world")
        XCTAssertEqual(result["boolean"] as? Bool, true)
        XCTAssertEqual(result["integer"] as? Int64, 123)
        XCTAssertEqual(result["double"] as? Double, 45.67)
    }

    func testConvertValueToDictionaryWithNestedStructure() {
        // Test the internal method with nested structures
        let value = Value.structure([
            "topLevel": .boolean(true),
            "nestedDict": .structure([
                "nestedString": .string("nested value"),
                "nestedBool": .boolean(false),
                "deeplyNested": .structure([
                    "level3": .string("deeply nested value"),
                    "number": .double(123.456),
                ]),
            ]),
        ])

        let result = provider.convertValueToDictionary(value)

        // Validate the result
        XCTAssertEqual(result.count, 2, "Should have 2 top-level entries")
        XCTAssertEqual(result["topLevel"] as? Bool, true)

        // Check first level nesting
        if let nestedDict = result["nestedDict"] as? [String: Any] {
            XCTAssertEqual(nestedDict.count, 3, "Nested dict should have 3 entries")
            XCTAssertEqual(nestedDict["nestedString"] as? String, "nested value")
            XCTAssertEqual(nestedDict["nestedBool"] as? Bool, false)

            // Check second level nesting
            if let deeplyNested = nestedDict["deeplyNested"] as? [String: Any] {
                XCTAssertEqual(deeplyNested.count, 2, "Deeply nested dict should have 2 entries")
                XCTAssertEqual(deeplyNested["level3"] as? String, "deeply nested value")
                XCTAssertEqual(deeplyNested["number"] as? Double, 123.456)
            } else {
                XCTFail("Expected deeply nested dictionary")
            }
        } else {
            XCTFail("Expected nested dictionary")
        }
    }

    func testConvertValueToDictionaryWithUnsupportedTypes() {
        // Test how the method handles unsupported Value types
        let value = Value.structure([
            "normalKey": .string("normal value"),
            "unsupportedKey": .list([.string("item1"), .string("item2")]),
        ])

        let result = provider.convertValueToDictionary(value)

        // Only the normal key should be present, unsupported type should be skipped
        XCTAssertEqual(result.count, 1, "Should have 1 entry")
        XCTAssertEqual(result["normalKey"] as? String, "normal value")
        XCTAssertNil(result["unsupportedKey"], "Unsupported types should be skipped")
    }

    func testConvertValueToDictionaryWithEmptyStructure() {
        // Test with empty structure
        let value = Value.structure([:])

        let result = provider.convertValueToDictionary(value)

        // Verify result is empty
        XCTAssertTrue(result.isEmpty, "Result should be empty")
    }

    func testConvertValueToDictionaryWithNonStructureValue() {
        // Test with non-structure Value types
        let stringValue = Value.string("just a string")
        let boolValue = Value.boolean(true)
        let doubleValue = Value.double(123.45)
        let intValue = Value.integer(42)

        // All should convert to empty dictionaries since they're not structures
        XCTAssertTrue(provider.convertValueToDictionary(stringValue).isEmpty)
        XCTAssertTrue(provider.convertValueToDictionary(boolValue).isEmpty)
        XCTAssertTrue(provider.convertValueToDictionary(doubleValue).isEmpty)
        XCTAssertTrue(provider.convertValueToDictionary(intValue).isEmpty)
    }
}
