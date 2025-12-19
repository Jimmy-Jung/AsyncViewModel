// swift-tools-version: 6.0
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
        // Note: AsyncViewModelMacros는 별도 패키지로 독립 관리
        // 사용자는 필요에 따라 두 패키지를 모두 의존성에 추가
    ],
    targets: [
        // Core 타겟 (내부 모듈)
        .target(
            name: "AsyncViewModelCore",
            dependencies: [],
            path: "Sources",
            exclude: ["AsyncViewModel"]
        ),
        // Umbrella 타겟 (공개 모듈 - Core만 포함, Macros는 별도 패키지)
        .target(
            name: "AsyncViewModel",
            dependencies: [
                "AsyncViewModelCore",
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
