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
        // Core library (내부 모듈)
        .library(
            name: "AsyncViewModelCore",
            targets: ["AsyncViewModelCore"]
        ),
        // 단일 Umbrella library (코어 + 매크로 통합)
        .library(
            name: "AsyncViewModel",
            targets: ["AsyncViewModel"]
        ),
    ],
    dependencies: [
        .package(path: "../AsyncViewModelMacros"),
    ],
    targets: [
        // Core 타겟 (내부 모듈)
        .target(
            name: "AsyncViewModelCore",
            dependencies: [],
            path: "Sources/Core"
        ),
        // Umbrella 타겟 (공개 모듈 - Core + Macros 통합)
        .target(
            name: "AsyncViewModel",
            dependencies: [
                "AsyncViewModelCore",
                .product(name: "AsyncViewModelMacros", package: "AsyncViewModelMacros"),
            ],
            path: "Sources/AsyncViewModel"
        ),
        .testTarget(
            name: "AsyncViewModelTests",
            dependencies: ["AsyncViewModelCore"],
            path: "Tests/AsyncViewModelTests"
        ),
    ]
)
