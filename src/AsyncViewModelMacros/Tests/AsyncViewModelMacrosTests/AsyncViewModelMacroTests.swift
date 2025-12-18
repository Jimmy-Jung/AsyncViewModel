//
//  AsyncViewModelMacroTests.swift
//  AsyncViewModelMacros
//
//  Created by 정준영 on 2025/12/17.
//

import SwiftSyntax
import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport
import Testing

@testable import AsyncViewModelMacrosImpl

// MARK: - AsyncViewModelMacroTests

@Suite("AsyncViewModel Macro Tests")
struct AsyncViewModelMacroTests {
    
    let testMacros: [String: Macro.Type] = [
        "AsyncViewModel": AsyncViewModelMacroImpl.self,
    ]
    
    // MARK: - Basic Expansion Tests
    
    @Test("기본 매크로 확장 - 모든 프로퍼티 생성 및 멤버에 @MainActor 자동 추가")
    func testBasicExpansion() {
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

                public var isLoggingEnabled: Bool = true

                public var logLevel: LogLevel = .info

                public var stateChangeObserver: ((State, State) -> Void)? = nil

                public var effectObserver: ((AsyncEffect<Action, CancelID>) -> Void)? = nil

                public var performanceObserver: ((String, TimeInterval) -> Void)? = nil
            }

            @MainActor
            extension TestViewModel: AsyncViewModelProtocol {
            }
            """,
            macros: testMacros
        )
    }
    
    @Test("커스텀 파라미터로 매크로 확장 및 멤버에 @MainActor 자동 추가")
    func testCustomParameters() {
        assertMacroExpansion(
            """
            @AsyncViewModel(isLoggingEnabled: false, logLevel: .debug)
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

                public var isLoggingEnabled: Bool = false

                public var logLevel: LogLevel = .debug

                public var stateChangeObserver: ((State, State) -> Void)? = nil

                public var effectObserver: ((AsyncEffect<Action, CancelID>) -> Void)? = nil

                public var performanceObserver: ((String, TimeInterval) -> Void)? = nil
            }

            @MainActor
            extension TestViewModel: AsyncViewModelProtocol {
            }
            """,
            macros: testMacros
        )
    }
    
    @Test("이미 선언된 프로퍼티는 건너뛰기 및 멤버에 @MainActor 자동 추가")
    func testSkipExistingProperties() {
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
                public var isLoggingEnabled: Bool = false
                public var logLevel: LogLevel = .error
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
                public var isLoggingEnabled: Bool = false
                @MainActor
                public var logLevel: LogLevel = .error

                public var tasks: [CancelID: Task<Void, Never>] = [:]

                public var effectQueue: [AsyncEffect<Action, CancelID>] = []

                public var isProcessingEffects: Bool = false

                public var actionObserver: ((Action) -> Void)? = nil

                public var stateChangeObserver: ((State, State) -> Void)? = nil

                public var effectObserver: ((AsyncEffect<Action, CancelID>) -> Void)? = nil

                public var performanceObserver: ((String, TimeInterval) -> Void)? = nil
            }

            @MainActor
            extension TestViewModel: AsyncViewModelProtocol {
            }
            """,
            macros: testMacros
        )
    }
    
    @Test("이미 @MainActor가 있는 멤버는 중복 추가하지 않기")
    func testExistingMainActorOnMember() {
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

                public var isLoggingEnabled: Bool = true

                public var logLevel: LogLevel = .info

                public var stateChangeObserver: ((State, State) -> Void)? = nil

                public var effectObserver: ((AsyncEffect<Action, CancelID>) -> Void)? = nil

                public var performanceObserver: ((String, TimeInterval) -> Void)? = nil
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
    func testStructError() {
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
    func testEnumError() {
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


