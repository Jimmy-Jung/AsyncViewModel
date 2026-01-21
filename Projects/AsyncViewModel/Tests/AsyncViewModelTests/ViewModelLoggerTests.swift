//
//  ViewModelLoggerTests.swift
//  AsyncViewModelTests
//
//  Created by jimmy on 2025/12/18.
//

@testable import AsyncViewModelCore
import Combine
import Foundation
import Testing

// MARK: - Test ViewModels

@MainActor
final class TestViewModel: ObservableObject, AsyncViewModelProtocol {
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
        var count: Int = 0
    }

    enum Input: Equatable, Sendable {
        case increment
    }

    enum Action: Equatable, Sendable {
        case increment
    }

    enum CancelID: Hashable, Sendable {
        case timer
    }

    func transform(_ input: Input) -> [Action] {
        switch input {
        case .increment:
            return [.increment]
        }
    }

    func reduce(state: inout State, action: Action) -> [AsyncEffect<Action, CancelID>] {
        switch action {
        case .increment:
            state.count += 1
            return []
        }
    }
}

// MARK: - Mock Logger

@MainActor
final class MockLogger: ViewModelLogger {
    var options: LoggingOptions = .init()
    let formatter: LogFormatter = DefaultLogFormatter()
    var loggedActions: [ActionInfo] = []
    var loggedStateChanges: [StateChangeInfo] = []
    var loggedEffects: [EffectInfo] = []
    var loggedEffectsGroups: [[EffectInfo]] = []
    var loggedPerformance: [PerformanceInfo] = []
    var loggedErrors: [SendableError] = []

    func logAction(
        _ action: ActionInfo,
        viewModel _: String,
        file _: String,
        function _: String,
        line _: Int
    ) {
        loggedActions.append(action)
    }

    func logStateChange(
        _ stateChange: StateChangeInfo,
        viewModel _: String,
        file _: String,
        function _: String,
        line _: Int
    ) {
        loggedStateChanges.append(stateChange)
    }

    func logEffect(
        _ effect: EffectInfo,
        viewModel _: String,
        file _: String,
        function _: String,
        line _: Int
    ) {
        loggedEffects.append(effect)
    }

    func logEffects(
        _ effects: [EffectInfo],
        viewModel _: String,
        file _: String,
        function _: String,
        line _: Int
    ) {
        loggedEffectsGroups.append(effects)
    }

    func logPerformance(
        _ performance: PerformanceInfo,
        viewModel _: String,
        file _: String,
        function _: String,
        line _: Int
    ) {
        if !options.showZeroPerformance, !performance.exceededThreshold {
            return
        }
        loggedPerformance.append(performance)
    }

    func logError(
        _ error: SendableError,
        viewModel _: String,
        file _: String,
        function _: String,
        line _: Int
    ) {
        loggedErrors.append(error)
    }
}

// MARK: - ViewModelLogger Tests

@MainActor
@Suite("ViewModelLogger Tests")
struct ViewModelLoggerTests {
    // MARK: - NoOpLogger Tests

    @Test("NoOpLogger는 아무것도 기록하지 않음")
    func noOpLoggerDoesNothing() async {
        AsyncViewModelConfiguration.shared.changeLogger(NoOpLogger())

        let viewModel = TestViewModel()

        // 액션 전송
        viewModel.send(.increment)

        // NoOpLogger는 아무것도 하지 않으므로 에러가 발생하지 않아야 함
        #expect(viewModel.state.count == 1)

        // 정리
        AsyncViewModelConfiguration.shared.resetLogger()
    }

    // MARK: - MockLogger Tests

    @Test("커스텀 로거가 액션을 기록함")
    func customLoggerLogsAction() async {
        let mockLogger = MockLogger()
        AsyncViewModelConfiguration.shared.changeLogger(mockLogger)

        let viewModel = TestViewModel()

        // 액션 전송
        viewModel.send(.increment)

        // 액션이 기록되었는지 확인
        #expect(mockLogger.loggedActions.count == 1)
        #expect(mockLogger.loggedActions[0].caseName == "increment")

        // 정리
        AsyncViewModelConfiguration.shared.resetLogger()
    }

    @Test("커스텀 로거가 상태 변경을 기록함")
    func customLoggerLogsStateChange() async {
        let mockLogger = MockLogger()
        AsyncViewModelConfiguration.shared.changeLogger(mockLogger)

        let viewModel = TestViewModel()

        // 액션 전송
        viewModel.send(.increment)

        // 상태 변경이 기록되었는지 확인
        #expect(mockLogger.loggedStateChanges.count == 1)
        #expect(mockLogger.loggedStateChanges[0].changes.isEmpty == false || mockLogger.loggedStateChanges[0].oldState.properties.isEmpty == false)

        // 정리
        AsyncViewModelConfiguration.shared.resetLogger()
    }

    @Test("Effect 포맷이 작동함")
    func effectFormatWorks() async {
        let mockLogger = MockLogger()
        AsyncViewModelConfiguration.shared.changeLogger(mockLogger)

        let viewModel = TestViewModel()

        // 액션 전송 (none이 아닌 effect 반환)
        viewModel.send(.increment)

        // Effect 포맷 기본값 확인
        #expect(mockLogger.options.effectFormat == .standard)

        // 정리
        AsyncViewModelConfiguration.shared.resetLogger()
    }

    @Test("성능 로그 임계값이 작동함")
    func performanceThresholdWorks() async {
        let mockLogger = MockLogger()
        mockLogger.options.performanceThreshold = PerformanceThreshold(
            type: .custom,
            customThreshold: 1.0
        )
        AsyncViewModelConfiguration.shared.changeLogger(mockLogger)

        let viewModel = TestViewModel()

        // 빠른 액션 (임계값 이하)
        viewModel.send(.increment)

        // 성능 로그가 필터링되었는지 확인 (1초 이하이므로 로깅되지 않음)
        #expect(mockLogger.loggedPerformance.isEmpty)

        // 정리
        AsyncViewModelConfiguration.shared.resetLogger()
    }

    // Note: 이제 로깅은 전역 로거 설정에 의해 제어됩니다.
    // ViewModel별 isLoggingEnabled/logLevel은 제거되었습니다.

    @Test("성능 메트릭이 기록됨")
    func performanceMetricsAreLogged() async {
        let mockLogger = MockLogger()
        AsyncViewModelConfiguration.shared.changeLogger(mockLogger)

        let viewModel = TestViewModel()

        // 성능 메트릭 로깅 (임계값 초과하도록 높은 값 사용)
        viewModel.logPerformance("test_operation", duration: 1.0)

        // 성능 메트릭이 기록되었는지 확인
        #expect(mockLogger.loggedPerformance.count == 1)
        #expect(mockLogger.loggedPerformance[0].operation == "test_operation")
        #expect(mockLogger.loggedPerformance[0].duration == 1.0)

        // 정리
        AsyncViewModelConfiguration.shared.resetLogger()
    }

    @Test("에러가 기록됨")
    func errorsAreLogged() async {
        let mockLogger = MockLogger()
        AsyncViewModelConfiguration.shared.changeLogger(mockLogger)

        let viewModel = TestViewModel()

        // 에러 로깅
        let error = SendableError(
            message: "Not Found",
            code: 404,
            domain: "TestDomain"
        )
        viewModel.logError(error)

        // 에러가 기록되었는지 확인
        #expect(mockLogger.loggedErrors.count == 1)
        #expect(mockLogger.loggedErrors[0].domain == "TestDomain")
        #expect(mockLogger.loggedErrors[0].code == 404)

        // 정리
        AsyncViewModelConfiguration.shared.resetLogger()
    }

    // MARK: - OSLogViewModelLogger Tests

    @Test("OSLogViewModelLogger가 초기화됨")
    func osLogViewModelLoggerInitializes() {
        let logger = OSLogViewModelLogger(subsystem: "com.test")
        AsyncViewModelConfiguration.shared.changeLogger(logger)

        // 에러 없이 초기화되어야 함
        let viewModel = TestViewModel()

        #expect(AsyncViewModelConfiguration.shared.logger is OSLogViewModelLogger)

        // 정리
        AsyncViewModelConfiguration.shared.resetLogger()
    }

    @Test("OSLogViewModelLogger가 액션을 로깅함")
    func osLogViewModelLoggerLogsAction() async {
        let logger = OSLogViewModelLogger(subsystem: "com.test")
        AsyncViewModelConfiguration.shared.changeLogger(logger)

        let viewModel = TestViewModel()

        // 액션 전송 (os.log로 출력됨, 크래시하지 않아야 함)
        viewModel.send(.increment)

        // 에러 없이 완료되어야 함
        #expect(viewModel.state.count == 1)

        // 정리
        AsyncViewModelConfiguration.shared.resetLogger()
    }

    // MARK: - 기본 로거 Tests

    @Test("전역 기본 로거를 사용함 (OSLogViewModelLogger)")
    func usesGlobalDefaultLogger() async {
        // 기본 로거 사용
        AsyncViewModelConfiguration.shared.resetLogger()

        let viewModel = TestViewModel()

        // 액션 전송 (전역 기본 로거 사용, 크래시하지 않아야 함)
        viewModel.send(.increment)

        // 에러 없이 완료되어야 함
        #expect(viewModel.state.count == 1)
    }

    // MARK: - Observer Tests

    @Test("상태 변경 관찰자가 호출됨")
    func stateChangeObserverIsCalled() async {
        var observedChanges: [(old: TestViewModel.State, new: TestViewModel.State)] = []

        AsyncViewModelConfiguration.shared.changeLogger(MockLogger())

        let viewModel = TestViewModel()
        viewModel.stateChangeObserver = { old, new in
            observedChanges.append((old, new))
        }

        // 액션 전송
        viewModel.send(.increment)

        // 관찰자가 호출되었는지 확인 (로깅 설정에 따라 여러 번 호출될 수 있음)
        #expect(observedChanges.count >= 1)
        // 마지막 변경 확인
        let lastChange = observedChanges.last!
        #expect(lastChange.old.count == 0)
        #expect(lastChange.new.count == 1)

        // 정리
        AsyncViewModelConfiguration.shared.resetLogger()
    }

    @Test("액션 관찰자가 호출됨")
    func actionObserverIsCalled() async {
        var observedActions: [TestViewModel.Action] = []

        AsyncViewModelConfiguration.shared.changeLogger(MockLogger())

        let viewModel = TestViewModel()
        viewModel.actionObserver = { action in
            observedActions.append(action)
        }

        // 액션 전송
        viewModel.send(.increment)

        // 관찰자가 호출되었는지 확인
        #expect(observedActions.count == 1)
        #expect(observedActions[0] == .increment)
    }

    @Test("성능 관찰자가 호출됨")
    func performanceObserverIsCalled() async {
        var observedMetrics: [(operation: String, duration: Double)] = []

        AsyncViewModelConfiguration.shared.changeLogger(MockLogger())

        let viewModel = TestViewModel()
        viewModel.performanceObserver = { operation, duration in
            observedMetrics.append((operation, duration))
        }

        // 성능 메트릭 로깅
        viewModel.logPerformance("test", duration: 1.0)

        // 관찰자가 호출되었는지 확인
        #expect(observedMetrics.count == 1)
        #expect(observedMetrics[0].operation == "test")
        #expect(observedMetrics[0].duration == 1.0)
    }
}
