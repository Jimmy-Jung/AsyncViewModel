// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription
import CompilerPluginSupport

let package = Package(
    name: "AsyncViewModelMacros",
    platforms: [
        .iOS(.v15),
        .macOS(.v12),
        .tvOS(.v15),
        .watchOS(.v8),
    ],
    products: [
        .library(
            name: "AsyncViewModelMacros",
            targets: ["AsyncViewModelMacros"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/swiftlang/swift-syntax.git", from: "600.0.0"),
        // Note: AsyncViewModelCore는 별도 패키지로 독립 관리
        // CI 환경에서는 로컬 path 의존성 사용 불가
    ],
    targets: [
        // 매크로 선언 타겟 (AsyncViewModelCore 없이 독립 실행)
        .target(
            name: "AsyncViewModelMacros",
            dependencies: [
                "AsyncViewModelMacrosImpl",
            ]
        ),
        // 매크로 구현 타겟 (컴파일러 플러그인)
        .macro(
            name: "AsyncViewModelMacrosImpl",
            dependencies: [
                .product(name: "SwiftSyntax", package: "swift-syntax"),
                .product(name: "SwiftSyntaxMacros", package: "swift-syntax"),
                .product(name: "SwiftCompilerPlugin", package: "swift-syntax"),
            ]
        ),
        // 테스트 타겟
        .testTarget(
            name: "AsyncViewModelMacrosTests",
            dependencies: [
                "AsyncViewModelMacros",
                "AsyncViewModelMacrosImpl",
                .product(name: "SwiftSyntaxMacrosTestSupport", package: "swift-syntax"),
            ]
        ),
    ]
)

