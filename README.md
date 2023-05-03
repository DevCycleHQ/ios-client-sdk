# DevCycle iOS / macOS Client SDK

[![CocoaPods compatible](https://img.shields.io/cocoapods/v/DevCycle.svg)](https://cocoapods.org/pods/DevCycle)
[![Carthage compatible](https://img.shields.io/badge/Carthage-compatible-4BC51D.svg?style=flat)](https://github.com/Carthage/Carthage)
[![SwiftPM compatible](https://img.shields.io/badge/SwiftPM-compatible-4BC51D.svg?style=flat)](https://swift.org/package-manager/)


The DevCycle iOS / tvOS / watchOS / macOS Client SDK. This SDK uses our Client SDK APIs to perform all user segmentation 
and bucketing for the SDK, providing fast response times using our globally distributed edge workers 
all around the world.

## Requirements

This version of the DevCycle Client SDK supports iOS 12.0+ / tvOS 12.0+ / watchOS 7.0+ / macOS 10.13+

## Installation

### CocoaPods

The SDK can be installed into your iOS project by adding the following to your cocoapod spec:

```swift
pod 'DevCycle'
```
Then, run `pod install`.

### Swift Package Manager

To use the library with Swift Package Manager, include it as a dependency in your `Package.swift` file like so:

```
...
    dependencies: [
        .package(url: "https://github.com/DevCycleHQ/ios-client-sdk.git", .upToNextMajor("1.11.2")),
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

### Carthage

**WARNING: Carthage Support is currently not working correctly, we are investigating soutions.**

Include the following in your `Cartfile` to integrate DevCycle as a dependency to your project: 

```swift
github "DevCycleHQ/ios-client-sdk"
```

Then, run `carthage update --use-xcframeworks`. Drag the built .xcframework bundles from Carthage/Build into the "Frameworks and Libraries" section of your application’s Xcode project.

## Usage

To find usage documentation, check out our [docs](https://docs.devcycle.com/docs/sdk/client-side-sdks/ios).
