// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "Goschn",
    platforms: [.macOS(.v26)],
    targets: [
        .target(name: "GoschnCore"),
        .executableTarget(name: "Goschn", dependencies: ["GoschnCore"]),
        .testTarget(name: "GoschnCoreTests", dependencies: ["GoschnCore"]),
    ],
    swiftLanguageModes: [.v5]
)
