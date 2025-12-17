import ProjectDescription
import ProjectDescriptionHelpers

let project = Project(
    name: "AsyncViewModelMacros",
    targets: [
        // Macro Implementation (Compiler Plugin) - macOS only
        .target(
            name: "AsyncViewModelMacrosImpl",
            destinations: [.mac],
            product: .macro,
            bundleId: "io.github.asyncviewmodel.macros.impl",
            deploymentTargets: .macOS("12.0"),
            sources: ["Sources/AsyncViewModelMacrosImpl/**"],
            dependencies: [
                .External.swiftSyntax,
                .External.swiftSyntaxMacros,
                .External.swiftCompilerPlugin,
            ],
            settings: .targetSettings()
        ),
        
        // Macro Declaration (User-facing module)
        .target(
            name: "AsyncViewModelMacros",
            destinations: [.iPhone, .iPad, .mac],
            product: .framework,
            bundleId: "io.github.asyncviewmodel.macros",
            deploymentTargets: .multiplatform(iOS: "15.0", macOS: "12.0"),
            sources: ["Sources/AsyncViewModelMacros/**"],
            dependencies: [
                .target(name: "AsyncViewModelMacrosImpl"),
                .project(target: "AsyncViewModelKit", path: "../AsyncViewModelKit"),
            ],
            settings: .targetSettings()
        ),
        
        // Tests - macOS for macro testing
        .target(
            name: "AsyncViewModelMacrosTests",
            destinations: [.mac],
            product: .unitTests,
            bundleId: "io.github.asyncviewmodel.macros.tests",
            deploymentTargets: .macOS("12.0"),
            sources: ["Tests/AsyncViewModelMacrosTests/**"],
            dependencies: [
                .target(name: "AsyncViewModelMacros"),
                .target(name: "AsyncViewModelMacrosImpl"),
                .External.swiftSyntaxMacrosTestSupport,
            ],
            settings: .targetSettings()
        ),
    ],
    schemes: [
        .scheme(
            name: "AsyncViewModelMacros",
            shared: true,
            buildAction: .buildAction(
                targets: [
                    .target("AsyncViewModelMacrosImpl"),
                    .target("AsyncViewModelMacros")
                ]
            ),
            testAction: .targets(
                [.testableTarget(target: .target("AsyncViewModelMacrosTests"))],
                configuration: .debug,
                options: .options(
                    coverage: true,
                    codeCoverageTargets: [
                        .target("AsyncViewModelMacros"),
                        .target("AsyncViewModelMacrosImpl")
                    ]
                )
            )
        )
    ]
)
