# DevCycle iOS Client SDK

[![CocoaPods compatible](https://img.shields.io/cocoapods/v/DevCycle.svg)](https://cocoapods.org/pods/DevCycle)
[![Carthage compatible](https://img.shields.io/badge/Carthage-compatible-4BC51D.svg?style=flat)](https://github.com/Carthage/Carthage)
[![SwiftPM compatible](https://img.shields.io/badge/SwiftPM-compatible-4BC51D.svg?style=flat)](https://swift.org/package-manager/)


The DevCycle iOS Client SDK. This SDK uses our Client SDK APIs to perform all user segmentation 
and bucketing for the SDK, providing fast response times using our globally distributed edge workers 
all around the world.

## Requirements

This version of the DevCycle iOS Client SDK supports a minimum of iOS 12.

## Installation

** Note **: Versions `1.3.2` and below are deprecated due to changes to the `UserConfig` model that support new properties from the retrieved config.

### CocoaPods

The SDK can be installed into your iOS project by adding the following to your cocoapod spec:

```swift
pod 'DevCycle'
```

### Carthage

Include the following in your `Cartfile`: 

```swift
github "DevCycleHQ/ios-client-sdk"
```

### Swift Package Manager

To use the library with Swift Package Manager, include it as a dependency in your `Package.swift` file like so:

```
...
    dependencies: [
        .package(url: "https://github.com/DevCycleHQ/ios-client-sdk.git", .upToNextMinor("1.3.5")),
    ],
    targets: [
        .target(
            name: "YOUR_TARGET",
            dependencies: ["DevCycle"]
        )
    ],
...
```

You can also add it through Xcode, i.e. `File > Swift Packages > Add Package Dependency`, then enter the repository clone URL.

## Usage

To find usage documentation, check out our [docs](https://docs.devcycle.com/docs/sdk/client-side-sdks/ios).
