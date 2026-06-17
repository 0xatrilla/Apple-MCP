// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "AppleAppsMCP",
    platforms: [.macOS(.v26)],
    products: [
        .executable(name: "AppleAppsControl", targets: ["AppleAppsControl"]),
        .executable(name: "AppleAppsHelper", targets: ["AppleAppsHelper"])
    ],
    dependencies: [
        .package(url: "https://github.com/sparkle-project/Sparkle", from: "2.6.0")
    ],
    targets: [
        .executableTarget(
            name: "AppleAppsControl",
            dependencies: [
                .product(name: "Sparkle", package: "Sparkle")
            ],
            path: "Swift/App",
            resources: [.copy("Resources")],
            linkerSettings: [
                // The packaging script embeds Sparkle.framework in Contents/Frameworks;
                // this rpath lets the executable find it at runtime inside the .app.
                .unsafeFlags(["-Xlinker", "-rpath", "-Xlinker", "@executable_path/../Frameworks"])
            ]
        ),
        .executableTarget(
            name: "AppleAppsHelper",
            path: "Swift/Helper"
        )
    ]
)
