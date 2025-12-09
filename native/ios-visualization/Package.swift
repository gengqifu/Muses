// swift-tools-version:5.7
import PackageDescription

let package = Package(
    name: "SoundwaveVisualization",
    platforms: [
        .iOS(.v12)
    ],
    products: [
        .library(
            name: "SoundwaveVisualization",
            targets: ["SoundwaveVisualization"]
        ),
    ],
    targets: [
        .binaryTarget(
            name: "SoundwaveVisualization",
            path: "SoundwaveVisualization.xcframework"
        ),
    ]
)
