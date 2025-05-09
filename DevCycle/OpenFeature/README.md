# DevCycle Provider for OpenFeature Swift SDK

This provider integrates the DevCycle iOS SDK with the OpenFeature Swift SDK, allowing you to use DevCycle's feature flags through the standardized OpenFeature API.

## Requirements

- iOS 14+ / macOS 10.15+ / tvOS 14+ / watchOS 7+
- Swift 5.5+
- DevCycle iOS SDK
- OpenFeature Swift SDK (v0.3.0+)

## Installation

The DevCycle OpenFeature provider is included in the DevCycle SDK package.

### Swift Package Manager

Add the DevCycle SDK to your project in Xcode or via Package.swift:

```swift
dependencies: [
    .package(url: "https://github.com/DevCycleHQ/ios-client-sdk.git", from: "VERSION"),
    .package(url: "https://github.com/open-feature/swift-sdk.git", from: "0.3.0")
]
```

### CocoaPods

```ruby
# Podfile
pod 'DevCycle'
pod 'openfeature-swift-sdk', '~> 0.3.0'
```

## Usage

### 1. Initialize the DevCycle Client

```swift
import DevCycle
import OpenFeature

// Create a DevCycle user
let user = try DevCycleUser.builder()
    .userId("user-123")
    .email("user@example.com")
    .build()

// Initialize DevCycle client
let client = try DevCycleClient.builder()
    .sdkKey("YOUR_DEVCYCLE_SDK_KEY")
    .user(user)
    .build(onInitialized: { error in
        if let error = error {
            print("DevCycle initialization error: \(error)")
        } else {
            print("DevCycle initialized successfully")
        }
    })
```

### 2. Create and Set the DevCycle Provider

```swift
// Create DevCycle provider
let provider = DevCycleProvider(client: client)

// Set the provider in OpenFeature
await OpenFeatureAPI.shared.setProviderAndWait(provider: provider)
```

### 3. Create an Evaluation Context

```swift
// Create context with targeting information
let context = MutableContext(
    targetingKey: "user-123",
    structure: MutableStructure(attributes: [
        "email": Value.string("user@example.com"),
        "country": Value.string("US"),
        "isPremium": Value.boolean(true)
    ])
)

// Set the evaluation context
OpenFeatureAPI.shared.setEvaluationContext(evaluationContext: context)
```

### 4. Evaluate Feature Flags

```swift
// Get the OpenFeature client
let featureClient = OpenFeatureAPI.shared.getClient()

// Evaluate a boolean flag
let boolFlag = featureClient.getBooleanValue(key: "new-feature-enabled", defaultValue: false)

// Evaluate a string flag
let stringFlag = featureClient.getStringValue(key: "welcome-message", defaultValue: "Welcome!")

// Evaluate a number flag
let numberFlag = featureClient.getNumberValue(key: "retry-count", defaultValue: 3)

// Get detailed flag evaluation with metadata
let details = featureClient.getBooleanDetails(key: "new-feature-enabled", defaultValue: false)
print("Value: \(details.value), Variant: \(details.variant ?? "none"), Reason: \(details.reason)")
```

### 5. Listen for Provider Events

```swift
OpenFeatureAPI.shared.observe().sink { event in
    switch event {
    case .ready:
        print("Provider is ready")
    case .error:
        print("Provider error occurred")
    case .configurationChanged:
        print("Provider configuration changed")
    default:
        print("Other provider event: \(event)")
    }
}
```

## Updating Context

When you need to update the evaluation context (e.g., when a user logs in or properties change):

```swift
// Create a new context
let newContext = MutableContext(
    targetingKey: "new-user-456",
    structure: MutableStructure(attributes: [
        "email": Value.string("newuser@example.com"),
        "country": Value.string("CA")
    ])
)

// Update the evaluation context
OpenFeatureAPI.shared.setEvaluationContext(evaluationContext: newContext)
```

## Mapping Between DevCycle and OpenFeature

The provider maps between DevCycle and OpenFeature concepts as follows:

1. DevCycle variables → OpenFeature flags
2. OpenFeature evaluation context → DevCycle user attributes
3. OpenFeature `targetingKey` → DevCycle `userId`
4. DevCycle evaluation reason → OpenFeature evaluation reason

## Feature Support

| Feature | Support |
|---------|---------|
| Boolean flags | ✅ |
| String flags | ✅ |
| Number flags | ✅ |
| JSON/Object flags | ✅ |
| Targeting | ✅ |
| Context updates | ✅ |
| Provider events | ✅ |

## License

This provider is available under the same license as the DevCycle iOS SDK. 