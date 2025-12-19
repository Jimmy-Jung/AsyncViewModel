import ProjectDescription

// MARK: - Settings Templates

extension Settings {
    /// AsyncViewModel 라이브러리용 설정 (Swift 6.1)
    public static func asyncViewModelSettings() -> Settings {
        return .settings(
            base: [
                "SWIFT_VERSION": "6.1",
                "ENABLE_USER_SCRIPT_SANDBOXING": "YES",
                "SWIFT_STRICT_CONCURRENCY": "complete",
                "ENABLE_TESTABILITY": "YES",
            ],
            configurations: [
                .debug(name: "Debug"),
                .release(name: "Release"),
            ],
            defaultSettings: .recommended
        )
    }
    
    /// 기본 타겟 설정 (Swift 5.9)
    public static func targetSettings() -> Settings {
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
    public static func appSettings() -> Settings {
        return .settings(
            base: [
                "SWIFT_VERSION": "5.9",
                "ENABLE_USER_SCRIPT_SANDBOXING": "NO",
                "DEVELOPMENT_TEAM": "",
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
