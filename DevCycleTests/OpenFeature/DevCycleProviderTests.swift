import OpenFeature
import XCTest

final class DevCycleProviderTests: XCTestCase {

    private var mockClient: MockDevCycleClient!
    private var provider: DevCycleProvider!

    override func setUp() async throws {
        mockClient = MockDevCycleClient()
        provider = DevCycleProvider(client: mockClient)
    }

    override func tearDown() async throws {
        mockClient = nil
        provider = nil
    }

    // MARK: - Initialization Tests

    func testProviderInitialization() {
        XCTAssertEqual(provider.metadata.name, "DevCycle Provider")
        XCTAssertTrue(provider.hooks.isEmpty)
    }

    // MARK: - Context Tests

    func testInitializeWithContext() async {
        // Create a context with targeting key and attributes
        let context = MutableContext(
            targetingKey: "test-user",
            structure: MutableStructure(attributes: [
                "email": Value.string("test@example.com"),
                "isPremium": Value.boolean(true),
                "loginCount": Value.number(5.0),
            ])
        )

        // Initialize the provider with the context
        await provider.initialize(initialContext: context)

        // Verify that the DevCycle user was created with the correct values
        XCTAssertTrue(mockClient.identifyUserCalled)
        XCTAssertEqual(mockClient.lastIdentifiedUser?.userId, "test-user")

        // Check custom data
        let customData = mockClient.lastIdentifiedUser?.customData
        XCTAssertEqual(customData?["email"] as? String, "test@example.com")
        XCTAssertEqual(customData?["isPremium"] as? Bool, true)
        XCTAssertEqual(customData?["loginCount"] as? Double, 5.0)
    }

    func testContextUpdate() async {
        // Initial context
        let initialContext = MutableContext(targetingKey: "user-1")
        await provider.initialize(initialContext: initialContext)

        // Update context
        let newContext = MutableContext(
            targetingKey: "user-2",
            structure: MutableStructure(attributes: ["role": Value.string("admin")])
        )

        await provider.onContextSet(oldContext: initialContext, newContext: newContext)

        // Verify user was updated
        XCTAssertEqual(mockClient.lastIdentifiedUser?.userId, "user-2")
        XCTAssertEqual(mockClient.lastIdentifiedUser?.customData["role"] as? String, "admin")
    }

    // MARK: - Flag Evaluation Tests

    func testBooleanEvaluation() throws {
        // Setup mock variable
        let mockVariable = MockDVCVariable(key: "test-bool", defaultValue: false)
        mockVariable.mockValue = true
        mockVariable.mockIsDefaulted = false
        mockVariable.mockEvalReason = "TARGETING_MATCH"
        mockClient.mockVariables["test-bool"] = mockVariable

        // Evaluate the flag
        let result = try provider.getBooleanEvaluation(
            key: "test-bool", defaultValue: false, context: nil)

        // Verify the results
        XCTAssertTrue(result.value)
        XCTAssertEqual(result.variant, "default")
        XCTAssertEqual(result.reason, "TARGETING_MATCH")
    }

    func testStringEvaluation() throws {
        // Setup mock variable
        let mockVariable = MockDVCVariable(key: "test-string", defaultValue: "default")
        mockVariable.mockValue = "custom value"
        mockVariable.mockIsDefaulted = false
        mockVariable.mockEvalReason = "TARGETING_MATCH"
        mockClient.mockVariables["test-string"] = mockVariable

        // Evaluate the flag
        let result = try provider.getStringEvaluation(
            key: "test-string", defaultValue: "default", context: nil)

        // Verify the results
        XCTAssertEqual(result.value, "custom value")
        XCTAssertEqual(result.variant, "default")
        XCTAssertEqual(result.reason, "TARGETING_MATCH")
    }

    func testDefaultValueWhenFlagNotFound() throws {
        // Evaluate a flag that doesn't exist
        let result = try provider.getStringEvaluation(
            key: "non-existent-flag", defaultValue: "fallback", context: nil)

        // Verify the default value is returned
        XCTAssertEqual(result.value, "fallback")
        XCTAssertNil(result.variant)
        XCTAssertEqual(result.reason, "DEFAULT")
    }
}

// MARK: - Mock Classes

class MockDevCycleClient: DevCycleClient {
    var identifyUserCalled = false
    var lastIdentifiedUser: DevCycleUser?
    var mockVariables: [String: MockDVCVariable<Any>] = [:]

    override func identifyUser(user: DevCycleUser, callback: IdentifyCompletedHandler? = nil) throws
    {
        identifyUserCalled = true
        lastIdentifiedUser = user
        callback?(nil, nil)
        return
    }

    override func variable<T>(key: String, defaultValue: T) -> DVCVariable<T> {
        if let mockVar = mockVariables[key] as? MockDVCVariable<T> {
            return mockVar
        }

        return MockDVCVariable(key: key, defaultValue: defaultValue)
    }
}

class MockDVCVariable<T>: DVCVariable<T> {
    var mockValue: T
    var mockIsDefaulted: Bool = true
    var mockEvalReason: String?

    override var value: T {
        get { return mockValue }
        set { mockValue = newValue }
    }

    override var isDefaulted: Bool {
        get { return mockIsDefaulted }
        set { mockIsDefaulted = newValue }
    }

    override var evalReason: String? {
        get { return mockEvalReason }
        set { mockEvalReason = newValue }
    }

    init(key: String, defaultValue: T) {
        self.mockValue = defaultValue
        super.init(key: key, value: defaultValue, defaultValue: defaultValue, evalReason: nil)
    }
}
