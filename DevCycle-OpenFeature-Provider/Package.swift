// swift-tools-version:5.3
import PackageDescription

let package = Package(
    name: "DevCycleOpenFeatureProvider",
    platforms: [
        .iOS(.v14),
        .tvOS(.v14),
        .macOS(.v11),
        .watchOS(.v7),
    ],
    products: [
        .library(
            name: "DevCycleOpenFeatureProvider",
            targets: ["DevCycleOpenFeatureProvider"])
    ],
    dependencies: [
        .package(
            name: "OpenFeature",
            url: "https://github.com/open-feature/swift-sdk.git",
            .upToNextMajor(from: "0.3.0")
        ),
        // For local development, fastlane will dynamically update this package reference
        // to use the local path. No change needed to this file.
        .package(
            name: "DevCycle",
            url: "https://github.com/DevCycleHQ/ios-client-sdk.git",
            .upToNextMajor(from: "1.0.0")
        ),
    ],
    targets: [
        .target(
            name: "DevCycleOpenFeatureProvider",
            dependencies: [
                .product(name: "OpenFeature", package: "OpenFeature"),
                .product(name: "DevCycle", package: "DevCycle"),
            ]
        ),
        .testTarget(
            name: "DevCycleOpenFeatureProviderTests",
            dependencies: ["DevCycleOpenFeatureProvider"]
        ),
    ],
    swiftLanguageVersions: [.v5]
)
