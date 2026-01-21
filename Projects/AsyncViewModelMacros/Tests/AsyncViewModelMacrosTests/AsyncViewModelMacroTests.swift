//
//  AsyncViewModelMacroTests.swift
//  AsyncViewModelMacros
//
//  Created by 정준영 on 2025/12/17.
//

#if os(macOS) // 매크로 테스트는 macOS에서만 실행

    import SwiftSyntax
    import SwiftSyntaxMacros
    import SwiftSyntaxMacrosTestSupport
    import Testing

    @testable import AsyncViewModelMacrosImpl

    // MARK: - AsyncViewModelMacroTests

    @Suite("AsyncViewModel Macro Tests")
    struct AsyncViewModelMacroTests {
        let testMacros: [String: Macro.Type] = [
            "AsyncViewModel": AsyncViewModelMacroImpl.self
        ]

        // MARK: - Basic Expansion Tests

        @Test("기본 매크로 확장 - 모든 프로퍼티 생성")
        func basicExpansion() {
            assertMacroExpansion(
                """
                @AsyncViewModel
                public final class TestViewModel: ObservableObject {
                    public enum Input: Sendable { case test }
                    public enum Action: Equatable & Sendable { case test }
                    public struct State: Equatable & Sendable { }
                    public enum CancelID: Hashable & Sendable { case test }
                    
                    @Published public var state: State = State()
                }
                """,
                expandedSource: """
                public final class TestViewModel: ObservableObject {
                    @MainActor
                    public enum Input: Sendable { case test }
                    @MainActor
                    public enum Action: Equatable & Sendable { case test }
                    @MainActor
                    public struct State: Equatable & Sendable { }
                    @MainActor
                    public enum CancelID: Hashable & Sendable { case test }
                    
                    @MainActor
                    @Published public var state: State = State()

                    public var tasks: [CancelID: Task<Void, Never>] = [:]

                    public var effectQueue: [AsyncEffect<Action, CancelID>] = []

                    public var isProcessingEffects: Bool = false

                    public var actionObserver: ((Action) -> Void)? = nil

                    public var stateChangeObserver: ((State, State) -> Void)? = nil

                    public var effectObserver: ((AsyncEffect<Action, CancelID>) -> Void)? = nil

                    public var performanceObserver: ((String, TimeInterval) -> Void)? = nil

                    public var timer: any AsyncTimer = SystemTimer()

                    public let loggingConfig: ViewModelLoggingConfig = ViewModelLoggingConfig(mode: .enabled, loggerMode: .shared, customOptions: nil)
                }

                @MainActor
                extension TestViewModel: AsyncViewModelProtocol {
                }
                """,
                macros: testMacros
            )
        }

        // MARK: - Logging Mode Tests

        @Test("로깅 비활성화 - logging: .disabled")
        func loggingDisabled() {
            assertMacroExpansion(
                """
                @AsyncViewModel(logging: .disabled)
                public final class TestViewModel: ObservableObject {
                    public enum Input: Sendable { case test }
                    public enum Action: Equatable & Sendable { case test }
                    public struct State: Equatable & Sendable { }
                    public enum CancelID: Hashable & Sendable { case test }
                    
                    @Published public var state: State = State()
                }
                """,
                expandedSource: """
                public final class TestViewModel: ObservableObject {
                    @MainActor
                    public enum Input: Sendable { case test }
                    @MainActor
                    public enum Action: Equatable & Sendable { case test }
                    @MainActor
                    public struct State: Equatable & Sendable { }
                    @MainActor
                    public enum CancelID: Hashable & Sendable { case test }
                    
                    @MainActor
                    @Published public var state: State = State()

                    public var tasks: [CancelID: Task<Void, Never>] = [:]

                    public var effectQueue: [AsyncEffect<Action, CancelID>] = []

                    public var isProcessingEffects: Bool = false

                    public var actionObserver: ((Action) -> Void)? = nil

                    public var stateChangeObserver: ((State, State) -> Void)? = nil

                    public var effectObserver: ((AsyncEffect<Action, CancelID>) -> Void)? = nil

                    public var performanceObserver: ((String, TimeInterval) -> Void)? = nil

                    public var timer: any AsyncTimer = SystemTimer()

                    public let loggingConfig: ViewModelLoggingConfig = ViewModelLoggingConfig(mode: .disabled, loggerMode: .shared, customOptions: nil)
                }

                @MainActor
                extension TestViewModel: AsyncViewModelProtocol {
                }
                """,
                macros: testMacros
            )
        }

        @Test("최소 로깅 - logging: .minimal")
        func loggingMinimal() {
            assertMacroExpansion(
                """
                @AsyncViewModel(logging: .minimal)
                public final class TestViewModel: ObservableObject {
                    public enum Input: Sendable { case test }
                    public enum Action: Equatable & Sendable { case test }
                    public struct State: Equatable & Sendable { }
                    public enum CancelID: Hashable & Sendable { case test }
                    
                    @Published public var state: State = State()
                }
                """,
                expandedSource: """
                public final class TestViewModel: ObservableObject {
                    @MainActor
                    public enum Input: Sendable { case test }
                    @MainActor
                    public enum Action: Equatable & Sendable { case test }
                    @MainActor
                    public struct State: Equatable & Sendable { }
                    @MainActor
                    public enum CancelID: Hashable & Sendable { case test }
                    
                    @MainActor
                    @Published public var state: State = State()

                    public var tasks: [CancelID: Task<Void, Never>] = [:]

                    public var effectQueue: [AsyncEffect<Action, CancelID>] = []

                    public var isProcessingEffects: Bool = false

                    public var actionObserver: ((Action) -> Void)? = nil

                    public var stateChangeObserver: ((State, State) -> Void)? = nil

                    public var effectObserver: ((AsyncEffect<Action, CancelID>) -> Void)? = nil

                    public var performanceObserver: ((String, TimeInterval) -> Void)? = nil

                    public var timer: any AsyncTimer = SystemTimer()

                    public let loggingConfig: ViewModelLoggingConfig = ViewModelLoggingConfig(mode: .minimal, loggerMode: .shared, customOptions: nil)
                }

                @MainActor
                extension TestViewModel: AsyncViewModelProtocol {
                }
                """,
                macros: testMacros
            )
        }

        @Test("특정 카테고리만 로깅 - logging: .only(...)")
        func loggingOnly() {
            assertMacroExpansion(
                """
                @AsyncViewModel(logging: .only(.action, .error))
                public final class TestViewModel: ObservableObject {
                    public enum Input: Sendable { case test }
                    public enum Action: Equatable & Sendable { case test }
                    public struct State: Equatable & Sendable { }
                    public enum CancelID: Hashable & Sendable { case test }
                    
                    @Published public var state: State = State()
                }
                """,
                expandedSource: """
                public final class TestViewModel: ObservableObject {
                    @MainActor
                    public enum Input: Sendable { case test }
                    @MainActor
                    public enum Action: Equatable & Sendable { case test }
                    @MainActor
                    public struct State: Equatable & Sendable { }
                    @MainActor
                    public enum CancelID: Hashable & Sendable { case test }
                    
                    @MainActor
                    @Published public var state: State = State()

                    public var tasks: [CancelID: Task<Void, Never>] = [:]

                    public var effectQueue: [AsyncEffect<Action, CancelID>] = []

                    public var isProcessingEffects: Bool = false

                    public var actionObserver: ((Action) -> Void)? = nil

                    public var stateChangeObserver: ((State, State) -> Void)? = nil

                    public var effectObserver: ((AsyncEffect<Action, CancelID>) -> Void)? = nil

                    public var performanceObserver: ((String, TimeInterval) -> Void)? = nil

                    public var timer: any AsyncTimer = SystemTimer()

                    public let loggingConfig: ViewModelLoggingConfig = ViewModelLoggingConfig(mode: .only(Set([.action, .error])), loggerMode: .shared, customOptions: nil)
                }

                @MainActor
                extension TestViewModel: AsyncViewModelProtocol {
                }
                """,
                macros: testMacros
            )
        }

        @Test("특정 카테고리 제외 - logging: .excluding(...)")
        func loggingExcluding() {
            assertMacroExpansion(
                """
                @AsyncViewModel(logging: .excluding(.stateChange))
                public final class TestViewModel: ObservableObject {
                    public enum Input: Sendable { case test }
                    public enum Action: Equatable & Sendable { case test }
                    public struct State: Equatable & Sendable { }
                    public enum CancelID: Hashable & Sendable { case test }
                    
                    @Published public var state: State = State()
                }
                """,
                expandedSource: """
                public final class TestViewModel: ObservableObject {
                    @MainActor
                    public enum Input: Sendable { case test }
                    @MainActor
                    public enum Action: Equatable & Sendable { case test }
                    @MainActor
                    public struct State: Equatable & Sendable { }
                    @MainActor
                    public enum CancelID: Hashable & Sendable { case test }
                    
                    @MainActor
                    @Published public var state: State = State()

                    public var tasks: [CancelID: Task<Void, Never>] = [:]

                    public var effectQueue: [AsyncEffect<Action, CancelID>] = []

                    public var isProcessingEffects: Bool = false

                    public var actionObserver: ((Action) -> Void)? = nil

                    public var stateChangeObserver: ((State, State) -> Void)? = nil

                    public var effectObserver: ((AsyncEffect<Action, CancelID>) -> Void)? = nil

                    public var performanceObserver: ((String, TimeInterval) -> Void)? = nil

                    public var timer: any AsyncTimer = SystemTimer()

                    public let loggingConfig: ViewModelLoggingConfig = ViewModelLoggingConfig(mode: .excluding(Set([.stateChange])), loggerMode: .shared, customOptions: nil)
                }

                @MainActor
                extension TestViewModel: AsyncViewModelProtocol {
                }
                """,
                macros: testMacros
            )
        }

        // MARK: - Logger Mode Tests

        @Test("커스텀 Logger - logger: .custom(...)")
        func customLogger() {
            assertMacroExpansion(
                """
                @AsyncViewModel(logger: .custom(DebugLogger()))
                public final class TestViewModel: ObservableObject {
                    public enum Input: Sendable { case test }
                    public enum Action: Equatable & Sendable { case test }
                    public struct State: Equatable & Sendable { }
                    public enum CancelID: Hashable & Sendable { case test }
                    
                    @Published public var state: State = State()
                }
                """,
                expandedSource: """
                public final class TestViewModel: ObservableObject {
                    @MainActor
                    public enum Input: Sendable { case test }
                    @MainActor
                    public enum Action: Equatable & Sendable { case test }
                    @MainActor
                    public struct State: Equatable & Sendable { }
                    @MainActor
                    public enum CancelID: Hashable & Sendable { case test }
                    
                    @MainActor
                    @Published public var state: State = State()

                    public var tasks: [CancelID: Task<Void, Never>] = [:]

                    public var effectQueue: [AsyncEffect<Action, CancelID>] = []

                    public var isProcessingEffects: Bool = false

                    public var actionObserver: ((Action) -> Void)? = nil

                    public var stateChangeObserver: ((State, State) -> Void)? = nil

                    public var effectObserver: ((AsyncEffect<Action, CancelID>) -> Void)? = nil

                    public var performanceObserver: ((String, TimeInterval) -> Void)? = nil

                    public var timer: any AsyncTimer = SystemTimer()

                    public let loggingConfig: ViewModelLoggingConfig = ViewModelLoggingConfig(mode: .enabled, loggerMode: .custom(DebugLogger()), customOptions: nil)
                }

                @MainActor
                extension TestViewModel: AsyncViewModelProtocol {
                }
                """,
                macros: testMacros
            )
        }

        @Test("로깅 모드와 Logger 조합")
        func loggingModeWithLogger() {
            assertMacroExpansion(
                """
                @AsyncViewModel(logging: .minimal, logger: .custom(TraceLogger()))
                public final class TestViewModel: ObservableObject {
                    public enum Input: Sendable { case test }
                    public enum Action: Equatable & Sendable { case test }
                    public struct State: Equatable & Sendable { }
                    public enum CancelID: Hashable & Sendable { case test }
                    
                    @Published public var state: State = State()
                }
                """,
                expandedSource: """
                public final class TestViewModel: ObservableObject {
                    @MainActor
                    public enum Input: Sendable { case test }
                    @MainActor
                    public enum Action: Equatable & Sendable { case test }
                    @MainActor
                    public struct State: Equatable & Sendable { }
                    @MainActor
                    public enum CancelID: Hashable & Sendable { case test }
                    
                    @MainActor
                    @Published public var state: State = State()

                    public var tasks: [CancelID: Task<Void, Never>] = [:]

                    public var effectQueue: [AsyncEffect<Action, CancelID>] = []

                    public var isProcessingEffects: Bool = false

                    public var actionObserver: ((Action) -> Void)? = nil

                    public var stateChangeObserver: ((State, State) -> Void)? = nil

                    public var effectObserver: ((AsyncEffect<Action, CancelID>) -> Void)? = nil

                    public var performanceObserver: ((String, TimeInterval) -> Void)? = nil

                    public var timer: any AsyncTimer = SystemTimer()

                    public let loggingConfig: ViewModelLoggingConfig = ViewModelLoggingConfig(mode: .minimal, loggerMode: .custom(TraceLogger()), customOptions: nil)
                }

                @MainActor
                extension TestViewModel: AsyncViewModelProtocol {
                }
                """,
                macros: testMacros
            )
        }

        // MARK: - Format Config Tests

        @Test("단일 포맷 - format: .compact")
        func singleFormatCompact() {
            assertMacroExpansion(
                """
                @AsyncViewModel(format: .compact)
                public final class TestViewModel: ObservableObject {
                    public enum Input: Sendable { case test }
                    public enum Action: Equatable & Sendable { case test }
                    public struct State: Equatable & Sendable { }
                    public enum CancelID: Hashable & Sendable { case test }
                    
                    @Published public var state: State = State()
                }
                """,
                expandedSource: """
                public final class TestViewModel: ObservableObject {
                    @MainActor
                    public enum Input: Sendable { case test }
                    @MainActor
                    public enum Action: Equatable & Sendable { case test }
                    @MainActor
                    public struct State: Equatable & Sendable { }
                    @MainActor
                    public enum CancelID: Hashable & Sendable { case test }
                    
                    @MainActor
                    @Published public var state: State = State()

                    public var tasks: [CancelID: Task<Void, Never>] = [:]

                    public var effectQueue: [AsyncEffect<Action, CancelID>] = []

                    public var isProcessingEffects: Bool = false

                    public var actionObserver: ((Action) -> Void)? = nil

                    public var stateChangeObserver: ((State, State) -> Void)? = nil

                    public var effectObserver: ((AsyncEffect<Action, CancelID>) -> Void)? = nil

                    public var performanceObserver: ((String, TimeInterval) -> Void)? = nil

                    public var timer: any AsyncTimer = SystemTimer()

                    public let loggingConfig: ViewModelLoggingConfig = ViewModelLoggingConfig(mode: .enabled, loggerMode: .shared, customOptions: LoggingOptions(actionFormat: .compact, stateFormat: .compact, effectFormat: .compact))
                }

                @MainActor
                extension TestViewModel: AsyncViewModelProtocol {
                }
                """,
                macros: testMacros
            )
        }

        @Test("카테고리별 포맷 - format: .perCategory(...)")
        func perCategoryFormat() {
            assertMacroExpansion(
                """
                @AsyncViewModel(format: .perCategory(action: .compact, state: .detailed, effect: .standard))
                public final class TestViewModel: ObservableObject {
                    public enum Input: Sendable { case test }
                    public enum Action: Equatable & Sendable { case test }
                    public struct State: Equatable & Sendable { }
                    public enum CancelID: Hashable & Sendable { case test }
                    
                    @Published public var state: State = State()
                }
                """,
                expandedSource: """
                public final class TestViewModel: ObservableObject {
                    @MainActor
                    public enum Input: Sendable { case test }
                    @MainActor
                    public enum Action: Equatable & Sendable { case test }
                    @MainActor
                    public struct State: Equatable & Sendable { }
                    @MainActor
                    public enum CancelID: Hashable & Sendable { case test }
                    
                    @MainActor
                    @Published public var state: State = State()

                    public var tasks: [CancelID: Task<Void, Never>] = [:]

                    public var effectQueue: [AsyncEffect<Action, CancelID>] = []

                    public var isProcessingEffects: Bool = false

                    public var actionObserver: ((Action) -> Void)? = nil

                    public var stateChangeObserver: ((State, State) -> Void)? = nil

                    public var effectObserver: ((AsyncEffect<Action, CancelID>) -> Void)? = nil

                    public var performanceObserver: ((String, TimeInterval) -> Void)? = nil

                    public var timer: any AsyncTimer = SystemTimer()

                    public let loggingConfig: ViewModelLoggingConfig = ViewModelLoggingConfig(mode: .enabled, loggerMode: .shared, customOptions: LoggingOptions(actionFormat: .compact, stateFormat: .detailed, effectFormat: .standard))
                }

                @MainActor
                extension TestViewModel: AsyncViewModelProtocol {
                }
                """,
                macros: testMacros
            )
        }

        @Test("특정 카테고리만 포맷 변경 - format: .action(...)")
        func singleCategoryFormat() {
            assertMacroExpansion(
                """
                @AsyncViewModel(format: .action(.compact))
                public final class TestViewModel: ObservableObject {
                    public enum Input: Sendable { case test }
                    public enum Action: Equatable & Sendable { case test }
                    public struct State: Equatable & Sendable { }
                    public enum CancelID: Hashable & Sendable { case test }
                    
                    @Published public var state: State = State()
                }
                """,
                expandedSource: """
                public final class TestViewModel: ObservableObject {
                    @MainActor
                    public enum Input: Sendable { case test }
                    @MainActor
                    public enum Action: Equatable & Sendable { case test }
                    @MainActor
                    public struct State: Equatable & Sendable { }
                    @MainActor
                    public enum CancelID: Hashable & Sendable { case test }
                    
                    @MainActor
                    @Published public var state: State = State()

                    public var tasks: [CancelID: Task<Void, Never>] = [:]

                    public var effectQueue: [AsyncEffect<Action, CancelID>] = []

                    public var isProcessingEffects: Bool = false

                    public var actionObserver: ((Action) -> Void)? = nil

                    public var stateChangeObserver: ((State, State) -> Void)? = nil

                    public var effectObserver: ((AsyncEffect<Action, CancelID>) -> Void)? = nil

                    public var performanceObserver: ((String, TimeInterval) -> Void)? = nil

                    public var timer: any AsyncTimer = SystemTimer()

                    public let loggingConfig: ViewModelLoggingConfig = ViewModelLoggingConfig(mode: .enabled, loggerMode: .shared, customOptions: LoggingOptions(actionFormat: .compact))
                }

                @MainActor
                extension TestViewModel: AsyncViewModelProtocol {
                }
                """,
                macros: testMacros
            )
        }

        // MARK: - Combined Options Tests

        @Test("모든 옵션 조합")
        func allOptionsCombined() {
            assertMacroExpansion(
                """
                @AsyncViewModel(logging: .only(.action, .error), logger: .custom(DebugLogger()), format: .detailed)
                public final class TestViewModel: ObservableObject {
                    public enum Input: Sendable { case test }
                    public enum Action: Equatable & Sendable { case test }
                    public struct State: Equatable & Sendable { }
                    public enum CancelID: Hashable & Sendable { case test }
                    
                    @Published public var state: State = State()
                }
                """,
                expandedSource: """
                public final class TestViewModel: ObservableObject {
                    @MainActor
                    public enum Input: Sendable { case test }
                    @MainActor
                    public enum Action: Equatable & Sendable { case test }
                    @MainActor
                    public struct State: Equatable & Sendable { }
                    @MainActor
                    public enum CancelID: Hashable & Sendable { case test }
                    
                    @MainActor
                    @Published public var state: State = State()

                    public var tasks: [CancelID: Task<Void, Never>] = [:]

                    public var effectQueue: [AsyncEffect<Action, CancelID>] = []

                    public var isProcessingEffects: Bool = false

                    public var actionObserver: ((Action) -> Void)? = nil

                    public var stateChangeObserver: ((State, State) -> Void)? = nil

                    public var effectObserver: ((AsyncEffect<Action, CancelID>) -> Void)? = nil

                    public var performanceObserver: ((String, TimeInterval) -> Void)? = nil

                    public var timer: any AsyncTimer = SystemTimer()

                    public let loggingConfig: ViewModelLoggingConfig = ViewModelLoggingConfig(mode: .only(Set([.action, .error])), loggerMode: .custom(DebugLogger()), customOptions: LoggingOptions(actionFormat: .detailed, stateFormat: .detailed, effectFormat: .detailed))
                }

                @MainActor
                extension TestViewModel: AsyncViewModelProtocol {
                }
                """,
                macros: testMacros
            )
        }

        // MARK: - Existing Property Tests

        @Test("이미 선언된 프로퍼티는 건너뛰기")
        func skipExistingProperties() {
            assertMacroExpansion(
                """
                @AsyncViewModel
                public final class TestViewModel: ObservableObject {
                    public enum Input: Sendable { case test }
                    public enum Action: Equatable & Sendable { case test }
                    public struct State: Equatable & Sendable { }
                    public enum CancelID: Hashable & Sendable { case test }
                    
                    @Published public var state: State = State()
                    
                    // 사용자가 커스텀한 프로퍼티
                    public var timer: any AsyncTimer = MockTimer()
                }
                """,
                expandedSource: """
                public final class TestViewModel: ObservableObject {
                    @MainActor
                    public enum Input: Sendable { case test }
                    @MainActor
                    public enum Action: Equatable & Sendable { case test }
                    @MainActor
                    public struct State: Equatable & Sendable { }
                    @MainActor
                    public enum CancelID: Hashable & Sendable { case test }
                    
                    @MainActor
                    @Published public var state: State = State()
                    
                    // 사용자가 커스텀한 프로퍼티
                    @MainActor
                    public var timer: any AsyncTimer = MockTimer()

                    public var tasks: [CancelID: Task<Void, Never>] = [:]

                    public var effectQueue: [AsyncEffect<Action, CancelID>] = []

                    public var isProcessingEffects: Bool = false

                    public var actionObserver: ((Action) -> Void)? = nil

                    public var stateChangeObserver: ((State, State) -> Void)? = nil

                    public var effectObserver: ((AsyncEffect<Action, CancelID>) -> Void)? = nil

                    public var performanceObserver: ((String, TimeInterval) -> Void)? = nil

                    public let loggingConfig: ViewModelLoggingConfig = ViewModelLoggingConfig(mode: .enabled, loggerMode: .shared, customOptions: nil)
                }

                @MainActor
                extension TestViewModel: AsyncViewModelProtocol {
                }
                """,
                macros: testMacros
            )
        }

        @Test("이미 @MainActor가 있는 멤버는 중복 추가하지 않기")
        func existingMainActorOnMember() {
            assertMacroExpansion(
                """
                @AsyncViewModel
                public final class TestViewModel: ObservableObject {
                    public enum Input: Sendable { case test }
                    public enum Action: Equatable & Sendable { case test }
                    public struct State: Equatable & Sendable { }
                    public enum CancelID: Hashable & Sendable { case test }
                    
                    @MainActor
                    @Published public var state: State = State()
                }
                """,
                expandedSource: """
                public final class TestViewModel: ObservableObject {
                    @MainActor
                    public enum Input: Sendable { case test }
                    @MainActor
                    public enum Action: Equatable & Sendable { case test }
                    @MainActor
                    public struct State: Equatable & Sendable { }
                    @MainActor
                    public enum CancelID: Hashable & Sendable { case test }
                    
                    @MainActor
                    @Published public var state: State = State()

                    public var tasks: [CancelID: Task<Void, Never>] = [:]

                    public var effectQueue: [AsyncEffect<Action, CancelID>] = []

                    public var isProcessingEffects: Bool = false

                    public var actionObserver: ((Action) -> Void)? = nil

                    public var stateChangeObserver: ((State, State) -> Void)? = nil

                    public var effectObserver: ((AsyncEffect<Action, CancelID>) -> Void)? = nil

                    public var performanceObserver: ((String, TimeInterval) -> Void)? = nil

                    public var timer: any AsyncTimer = SystemTimer()

                    public let loggingConfig: ViewModelLoggingConfig = ViewModelLoggingConfig(mode: .enabled, loggerMode: .shared, customOptions: nil)
                }

                @MainActor
                extension TestViewModel: AsyncViewModelProtocol {
                }
                """,
                macros: testMacros
            )
        }

        // MARK: - Error Tests

        @Test("struct에 적용 시 에러")
        func structError() {
            assertMacroExpansion(
                """
                @AsyncViewModel
                struct TestViewModel {
                }
                """,
                expandedSource: """
                struct TestViewModel {
                }
                """,
                diagnostics: [
                    DiagnosticSpec(
                        message: "@AsyncViewModel can only be applied to a class",
                        line: 1,
                        column: 1
                    )
                ],
                macros: testMacros
            )
        }

        @Test("enum에 적용 시 에러")
        func enumError() {
            assertMacroExpansion(
                """
                @AsyncViewModel
                enum TestViewModel {
                    case test
                }
                """,
                expandedSource: """
                enum TestViewModel {
                    case test
                }
                """,
                diagnostics: [
                    DiagnosticSpec(
                        message: "@AsyncViewModel can only be applied to a class",
                        line: 1,
                        column: 1
                    )
                ],
                macros: testMacros
            )
        }
    }

#endif // os(macOS)
