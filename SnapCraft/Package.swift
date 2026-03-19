// swift-tools-version: 5.10
import PackageDescription

let package = Package(
    name: "SnapCraft",
    platforms: [
        .macOS(.v14)
    ],
    targets: [
        .executableTarget(
            name: "SnapCraft",
            path: "Sources/SnapCraft",
            resources: [
                .process("Resources")
            ],
            swiftSettings: [
                .enableUpcomingFeature("StrictConcurrency")
            ]
        ),
        .testTarget(
            name: "SnapCraftTests",
            dependencies: ["SnapCraft"],
            path: "Tests/SnapCraftTests"
        )
    ]
)
