# DevCycle OpenFeature Provider Examples

This directory contains example applications demonstrating how to use the DevCycle OpenFeature Provider.

## DevCycle-iOS-OpenFeature-Example-App-Swift

A simple iOS app showing how to integrate DevCycle with OpenFeature using Swift.

### Setup

1. Open the Xcode project in the `DevCycle-iOS-OpenFeature-Example-App-Swift` directory
2. Add your DevCycle SDK key to the `DevCycleKeys.DEVELOPMENT` constant in `OpenFeatureManager.swift`
3. Update the project's Swift Package dependencies:
   - During development: Add the local DevCycleOpenFeatureProvider package (File > Add Packages > Add Local...)
   - For release: Use the published version from GitHub
4. Build and run the application

### Development Notes

When developing and testing locally:
- The package is configured to use the local DevCycle SDK in the parent directory
- This allows changes to the main SDK to be immediately reflected in the provider

When preparing for release:
- Modify `Package.swift` to use the GitHub URL instead of the local path
- Update the version number before publishing

### Key Files

- **OpenFeatureManager.swift**: Sets up the DevCycle provider and initializes OpenFeature
- **ViewController.swift**: Demonstrates how to use feature flags via the OpenFeature API

### Adding to Your Own Project

To add the DevCycle OpenFeature Provider to your own iOS project:

1. Add the DevCycleOpenFeatureProvider package to your project:
   ```swift
   .package(url: "https://github.com/DevCycleHQ/openfeature-provider-swift.git", from: "1.0.0")
   ```

2. Import the necessary frameworks:
   ```swift
   import DevCycle
   import DevCycleOpenFeatureProvider
   import OpenFeature
   ```

3. Initialize the provider and set it up with OpenFeature:
   ```swift
   // Create the DevCycle provider
   let provider = DevCycleProvider(sdkKey: "DEVCYCLE_MOBILE_SDK_KEY")
   
   // Set the provider in OpenFeature
   Task {
       await OpenFeatureAPI.shared.setProviderAndWait(provider: provider)
   }
   ```

4. Use feature flags through the OpenFeature API:
   ```swift
   let client = OpenFeatureAPI.shared.getClient()
   let flagValue = client.getBooleanValue(key: "flag-key", defaultValue: false)
   ``` 