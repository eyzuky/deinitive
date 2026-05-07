// swift-tools-version: 5.10
import PackageDescription

let package = Package(
    name: "memwatch",
    platforms: [.macOS(.v14)],
    products: [
        .executable(name: "memwatch", targets: ["memwatch"]),
        .library(name: "MemwatchCore", targets: ["MemwatchCore"]),
        .library(name: "MemwatchMCP", targets: ["MemwatchMCP"]),
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-argument-parser.git", from: "1.5.0"),
    ],
    targets: [
        .executableTarget(
            name: "memwatch",
            dependencies: [
                "MemwatchCore",
                "MemwatchMCP",
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
            ]
        ),
        .target(name: "MemwatchCore"),
        .target(name: "MemwatchMCP", dependencies: ["MemwatchCore"]),
        .testTarget(
            name: "MemwatchCoreTests",
            dependencies: ["MemwatchCore"],
            resources: [.copy("Fixtures")]
        ),
    ]
)
