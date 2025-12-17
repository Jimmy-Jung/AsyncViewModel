// swift-tools-version: 6.0
import PackageDescription

#if TUIST
    import struct ProjectDescription.PackageSettings

    let packageSettings = PackageSettings(
        // 외부 의존성 타입 설정
        // .framework: 동적 프레임워크 (개발 시 빠른 빌드)
        // .staticFramework: 정적 프레임워크 (릴리즈 시 최적화)
        productTypes: [
            "AsyncViewModelKit": .framework,
            "ReactorKit": .framework,
            "RxSwift": .framework,
            "RxCocoa": .framework,
            "ComposableArchitecture": .framework,
            "PinLayout": .framework,
        ],
        // 매크로 타겟은 자동으로 처리되므로 baseSettings에서 제외
        baseSettings: .settings(
            configurations: [
                .debug(name: "Debug", settings: [:]),
                .release(name: "Release", settings: [:])
            ]
        )
    )
#endif

let package = Package(
    name: "AsyncViewModelExample",
    dependencies: [
        // Local Packages
        .package(path: "../../AsyncViewModelKit"),
        .package(path: "../../AsyncViewModelMacros"),
        
        // Architecture
        .package(
            url: "https://github.com/ReactorKit/ReactorKit.git",
            .upToNextMajor(from: "3.2.0")
        ),
        .package(
            url: "https://github.com/pointfreeco/swift-composable-architecture.git",
            .upToNextMajor(from: "1.21.0")
        ),
        
        // Reactive
        .package(
            url: "https://github.com/ReactiveX/RxSwift.git",
            .upToNextMajor(from: "6.6.0")
        ),
        
        // UI
        .package(
            url: "https://github.com/layoutBox/PinLayout.git",
            .upToNextMajor(from: "1.10.5")
        ),
    ]
)
