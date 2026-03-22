// swift-tools-version: 5.10
import PackageDescription

let package = Package(
    name: "ClipVault",
    platforms: [
        .macOS(.v14)
    ],
    targets: [
        .executableTarget(
            name: "ClipVault",
            path: "Sources/ClipVault",
            swiftSettings: [
                .enableUpcomingFeature("StrictConcurrency")
            ]
        ),
        .testTarget(
            name: "ClipVaultTests",
            dependencies: ["ClipVault"],
            path: "Tests/ClipVaultTests"
        )
    ]
)
