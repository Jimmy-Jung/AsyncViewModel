import ProjectDescription

let project = Project(
    name: "AsyncViewModelExample",
    packages: [
        .local(path: "Modules/Features/CalculatorFeature"),
    ],
    targets: [
        .target(
            name: "AsyncViewModelExample",
            destinations: .iOS,
            product: .app,
            bundleId: "io.tuist.AsyncViewModelExample",
            deploymentTargets: .iOS("15.0"),
            infoPlist: .extendingDefault(
                with: [
                    "UILaunchScreen": [
                        "UIColorName": "",
                        "UIImageName": "",
                    ],
                ]
            ),
            sources: ["AsyncViewModelExample/Sources/**"],
            resources: ["AsyncViewModelExample/Resources/**"],
            dependencies: [
                .package(product: "CalculatorFeature"),
            ]
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
            dependencies: [.target(name: "AsyncViewModelExample")]
        ),
    ]
)
