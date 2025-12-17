import ProjectDescription
import ProjectDescriptionHelpers

let project = Project(
    name: "AsyncViewModelKit",
    targets: [
        .target(
            name: "AsyncViewModelKit",
            destinations: [.iPhone, .iPad, .mac],
            product: .framework,
            bundleId: "io.github.asyncviewmodel.kit",
            deploymentTargets: .multiplatform(iOS: "15.0", macOS: "12.0"),
            sources: ["Sources/AsyncViewModel/**"],
            settings: .asyncViewModelSettings()  // Swift 6.1
        ),
        .target(
            name: "AsyncViewModelKitTests",
            destinations: [.iPhone, .iPad, .mac],
            product: .unitTests,
            bundleId: "io.github.asyncviewmodel.kit.tests",
            deploymentTargets: .multiplatform(iOS: "15.0", macOS: "12.0"),
            sources: ["Tests/AsyncViewModelTests/**"],
            dependencies: [
                .target(name: "AsyncViewModelKit")
            ],
            settings: .asyncViewModelSettings()  // Swift 6.1
        ),
    ],
    schemes: [
        .scheme(
            name: "AsyncViewModelKit",
            shared: true,
            buildAction: .buildAction(
                targets: [.target("AsyncViewModelKit")]
            ),
            testAction: .targets(
                [.testableTarget(target: .target("AsyncViewModelKitTests"))],
                configuration: .debug,
                options: .options(
                    coverage: true,
                    codeCoverageTargets: [.target("AsyncViewModelKit")]
                )
            )
        )
    ]
)
