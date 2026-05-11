// swift-tools-version: 5.10
import PackageDescription

let package = Package(
    name: "deinitive",
    platforms: [.macOS(.v14)],
    products: [
        .executable(name: "deinitive", targets: ["deinitive"]),
        .library(name: "DeinitiveCore", targets: ["DeinitiveCore"]),
        .library(name: "DeinitiveMCP", targets: ["DeinitiveMCP"]),
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-argument-parser.git", from: "1.5.0"),
    ],
    targets: [
        .executableTarget(
            name: "deinitive",
            dependencies: [
                "DeinitiveCore",
                "DeinitiveMCP",
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
            ]
        ),
        .target(name: "DeinitiveCore"),
        .target(name: "DeinitiveMCP", dependencies: ["DeinitiveCore"]),
        .testTarget(
            name: "DeinitiveCoreTests",
            dependencies: ["DeinitiveCore"],
            resources: [.copy("Fixtures")]
        ),
    ]
)
