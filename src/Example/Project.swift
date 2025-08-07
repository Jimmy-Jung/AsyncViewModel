import ProjectDescription

let project = Project(
    name: "AsyncViewModelExample",
    targets: [
        .target(
            name: "AsyncViewModelExample",
            destinations: .iOS,
            product: .app,
            bundleId: "io.tuist.AsyncViewModelExample",
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
            dependencies: []
        ),
        .target(
            name: "AsyncViewModelExampleTests",
            destinations: .iOS,
            product: .unitTests,
            bundleId: "io.tuist.AsyncViewModelExampleTests",
            infoPlist: .default,
            sources: ["AsyncViewModelExample/Tests/**"],
            resources: [],
            dependencies: [.target(name: "AsyncViewModelExample")]
        ),
    ]
)
