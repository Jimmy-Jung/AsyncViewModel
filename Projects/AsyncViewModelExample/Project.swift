import ProjectDescription

// MARK: - External Dependencies

extension TargetDependency {
    enum External {
        // Architecture
        static let reactorKit: TargetDependency = .external(name: "ReactorKit")
        static let composableArchitecture: TargetDependency = .external(name: "ComposableArchitecture")

        // Reactive
        static let rxSwift: TargetDependency = .external(name: "RxSwift")
        static let rxCocoa: TargetDependency = .external(name: "RxCocoa")

        // UI
        static let pinLayout: TargetDependency = .external(name: "PinLayout")
    }
}

// MARK: - Settings Templates

extension Settings {
    /// 기본 타겟 설정 (Swift 5.9)
    static func targetSettings() -> Settings {
        return .settings(
            base: [
                "SWIFT_VERSION": "5.9",
                "ENABLE_USER_SCRIPT_SANDBOXING": "NO",
                "ENABLE_TESTABILITY": "YES",
            ],
            configurations: [
                .debug(name: "Debug"),
                .release(name: "Release"),
            ],
            defaultSettings: .recommended
        )
    }

    /// 앱 타겟 설정 (Swift 5.9)
    static func appSettings() -> Settings {
        return .settings(
            base: [
                "SWIFT_VERSION": "5.9",
                "ENABLE_USER_SCRIPT_SANDBOXING": "NO",
                "CODE_SIGN_STYLE": "Automatic",
                "ENABLE_TESTABILITY": "YES",
            ],
            configurations: [
                .debug(
                    name: "Debug",
                    settings: [
                        "SWIFT_OPTIMIZATION_LEVEL": "-Onone",
                        "GCC_OPTIMIZATION_LEVEL": "0",
                    ]
                ),
                .release(
                    name: "Release",
                    settings: [
                        "SWIFT_OPTIMIZATION_LEVEL": "-O",
                        "SWIFT_COMPILATION_MODE": "wholemodule",
                    ]
                ),
            ],
            defaultSettings: .recommended
        )
    }
}

// MARK: - Scheme Templates

extension Scheme {
    /// 앱 스킴 생성 (빌드, 테스트, 실행 포함)
    static func appScheme(
        name: String,
        testTargets: [TestableTarget] = []
    ) -> Scheme {
        return Scheme.scheme(
            name: name,
            shared: true,
            buildAction: .buildAction(
                targets: [.target(name)],
                preActions: [],
                postActions: []
            ),
            testAction: .targets(
                testTargets,
                configuration: .debug,
                options: .options(
                    coverage: true,
                    codeCoverageTargets: [.target(name)]
                )
            ),
            runAction: .runAction(
                configuration: .debug,
                executable: .target(name)
            ),
            archiveAction: .archiveAction(
                configuration: .release
            ),
            profileAction: .profileAction(
                configuration: .release,
                executable: .target(name)
            ),
            analyzeAction: .analyzeAction(
                configuration: .debug
            )
        )
    }
}

// MARK: - Project

let project = Project(
    name: "AsyncViewModelExample",
    targets: [
        .target(
            name: "AsyncViewModelExample",
            destinations: .iOS,
            product: .app,
            bundleId: "io.tuist.AsyncViewModelExample",
            deploymentTargets: .iOS("15.0"),
            infoPlist: .extendingDefault(
                with: [
                    "UILaunchStoryboardName": "LaunchScreen",
                    "UIApplicationSceneManifest": [
                        "UIApplicationSupportsMultipleScenes": false,
                        "UISceneConfigurations": [
                            "UIWindowSceneSessionRoleApplication": [
                                [
                                    "UISceneConfigurationName": "Default Configuration",
                                    "UISceneDelegateClassName": "$(PRODUCT_MODULE_NAME).SceneDelegate",
                                ],
                            ],
                        ],
                    ],
                ]
            ),
            sources: ["AsyncViewModelExample/Sources/**"],
            resources: ["AsyncViewModelExample/Resources/**"],
            dependencies: [
                // AsyncViewModel (로컬 SPM 패키지)
                .external(name: "AsyncViewModel"),

                // TraceKit (외부 SPM 패키지)
                .external(name: "TraceKit"),

                // External Dependencies
                .External.reactorKit,
                .External.rxSwift,
                .External.rxCocoa,
                .External.composableArchitecture,
                .External.pinLayout,
            ],
            settings: .appSettings()
        ),
        .target(
            name: "AsyncViewModelExampleTests",
            destinations: .iOS,
            product: .unitTests,
            bundleId: "io.tuist.AsyncViewModelExampleTests",
            deploymentTargets: .iOS("15.0"),
            infoPlist: .default,
            sources: ["AsyncViewModelExample/Tests/**"],
            resources: [],
            dependencies: [
                .target(name: "AsyncViewModelExample"),
            ],
            settings: .targetSettings()
        ),
    ],
    schemes: [
        .appScheme(
            name: "AsyncViewModelExample",
            testTargets: [
                .testableTarget(target: .target("AsyncViewModelExampleTests")),
            ]
        ),
    ]
)
