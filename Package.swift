// swift-tools-version: 6.0
// Package.swift
// AsyncViewModel
//
// Created by jimmy on 2025-12-19.

import CompilerPluginSupport
import PackageDescription

let package = Package(
    name: "AsyncViewModel",
    platforms: [
        .iOS(.v15),
        .macOS(.v12),
        .tvOS(.v15),
        .watchOS(.v8)
    ],
    products: [
        // Core library
        .library(
            name: "AsyncViewModelCore",
            targets: ["AsyncViewModelCore"]
        ),
        // Umbrella library (Core + Macros 통합)
        .library(
            name: "AsyncViewModel",
            targets: ["AsyncViewModel"]
        ),
        // Macros library
        .library(
            name: "AsyncViewModelMacros",
            targets: ["AsyncViewModelMacros"]
        )
    ],
    dependencies: [
        .package(url: "https://github.com/swiftlang/swift-syntax.git", from: "600.0.0"),
        .package(url: "https://github.com/apple/swift-docc-plugin", from: "1.0.0")
    ],
    targets: [
        // MARK: - Core AsyncViewModel Target

        .target(
            name: "AsyncViewModelCore",
            dependencies: [],
            path: "Projects/AsyncViewModel/Sources",
            exclude: ["AsyncViewModel"]
        ),

        // MARK: - Umbrella Target (Core + Macros)

        .target(
            name: "AsyncViewModel",
            dependencies: [
                "AsyncViewModelCore",
                "AsyncViewModelMacros"
            ],
            path: "Projects/AsyncViewModel/Sources/AsyncViewModel"
        ),

        // MARK: - AsyncViewModel Tests

        .testTarget(
            name: "AsyncViewModelTests",
            dependencies: ["AsyncViewModelCore"],
            path: "Projects/AsyncViewModel/Tests"
        ),

        // MARK: - AsyncViewModelMacros Target

        .target(
            name: "AsyncViewModelMacros",
            dependencies: [
                "AsyncViewModelMacrosImpl",
                "AsyncViewModelCore"
            ],
            path: "Projects/AsyncViewModelMacros/Sources/AsyncViewModelMacros"
        ),

        // MARK: - Macro Implementation (Compiler Plugin)

        .macro(
            name: "AsyncViewModelMacrosImpl",
            dependencies: [
                .product(name: "SwiftSyntax", package: "swift-syntax"),
                .product(name: "SwiftSyntaxMacros", package: "swift-syntax"),
                .product(name: "SwiftCompilerPlugin", package: "swift-syntax")
            ],
            path: "Projects/AsyncViewModelMacros/Sources/AsyncViewModelMacrosImpl"
        ),

        // MARK: - AsyncViewModelMacros Tests (macOS only)

        .testTarget(
            name: "AsyncViewModelMacrosTests",
            dependencies: [
                "AsyncViewModelMacros",
                "AsyncViewModelMacrosImpl",
                .product(name: "SwiftSyntaxMacrosTestSupport", package: "swift-syntax")
            ],
            path: "Projects/AsyncViewModelMacros/Tests",
            swiftSettings: [
                // 매크로 테스트는 macOS에서만 실행
                .define("MACRO_TESTING_ENABLED", .when(platforms: [.macOS]))
            ]
        )
    ]
)
