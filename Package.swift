// swift-tools-version:5.3
import PackageDescription

let package = Package(
    name: "DevCycle",
    // Package minimum requirements
    // Note: DevCycleOpenFeatureProvider requires higher minimums at runtime
    // (iOS 14+, tvOS 14+, macOS 11+, watchOS 7+)
    platforms: [
        .iOS(.v12),
        .tvOS(.v12),
        .macOS(.v10_13),
        .watchOS(.v7),
    ],
    products: [
        .library(
            name: "DevCycle",
            targets: ["DevCycle"]),
        .library(
            name: "DevCycleOpenFeatureProvider",
            targets: ["DevCycleOpenFeatureProvider"]),
    ],
    dependencies: [
        .package(
            name: "LDSwiftEventSource",
            url: "https://github.com/LaunchDarkly/swift-eventsource.git",
            .upToNextMajor(from: "3.3.0")
        ),
        .package(
            name: "OpenFeature",
            url: "https://github.com/open-feature/swift-sdk.git",
            .upToNextMajor(from: "0.3.0")
        ),
    ],
    targets: [
        // Base DevCycle SDK - supports iOS 12+, tvOS 12+, macOS 10.13+, watchOS 7+
        .target(
            name: "DevCycle",
            dependencies: [
                .product(name: "LDSwiftEventSource", package: "LDSwiftEventSource")
            ],
            path: "DevCycle",
            resources: [
                .process("PrivacyInfo.xcprivacy")
            ]
        ),
        // OpenFeature Provider - requires iOS 14+, tvOS 14+, macOS 11+, watchOS 7+
        // (runtime checks should be implemented in the code)
        .target(
            name: "DevCycleOpenFeatureProvider",
            dependencies: [
                .product(name: "OpenFeature", package: "OpenFeature"),
                .target(name: "DevCycle"),
            ],
            path: "DevCycle-OpenFeature-Provider/Sources/DevCycleOpenFeatureProvider"
        ),
        .testTarget(
            name: "DevCycleTests",
            dependencies: [
                "DevCycle"
            ],
            path: "DevCycleTests",
            exclude: ["ObjC"]
        ),
        .testTarget(
            name: "DevCycleTests-ObjC",
            dependencies: [
                "DevCycle"
            ],
            path: "DevCycleTests/ObjC"
        ),
        .testTarget(
            name: "DevCycleOpenFeatureProviderTests",
            dependencies: [
                .target(name: "DevCycleOpenFeatureProvider")
            ],
            path: "DevCycle-OpenFeature-Provider/Tests/DevCycleOpenFeatureProviderTests"
        ),
    ],
    swiftLanguageVersions: [.v5]
)
