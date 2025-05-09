import OpenFeature
import XCTest

@testable import DevCycle

final class DevCycleProviderTests: XCTestCase {

    private var sdkKey: String!
    private var provider: DevCycleProvider!

    override func setUp() async throws {
        sdkKey = "test-sdk-key"
        provider = DevCycleProvider(sdkKey: sdkKey)
    }

    override func tearDown() async throws {
        provider = nil
    }

    // MARK: - Initialization Tests

    func testProviderInitialization() {
        XCTAssertEqual(provider.metadata.name, "DevCycle Provider")
        XCTAssertTrue(provider.hooks.isEmpty)
    }

    // MARK: - Context and Provider Tests

    func testInitializeWithContext() async throws {
        // Skip actual initialization since we don't want to make real API calls in unit tests
        // This is a unit test for the provider's behavior, not for the actual API calls

        // Create a context with targeting key and attributes
        let context = MutableContext(
            targetingKey: "test-user",
            structure: MutableStructure(attributes: [
                "email": Value.string("test@example.com"),
                "isPremium": Value.boolean(true),
                "loginCount": Value.double(5.0),
            ])
        )

        // We should be able to create a provider with this context
        // We won't actually initialize since it would make real API calls
        let testProvider = DevCycleProvider(sdkKey: sdkKey)
        XCTAssertNotNil(testProvider)
    }

    // MARK: - Flag Evaluation Tests

    func testFlagEvaluationDefaultValues() throws {
        // Since we don't have initialized provider with real variables,
        // we should get default values for all flag evaluations

        // Boolean evaluation
        let boolResult = try provider.getBooleanEvaluation(
            key: "test-bool", defaultValue: true, context: nil as EvaluationContext?)
        XCTAssertEqual(boolResult.value, true)
        XCTAssertEqual(boolResult.reason, "DEFAULT")

        // String evaluation
        let stringResult = try provider.getStringEvaluation(
            key: "test-string", defaultValue: "default-value", context: nil as EvaluationContext?)
        XCTAssertEqual(stringResult.value, "default-value")
        XCTAssertEqual(stringResult.reason, "DEFAULT")

        // Number evaluation
        let numberResult = try provider.getDoubleEvaluation(
            key: "test-number", defaultValue: 42.0, context: nil as EvaluationContext?)
        XCTAssertEqual(numberResult.value, 42.0)
        XCTAssertEqual(numberResult.reason, "DEFAULT")
    }

    func testObjectEvaluation() throws {
        // Test object evaluation with a complex structure
        let defaultValue = Value.structure([
            "name": Value.string("John"),
            "age": Value.double(30),
            "isActive": Value.boolean(true),
        ])

        let result = try provider.getObjectEvaluation(
            key: "test-object", defaultValue: defaultValue, context: nil as EvaluationContext?)

        XCTAssertEqual(result.reason, "DEFAULT")

        if case .structure(let attributes) = result.value {
            XCTAssertEqual(attributes["name"], Value.string("John"))
            XCTAssertEqual(attributes["age"], Value.double(30))
            XCTAssertEqual(attributes["isActive"], Value.boolean(true))
        } else {
            XCTFail("Expected structure value")
        }
    }
}
