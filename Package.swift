// swift-tools-version:5.2
import PackageDescription

let package = Package(
    name: "DevCycle",
    platforms: [
        .iOS(.v12)
    ],
    products: [
        .library(
            name: "DevCycle",
            targets: ["DevCycle"]),
    ],
    dependencies: [
       .package(url: "https://github.com/LaunchDarkly/swift-eventsource.git", .upToNextMajor(from: "3.0.0"))
   ],
    targets: [
        .target(
            name: "DevCycle",
            path: "DevCycle",
            dependencies: [
                "LDSwiftEventSource"
            ]
        ),
        .testTarget(
            name: "DevCycleTests",
            dependencies: [
                "DevCycle",
            ],
            path: "DevCycleTests",
            exclude: ["ObjC"]
        ),
        .testTarget(
            name: "DevCycleTests-ObjC",
            dependencies: [
                "DevCycle",
            ],
            path: "DevCycleTests/ObjC"
        ),
    ],
    swiftLanguageVersions: [.v5]
)

