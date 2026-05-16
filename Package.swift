// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "Sesame",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(name: "Sesame", targets: ["Sesame"])
    ],
    targets: [
        .executableTarget(
            name: "Sesame",
            path: "Sources/Sesame",
            resources: [
                .process("Resources")
            ]
        )
    ]
)
