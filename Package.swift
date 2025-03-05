// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "MusicDashboard",
    platforms: [
        .iOS(.v16)
    ],
    products: [
        .library(
            name: "MusicDashboard",
            targets: ["MusicDashboard"]
        ),
    ],
    dependencies: [],
    targets: [
        .target(
            name: "MusicDashboard",
            dependencies: [],
            path: "Sources"
        )
    ]
)
