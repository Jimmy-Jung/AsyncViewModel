import ProjectDescription

let workspace = Workspace(
    name: "AsyncViewModelExample",
    projects: [
        ".",
    ],
    schemes: [
        .scheme(
            name: "AsyncViewModelExample-All",
            shared: true,
            buildAction: .buildAction(
                targets: [
                    .project(path: ".", target: "AsyncViewModelExample"),
                ]
            ),
            testAction: .targets(
                [
                    .testableTarget(target: .project(path: ".", target: "AsyncViewModelExampleTests")),
                ],
                configuration: .debug,
                options: .options(coverage: true)
            ),
            runAction: .runAction(
                configuration: .debug,
                executable: .project(path: ".", target: "AsyncViewModelExample")
            )
        )
    ]
)
