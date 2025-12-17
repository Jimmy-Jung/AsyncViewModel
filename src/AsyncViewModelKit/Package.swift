// swift-tools-version: 6.1
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "AsyncViewModelKit",
    platforms: [
        .iOS(.v15),
        .macOS(.v12),
        .tvOS(.v15),
        .watchOS(.v8),
    ],
    products: [
        .library(
            name: "AsyncViewModelKit",
            targets: ["AsyncViewModelKit"]
        ),
    ],
    dependencies: [],
    targets: [
        .target(
            name: "AsyncViewModelKit",
            dependencies: [],
            path: "Sources/AsyncViewModel"
        ),
        .testTarget(
            name: "AsyncViewModelKitTests",
            dependencies: ["AsyncViewModelKit"],
            path: "Tests/AsyncViewModelTests"
        ),
    ]
)