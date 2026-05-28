// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "AppleAppsMCP",
    platforms: [.macOS(.v14)],
    products: [
        .executable(name: "AppleAppsControl", targets: ["AppleAppsControl"]),
        .executable(name: "AppleAppsHelper", targets: ["AppleAppsHelper"])
    ],
    targets: [
        .executableTarget(
            name: "AppleAppsControl",
            path: "Swift/App",
            resources: [.copy("Resources")]
        ),
        .executableTarget(
            name: "AppleAppsHelper",
            path: "Swift/Helper"
        )
    ]
)
