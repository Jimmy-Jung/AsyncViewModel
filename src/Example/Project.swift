import ProjectDescription
import ProjectDescriptionHelpers

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
                                ]
                            ]
                        ]
                    ],
                ]
            ),
            sources: ["AsyncViewModelExample/Sources/**"],
            resources: ["AsyncViewModelExample/Resources/**"],
            dependencies: [
                // AsyncViewModel (로컬 SPM 패키지)
                .external(name: "AsyncViewModel"),
                
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
                .target(name: "AsyncViewModelExample")
            ],
            settings: .targetSettings()
        ),
    ],
    schemes: [
        .appScheme(
            name: "AsyncViewModelExample",
            testTargets: [
                .testableTarget(target: .target("AsyncViewModelExampleTests"))
            ]
        )
    ]
)
