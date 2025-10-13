// swift-tools-version: 6.1
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "AsyncViewModel",
    platforms: [
        .iOS(.v15),
        .macOS(.v12),
        .tvOS(.v15),
        .watchOS(.v8),
    ],
    products: [
        .library(
            name: "AsyncViewModel",
            targets: ["AsyncViewModel"]
        ),
    ],
    dependencies: [],
    targets: [
        .target(
            name: "AsyncViewModel",
            dependencies: []
        ),
        .testTarget(
            name: "AsyncViewModelTests",
            dependencies: ["AsyncViewModel"]
        ),
    ]
)