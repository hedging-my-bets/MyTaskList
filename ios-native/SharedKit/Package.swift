// swift-tools-version: 5.10
import PackageDescription

let package = Package(
    name: "SharedKit",
    platforms: [
        .iOS(.v17)
    ],
    products: [
        .library(
            name: "SharedKit",
            targets: ["SharedKit"]
        ),
    ],
    targets: [
        .target(
            name: "SharedKit",
            dependencies: []
        ),
        .testTarget(
            name: "SharedKitTests",
            dependencies: ["SharedKit"]
        ),
    ]
)