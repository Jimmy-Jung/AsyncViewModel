import ProjectDescription

// MARK: - Scheme Templates

extension Scheme {
    /// 앱 스킴 생성 (빌드, 테스트, 실행 포함)
    public static func appScheme(
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
    
    /// 모듈 스킴 생성 (테스트만 포함)
    public static func moduleScheme(
        name: String,
        hasTests: Bool = true
    ) -> Scheme {
        var testTargets: [TestableTarget] = []
        if hasTests {
            testTargets.append(.testableTarget(target: .target("\(name)Tests")))
        }
        
        return Scheme.scheme(
            name: name,
            shared: true,
            buildAction: .buildAction(
                targets: [.target(name)]
            ),
            testAction: hasTests ? .targets(
                testTargets,
                configuration: .debug,
                options: .options(
                    coverage: true,
                    codeCoverageTargets: [.target(name)]
                )
            ) : nil
        )
    }
}
