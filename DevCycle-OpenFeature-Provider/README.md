# DevCycle OpenFeature Provider

This package provides a DevCycle provider implementation for the [OpenFeature iOS SDK](https://openfeature.dev/docs/reference/technologies/client/swift) feature flagging SDK. It allows you to use DevCycle as the feature flag management system behind the standardized OpenFeature API.

## Installation

### Swift Package Manager

Add the dependency to your `Package.swift` file:

```swift
.package(url: "https://github.com/DevCycleHQ/ios-client-sdk.git", from: "1.18.0")
```

Then add both `DevCycle` and `DevCycleOpenFeatureProvider` to your target's dependencies:

```swift
.target(
    name: "YourTarget",
    dependencies: [
        .product(name: "DevCycle", package: "ios-client-sdk"),
        .product(name: "DevCycleOpenFeatureProvider", package: "ios-client-sdk")
    ]
)
```

## Usage

```swift
import OpenFeature
import DevCycle
import DevCycleOpenFeatureProvider

// Configure the DevCycle provider
let provider = DevCycleProvider(sdkKey: "<YOUR_DEVCYCLE_SDK_KEY>")

// Set up the evaluation context
let evaluationContext = MutableContext(
    targetingKey: "user-123",
    structure: MutableStructure(attributes: [
        "email": .string("user@example.com"),
        "name": .string("Test User")
    ])
)

// Initialize OpenFeature with the DevCycle provider
Task {
    // Set the evaluation context
    OpenFeatureAPI.shared.setEvaluationContext(evaluationContext: evaluationContext)
    
    // Set the provider
    try await OpenFeatureAPI.shared.setProviderAndWait(provider: provider)
    
    // Get a client
    let client = OpenFeatureAPI.shared.getClient()
    
    // Evaluate flags
    let boolValue = client.getBooleanValue(key: "my-boolean-flag", defaultValue: false)
    let stringValue = client.getStringValue(key: "my-string-flag", defaultValue: "default")
    
    print("Bool flag value: \(boolValue)")
    print("String flag value: \(stringValue)")
}
```

## Example App

An example iOS application demonstrating how to use the DevCycle OpenFeature Provider can be found in the [Examples](./Examples) directory. This example shows how to:

1. Initialize the DevCycle provider
2. Set up an evaluation context
3. Evaluate different types of feature flags
4. Handle flag changes

See the [Examples README](./Examples/README.md) for more details.

## Development

### Local Setup

During development, this package can be configured to use the local DevCycle SDK:

```swift
// In Package.swift
.package(
    name: "DevCycle",
    path: ".."  // Uses the DevCycle SDK in the parent directory
)
```

This setup allows for easier development and testing:
- Changes to the main DevCycle SDK are immediately reflected in the provider
- You can test changes to both packages together without publishing
- Make sure you revert this to not break publishing