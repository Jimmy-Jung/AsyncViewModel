// swift-tools-version: 5.10
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "CalculatorFeature",
    platforms: [
        .iOS(.v15),
    ],
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "CalculatorFeature",
            targets: ["CalculatorFeature"]
        ),
    ],
    dependencies: [
        .package(path: "../../Cores/DesignSystem"),
        .package(path: "../../Cores/LocalStorage"),
//        .package(path: "../../Cores/Network"),
        .package(path: "../../Cores/Foundation+Extension"),
        .package(path: "../../Cores/UI+Extension"),
        .package(path: "../../../../AsyncViewModel"),
        .package(url: "https://github.com/devxoul/Then", from: "3.0.0"),
        .package(url: "https://github.com/SnapKit/SnapKit.git", from: "5.7.1"),
        .package(url: "https://github.com/CombineCommunity/CombineCocoa.git", from: "0.2.1"),
        .package(url: "https://github.com/daltoniam/Starscream.git", from: "4.0.6"),
        .package(url: "https://github.com/layoutBox/FlexLayout.git", .upToNextMajor(from: "2.2.0")),
        .package(url: "https://github.com/layoutBox/PinLayout.git", .upToNextMajor(from: "1.10.5")),
        .package(url: "https://github.com/ReactorKit/ReactorKit.git", .upToNextMajor(from: .init(3, 2, 0))),
        .package(url: "https://github.com/ReactiveX/RxSwift.git", .upToNextMajor(from: .init(6, 6, 0))),
        .package(url: "https://github.com/pointfreeco/swift-composable-architecture.git", .upToNextMajor(from: .init(1, 21, 0))),
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .target(
            name: "CalculatorFeature",
            dependencies: [
                .product(name: "DesignSystem", package: "DesignSystem"),
                .product(name: "LocalStorage", package: "LocalStorage"),
//                .product(name: "Network", package: "Network"),
                .product(name: "Foundation+Extension", package: "Foundation+Extension"),
                .product(name: "UI+Extension", package: "UI+Extension"),
                "AsyncViewModel",
                "Then",
                "SnapKit",
                "CombineCocoa",
                "Starscream",
                "FlexLayout",
                "PinLayout",
                "ReactorKit",
                .product(name: "RxCocoa", package: "RxSwift"),
                .product(name: "ComposableArchitecture", package: "swift-composable-architecture"),
            ],
        ),
        .testTarget(
            name: "CalculatorFeatureTests",
            dependencies: ["CalculatorFeature"]
        ),
    ]
)
