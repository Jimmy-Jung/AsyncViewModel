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
        .package(path: "../AsyncViewModel"),
    ],
    targets: [
        // 매크로 선언 타겟 (사용자가 import하는 모듈)
        .target(
            name: "AsyncViewModelMacros",
            dependencies: [
                "AsyncViewModelMacrosImpl",
                .product(name: "AsyncViewModelCore", package: "AsyncViewModel"),
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

