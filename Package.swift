// swift-tools-version:5.3
import PackageDescription

let package = Package(
    name: "DevCycle",
    platforms: [
        .iOS(.v12),
        .tvOS(.v12),
        .macOS(.v10_13),
        .watchOS(.v7),
    ],
    products: [
        .library(
            name: "DevCycle",
            targets: ["DevCycle"])
    ],
    dependencies: [
        .package(
            name: "LDSwiftEventSource",
            url: "https://github.com/LaunchDarkly/swift-eventsource.git",
            .upToNextMajor(from: "3.3.0")
        )
    ],
    targets: [
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
        .testTarget(
            name: "DevCycleTests",
            dependencies: ["DevCycle"],
            path: "DevCycleTests",
            exclude: ["ObjC"],
            resources: [
                .process("Models/test_config.json"),
                .process("Models/test_config_eval_reason.json"),
            ]
        ),
        .testTarget(
            name: "DevCycleTests-ObjC",
            dependencies: ["DevCycle"],
            path: "DevCycleTests/ObjC"
        ),
    ],
    swiftLanguageVersions: [.v5]
)
