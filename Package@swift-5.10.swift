// swift-tools-version: 5.10
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
        .package(url: "https://github.com/swiftlang/indexstore-db.git", revision: "swift-6.0.2-RELEASE"),
        .package(url: "https://github.com/swiftlang/swift-tools-support-core.git", exact: Version("0.7.1")),
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages this package depends on.
        .target(
            name: "IndexStore",
            dependencies: [
                .product(name: "SwiftToolsSupport-auto", package: "swift-tools-support-core"),
                .product(name: "IndexStoreDB", package: "indexstore-db"),
            ],
            resources: [
                .copy("Resources/PrivacyInfo.xcprivacy")
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

// Supplementary
package.dependencies.append(contentsOf: [
    .package(url: "https://github.com/SwiftPackageIndex/SPIManifest.git", from: "0.12.0"),
])
