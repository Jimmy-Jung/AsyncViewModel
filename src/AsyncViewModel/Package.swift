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
        // AsyncViewModel 라이브러리 (AsyncViewModelCore를 노출)
        .library(
            name: "AsyncViewModel",
            targets: ["AsyncViewModelCore"]
        ),
    ],
    dependencies: [
        // Note: AsyncViewModelMacros는 별도 패키지로 독립 관리
        // 사용자는 필요에 따라 두 패키지를 모두 의존성에 추가
    ],
    targets: [
        // Core 타겟 (AsyncViewModel 제품명으로 노출)
        .target(
            name: "AsyncViewModelCore",
            dependencies: [],
            path: "Sources"
        ),
        .testTarget(
            name: "AsyncViewModelTests",
            dependencies: ["AsyncViewModelCore"],
            path: "Tests/AsyncViewModelTests"
        ),
    ]
)
