//
//  ViewModelLoggerConfigurationTests.swift
//  AsyncViewModelTests
//
//  Created by jimmy on 2025/12/29.
//

@testable import AsyncViewModelCore
import Combine
import Testing

// MARK: - Test ViewModels

@MainActor
final class GlobalTestViewModel: ObservableObject, AsyncViewModelProtocol {
    @Published var state = State()
    var tasks: [CancelID: Task<Void, Never>] = [:]
    var effectQueue: [AsyncEffect<Action, CancelID>] = []
    var isProcessingEffects = false
    var timer: any AsyncTimer = SystemTimer()
    var actionObserver: ((Action) -> Void)?

    var stateChangeObserver: ((State, State) -> Void)?
    var effectObserver: ((AsyncEffect<Action, CancelID>) -> Void)?
    var performanceObserver: ((String, Double) -> Void)?

    struct State: Equatable, Sendable {
        var value: Int = 0
    }

    enum Input: Equatable, Sendable {
        case increment
    }

    enum Action: Equatable, Sendable {
        case increment
    }

    enum CancelID: Hashable, Sendable {}

    func transform(_ input: Input) -> [Action] {
        switch input {
        case .increment:
            return [.increment]
        }
    }

    func reduce(state: inout State, action: Action) -> [AsyncEffect<Action, CancelID>] {
        switch action {
        case .increment:
            state.value += 1
            return []
        }
    }
}

// MARK: - Mock Logger for Global Tests

@MainActor
final class GlobalMockLogger: ViewModelLogger {
    var options: LoggingOptions = .init()
    var loggedActions: [String] = []

    func logAction(
        _ action: String,
        viewModel: String,
        level _: LogLevel,
        file _: String,
        function _: String,
        line _: Int
    ) {
        loggedActions.append("[\(viewModel)] \(action)")
    }

    func logStateChange(
        from _: String,
        to _: String,
        viewModel _: String,
        file _: String,
        function _: String,
        line _: Int
    ) {}

    func logEffect(
        _: String,
        viewModel _: String,
        file _: String,
        function _: String,
        line _: Int
    ) {}

    func logEffects(
        _: [String],
        viewModel _: String,
        file _: String,
        function _: String,
        line _: Int
    ) {}

    func logStateDiff(
        changes _: [String: (old: String, new: String)],
        viewModel _: String,
        file _: String,
        function _: String,
        line _: Int
    ) {}

    func logPerformance(
        operation _: String,
        duration _: Double,
        viewModel _: String,
        level _: LogLevel,
        file _: String,
        function _: String,
        line _: Int
    ) {}

    func logError(
        _: SendableError,
        viewModel _: String,
        level _: LogLevel,
        file _: String,
        function _: String,
        line _: Int
    ) {}
}

// MARK: - LoggerConfiguration Tests

@MainActor
@Suite("LoggerConfiguration Tests")
struct LoggerConfigurationTests {
    init() {
        // 각 테스트 시작 전 기본값으로 재설정
        LoggerConfiguration.resetToDefault()
    }

    @Test("전역 기본 로거가 올바르게 설정됨")
    func globalLoggerIsSet() async {
        let mockLogger = GlobalMockLogger()
        LoggerConfiguration.setLogger(mockLogger)

        // 전역 로거가 설정되었는지 확인
        #expect(LoggerConfiguration.logger is GlobalMockLogger)

        // 정리
        LoggerConfiguration.resetToDefault()
    }

    @Test("전역 로거가 모든 ViewModel에 적용됨")
    func globalLoggerAppliedToAllViewModels() async {
        let mockLogger = GlobalMockLogger()
        LoggerConfiguration.setLogger(mockLogger)

        // 여러 ViewModel 인스턴스 생성
        let viewModel1 = GlobalTestViewModel()
        let viewModel2 = GlobalTestViewModel()

        // 액션 전송
        viewModel1.send(.increment)
        viewModel2.send(.increment)

        // 두 ViewModel 모두 전역 로거를 사용하는지 확인
        #expect(mockLogger.loggedActions.count == 2)
        #expect(mockLogger.loggedActions[0].contains("GlobalTestViewModel"))
        #expect(mockLogger.loggedActions[1].contains("GlobalTestViewModel"))

        // 정리
        LoggerConfiguration.resetToDefault()
    }

    @Test("로깅 비활성화가 올바르게 작동함")
    func disableLoggingWorks() async {
        LoggerConfiguration.disableLogging()

        let viewModel = GlobalTestViewModel()
        viewModel.send(.increment)

        // NoOpLogger가 사용되므로 아무 일도 일어나지 않음 (크래시 없음)
        #expect(viewModel.state.value == 1)

        // 정리
        LoggerConfiguration.resetToDefault()
    }

    @Test("기본값으로 재설정이 올바르게 작동함")
    func resetToDefaultWorks() async {
        let mockLogger = GlobalMockLogger()

        // 전역 로거 설정
        LoggerConfiguration.setLogger(mockLogger)
        #expect(LoggerConfiguration.logger is GlobalMockLogger)

        // 기본값으로 재설정 (OSLogViewModelLogger)
        LoggerConfiguration.resetToDefault()
        #expect(LoggerConfiguration.logger is OSLogViewModelLogger)
    }

    @Test("기본 OSLogViewModelLogger로 동작함")
    func worksWithDefaultLogger() async {
        // 기본 로거 사용 (OSLogViewModelLogger)
        LoggerConfiguration.resetToDefault()

        let viewModel = GlobalTestViewModel()
        viewModel.send(.increment)

        // OSLogViewModelLogger를 사용하므로 크래시 없이 동작
        #expect(viewModel.state.value == 1)
    }

    @Test("로거 변경이 즉시 적용됨")
    func loggerChangeAppliesImmediately() async {
        let mockLogger1 = GlobalMockLogger()
        let mockLogger2 = GlobalMockLogger()

        // 첫 번째 로거 설정
        LoggerConfiguration.setLogger(mockLogger1)

        let viewModel = GlobalTestViewModel()
        viewModel.send(.increment)

        #expect(mockLogger1.loggedActions.count == 1)
        #expect(mockLogger2.loggedActions.isEmpty)

        // 두 번째 로거로 변경
        LoggerConfiguration.setLogger(mockLogger2)

        viewModel.send(.increment)

        // 첫 번째 로거는 더 이상 사용되지 않음
        #expect(mockLogger1.loggedActions.count == 1)
        #expect(mockLogger2.loggedActions.count == 1)

        // 정리
        LoggerConfiguration.resetToDefault()
    }
}
