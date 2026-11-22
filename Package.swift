// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "Rueber",
    platforms: [.macOS(.v26)],
    targets: [
        .target(name: "RueberCore"),
        .executableTarget(name: "Rueber", dependencies: ["RueberCore"]),
        .testTarget(name: "RueberCoreTests", dependencies: ["RueberCore"]),
    ],
    swiftLanguageModes: [.v5]
)
