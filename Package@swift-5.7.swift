// swift-tools-version: 5.7
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "IndexStore",
    platforms: [.macOS(.v10_13)],
    products: [
        // Products define the executables and libraries a package produces, and make them visible to other packages.
        .library(
            name: "IndexStore",
            targets: ["IndexStore"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-log.git", from: "1.0.0"),
        .package(url: "https://github.com/apple/indexstore-db.git", branch: "release/5.9"),
        .package(url: "https://github.com/apple/swift-tools-support-core.git", exact: Version("0.4.0")),
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages this package depends on.
        .target(
            name: "IndexStore",
            dependencies: [
                .product(name: "SwiftToolsSupport-auto", package: "swift-tools-support-core"),
                .product(name: "IndexStoreDB", package: "indexstore-db"),
                .product(name: "Logging", package: "swift-log")
            ]
        ),
        .testTarget(
            name: "IndexStoreTests",
            dependencies: [
                "IndexStore",
            ],
            resources: [
                .copy("Configurations"),
            ]
        ),
    ]
)
