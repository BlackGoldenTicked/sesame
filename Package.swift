// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "TextLaunch",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(name: "TextLaunch", targets: ["TextLaunch"])
    ],
    targets: [
        .executableTarget(
            name: "TextLaunch",
            path: "Sources/TextLaunch"
        )
    ]
)
