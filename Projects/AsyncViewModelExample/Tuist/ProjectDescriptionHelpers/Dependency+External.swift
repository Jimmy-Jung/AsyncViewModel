import ProjectDescription

// MARK: - External Dependencies

extension TargetDependency {
    public struct External {
        // Swift Syntax (for Macros)
        public static let swiftSyntax: TargetDependency = .external(name: "SwiftSyntax")
        public static let swiftSyntaxMacros: TargetDependency = .external(name: "SwiftSyntaxMacros")
        public static let swiftCompilerPlugin: TargetDependency = .external(name: "SwiftCompilerPlugin")
        public static let swiftSyntaxMacrosTestSupport: TargetDependency = .external(name: "SwiftSyntaxMacrosTestSupport")
        
        // Architecture
        public static let reactorKit: TargetDependency = .external(name: "ReactorKit")
        public static let composableArchitecture: TargetDependency = .external(name: "ComposableArchitecture")
        
        // Reactive
        public static let rxSwift: TargetDependency = .external(name: "RxSwift")
        public static let rxCocoa: TargetDependency = .external(name: "RxCocoa")
        
        // UI
        public static let pinLayout: TargetDependency = .external(name: "PinLayout")
    }
}
