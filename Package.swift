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
    targets: [
        .target(
            name: "DevCycle",
            path: "DevCycle"
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

