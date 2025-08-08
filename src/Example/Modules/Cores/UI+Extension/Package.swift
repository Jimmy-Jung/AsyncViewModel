// swift-tools-version: 5.10
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "UI+Extension",
    platforms: [
        .iOS(.v15),
    ],
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "UI+Extension",
            targets: ["UI+Extension"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/SnapKit/SnapKit.git", from: "5.7.0"),
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .target(
            name: "UI+Extension",
            dependencies: [
                .product(name: "SnapKit", package: "SnapKit"),
            ]
        ),
        .testTarget(
            name: "UI+ExtensionTests",
            dependencies: ["UI+Extension"]
        ),
    ]
)
