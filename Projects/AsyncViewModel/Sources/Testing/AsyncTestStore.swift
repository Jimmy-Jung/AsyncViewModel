//
//  AsyncTestStore.swift
//  AsyncViewModel
//
//  Created by 정준영 on 2025/8/7.
//

import Foundation

/// ViewModel의 모든 액션을 자동으로 추적하는 테스트 스토어
///
/// 사용 예시:
/// ```swift
/// let store = AsyncTestStore(viewModel: viewModel)
/// store.send(.increment)
/// try await store.wait(for: { $0.count == 1 })
/// XCTAssertEqual(store.actions, [.increment, .incrementCompleted])
/// ```
@available(macOS 10.15, *)
@MainActor
public class AsyncTestStore<ViewModel: AsyncViewModelProtocol> {
    public let viewModel: ViewModel
    public let testTimer: TestTimer
    private var receivedActions: [ViewModel.Action] = []
    private var originalObserver: ((ViewModel.Action) -> Void)?

    public init(viewModel: ViewModel) {
        self.viewModel = viewModel
        testTimer = TestTimer()

        // TestTimer를 ViewModel에 주입
        viewModel.timer = testTimer

        originalObserver = viewModel.actionObserver

        viewModel.actionObserver = { [weak self] action in
            self?.receivedActions.append(action)
            self?.originalObserver?(action)
        }
    }

    public func cleanup() {
        viewModel.actionObserver = originalObserver
    }

    public func perform(_ action: ViewModel.Action) {
        viewModel.perform(action)
    }

    public func send(_ input: ViewModel.Input) {
        viewModel.send(input)
    }

    public var state: ViewModel.State {
        viewModel.state
    }

    public var actions: [ViewModel.Action] {
        receivedActions
    }

    public func clearActions() {
        receivedActions.removeAll()
    }

    // MARK: - Task Management

    /// 특정 ID의 활성 작업이 있는지 확인합니다.
    ///
    /// **사용 예시:**
    /// ```swift
    /// testStore.send(.startLongTask)
    /// #expect(testStore.hasActiveTask(id: .longTask) == true)
    ///
    /// testStore.send(.cancelTask)
    /// #expect(testStore.hasActiveTask(id: .longTask) == false)
    /// ```
    public func hasActiveTask(id: ViewModel.CancelID) -> Bool {
        viewModel.tasks[id] != nil
    }

    /// 현재 활성화된 모든 작업의 ID 목록을 반환합니다.
    ///
    /// **사용 예시:**
    /// ```swift
    /// testStore.send(.startMultipleTasks)
    /// #expect(testStore.activeTaskIDs.contains(.taskA))
    /// #expect(testStore.activeTaskIDs.contains(.taskB))
    /// ```
    public var activeTaskIDs: Set<ViewModel.CancelID> {
        Set(viewModel.tasks.keys)
    }

    /// 활성 작업의 개수를 반환합니다.
    public var activeTaskCount: Int {
        viewModel.tasks.count
    }

    /// 특정 작업이 시작될 때까지 대기합니다.
    ///
    /// **사용 예시:**
    /// ```swift
    /// testStore.send(.startLongTask)
    /// try await testStore.waitUntilTaskStarts(id: .longTask)
    /// #expect(testStore.hasActiveTask(id: .longTask))
    /// ```
    public func waitUntilTaskStarts(id: ViewModel.CancelID, timeout: TimeInterval = 1.0) async throws {
        let startTime = Date()

        while !hasActiveTask(id: id) {
            if Date().timeIntervalSince(startTime) > timeout {
                throw TestError.timeout(
                    description: "Task '\(id)' did not start",
                    lastState: String(describing: state)
                )
            }
            try await Task.sleep(nanoseconds: 10_000_000)
        }
    }

    /// 특정 작업이 완료될 때까지 대기합니다.
    ///
    /// **사용 예시:**
    /// ```swift
    /// try await testStore.waitUntilTaskCompletes(id: .longTask)
    /// #expect(testStore.hasActiveTask(id: .longTask) == false)
    /// ```
    public func waitUntilTaskCompletes(id: ViewModel.CancelID, timeout: TimeInterval = 1.0) async throws {
        let startTime = Date()

        while hasActiveTask(id: id) {
            if Date().timeIntervalSince(startTime) > timeout {
                throw TestError.timeout(
                    description: "Task '\(id)' did not complete",
                    lastState: String(describing: state)
                )
            }
            try await Task.sleep(nanoseconds: 10_000_000)
        }
    }

    // MARK: - Wait Methods

    public func waitForEffects(timeout: TimeInterval = 1.0) async throws {
        let startTime = Date()

        while !viewModel.tasks.isEmpty || viewModel.isProcessingEffects {
            if Date().timeIntervalSince(startTime) > timeout {
                throw TestError.timeout(
                    description: "Effects still processing. Active tasks: \(activeTaskIDs)",
                    lastState: String(describing: state)
                )
            }
            try await Task.sleep(nanoseconds: 10_000_000)
        }
    }

    public func wait(for predicate: @escaping (ViewModel.State) -> Bool, timeout: TimeInterval = 1.0) async throws {
        let startTime = Date()

        while !predicate(state) {
            if Date().timeIntervalSince(startTime) > timeout {
                throw TestError.timeout(
                    description: "State condition not met",
                    lastState: String(describing: state)
                )
            }
            try await Task.sleep(nanoseconds: 10_000_000)
        }
    }

    /// 특정 Action이 발생할 때까지 대기합니다.
    ///
    /// **사용 예시:**
    /// ```swift
    /// testStore.send(.fetchData)
    /// try await testStore.waitForAction(.dataLoaded)
    /// #expect(testStore.state.data != nil)
    /// ```
    ///
    /// - Parameters:
    ///   - action: 대기할 Action
    ///   - timeout: 타임아웃 시간 (기본값: 1.0초)
    public func waitForAction(_ action: ViewModel.Action, timeout: TimeInterval = 1.0) async throws {
        let startTime = Date()
        let initialCount = receivedActions.count

        while !receivedActions.dropFirst(initialCount).contains(action) {
            if Date().timeIntervalSince(startTime) > timeout {
                let recentActions = receivedActions.suffix(5).map { String(describing: $0) }
                throw TestError.actionNotReceived(
                    expected: String(describing: action),
                    receivedActions: recentActions
                )
            }
            try await Task.sleep(nanoseconds: 10_000_000)
        }
    }

    /// 특정 Action이 발생할 때까지 대기하고, 발생 시 상태를 검증합니다.
    ///
    /// **사용 예시:**
    /// ```swift
    /// testStore.send(.increment)
    /// try await testStore.waitForAction(.incrementCompleted) { state in
    ///     #expect(state.count == 1)
    /// }
    /// ```
    public func waitForAction(
        _ action: ViewModel.Action,
        timeout: TimeInterval = 1.0,
        assert: (ViewModel.State) -> Void
    ) async throws {
        try await waitForAction(action, timeout: timeout)
        assert(state)
    }

    // MARK: - Virtual Time Control

    /// 가상 시간을 진행시킵니다. (TestTimer의 tick 호출)
    ///
    /// **사용 예시:**
    /// ```swift
    /// store.send(.startTimer)
    /// await store.tick(by: 1.0) // 1초 진행
    /// #expect(store.state.timerFired == true)
    /// ```
    public func tick(by duration: TimeInterval) async {
        // Task가 실제로 sleep을 등록할 수 있도록 MainActor에 양보
        await Task.yield()
        await testTimer.tick(by: duration)
    }

    /// 모든 대기 중인 sleep을 즉시 완료시킵니다.
    public func flush() async {
        await testTimer.flush()
    }

    /// 가상 시간을 진행시키고 조건이 충족될 때까지 대기합니다.
    ///
    /// **사용 예시:**
    /// ```swift
    /// testStore.send(.startDelayedTask)
    /// try await testStore.tickAndWait(by: 1.0, for: { $0.taskCompleted })
    /// ```
    public func tickAndWait(
        by duration: TimeInterval,
        for predicate: @escaping (ViewModel.State) -> Bool,
        timeout: TimeInterval = 1.0
    ) async throws {
        await tick(by: duration)

        // tick 후 즉시 조건 확인
        if predicate(state) {
            return
        }

        try await wait(for: predicate, timeout: timeout)
    }

    /// 가상 시간을 진행시키고 특정 Action이 발생할 때까지 대기합니다.
    ///
    /// **사용 예시:**
    /// ```swift
    /// testStore.send(.startTimer)
    /// try await testStore.tickAndWaitForAction(by: 1.0, action: .timerFired)
    /// ```
    public func tickAndWaitForAction(
        by duration: TimeInterval,
        action: ViewModel.Action,
        timeout: TimeInterval = 1.0
    ) async throws {
        let startTime = Date()
        let initialCount = receivedActions.count

        await tick(by: duration)

        // tick 중에 이미 액션이 발생했는지 확인
        if receivedActions.dropFirst(initialCount).contains(action) {
            return
        }

        // 아직 발생하지 않았으면 대기
        while !receivedActions.dropFirst(initialCount).contains(action) {
            if Date().timeIntervalSince(startTime) > timeout {
                let recentActions = receivedActions.suffix(5).map { String(describing: $0) }
                throw TestError.actionNotReceived(
                    expected: String(describing: action),
                    receivedActions: recentActions
                )
            }
            try await Task.sleep(nanoseconds: 10_000_000)
        }
    }

    // MARK: - Receive (TCA Style)

    /// 다음에 발생할 Action을 검증합니다. (TCA의 receive와 유사)
    ///
    /// **사용 예시:**
    /// ```swift
    /// testStore.send(.buttonTapped)
    /// try await testStore.receive(.loading)
    /// try await testStore.receive(.dataLoaded(data)) { state in
    ///     #expect(state.data == data)
    /// }
    /// ```
    ///
    /// - Parameters:
    ///   - expectedAction: 예상되는 Action
    ///   - timeout: 타임아웃 시간 (기본값: 1.0초)
    ///   - updateStateToExpectedResult: 상태 검증 클로저 (선택적)
    @discardableResult
    public func receive(
        _ expectedAction: ViewModel.Action,
        timeout: TimeInterval = 1.0,
        assert updateStateToExpectedResult: ((ViewModel.State) -> Void)? = nil
    ) async throws -> Self {
        try await waitForAction(expectedAction, timeout: timeout)
        updateStateToExpectedResult?(state)
        return self
    }

    // MARK: - Assert Helpers

    /// 현재 상태를 검증합니다.
    ///
    /// **사용 예시:**
    /// ```swift
    /// testStore.send(.setValue(10))
    /// testStore.assert { state in
    ///     #expect(state.currentValue == 10)
    ///     #expect(state.isLoading == false)
    /// }
    /// ```
    @discardableResult
    public func assert(_ assertion: (ViewModel.State) -> Void) -> Self {
        assertion(state)
        return self
    }

    /// 현재까지 발생한 Action들을 검증합니다.
    ///
    /// **사용 예시:**
    /// ```swift
    /// testStore.send(.buttonTapped)
    /// try await testStore.waitForEffects()
    /// testStore.assertActions { actions in
    ///     #expect(actions == [.buttonTapped, .loading, .loaded])
    /// }
    /// ```
    @discardableResult
    public func assertActions(_ assertion: ([ViewModel.Action]) -> Void) -> Self {
        assertion(receivedActions)
        return self
    }

    // MARK: - Skip Actions

    /// 지정된 개수만큼의 Action을 스킵합니다.
    ///
    /// 중간 과정의 Action들을 무시하고 최종 결과만 검증할 때 유용합니다.
    ///
    /// **사용 예시:**
    /// ```swift
    /// testStore.send(.complexOperation)
    /// testStore.skipReceivedActions(count: 3) // 중간 Action 3개 스킵
    /// try await testStore.receive(.finalAction)
    /// ```
    public func skipReceivedActions(count: Int) {
        guard count > 0, count <= receivedActions.count else { return }
        receivedActions.removeFirst(count)
    }

    /// 특정 Action까지의 모든 Action을 스킵합니다. (이미 발생한 Action 포함)
    ///
    /// 이미 발생한 Action을 찾으면 즉시 스킵하고, 없으면 해당 Action이 발생할 때까지 대기합니다.
    ///
    /// **사용 예시:**
    /// ```swift
    /// testStore.send(.startProcess)
    /// try await testStore.skipUntilAction(.processingComplete)
    /// #expect(testStore.state.isComplete == true)
    /// ```
    public func skipUntilAction(_ action: ViewModel.Action, timeout: TimeInterval = 1.0) async throws {
        // 이미 발생한 action에서 먼저 찾기
        if let index = receivedActions.firstIndex(of: action) {
            receivedActions.removeFirst(index + 1)
            return
        }

        // 없으면 새로 발생할 때까지 대기
        let startTime = Date()
        while !receivedActions.contains(action) {
            if Date().timeIntervalSince(startTime) > timeout {
                let recentActions = receivedActions.suffix(5).map { String(describing: $0) }
                throw TestError.actionNotReceived(
                    expected: String(describing: action),
                    receivedActions: recentActions
                )
            }
            try await Task.sleep(nanoseconds: 10_000_000)
        }

        if let index = receivedActions.firstIndex(of: action) {
            receivedActions.removeFirst(index + 1)
        }
    }
}

// MARK: - TestError

public extension AsyncTestStore {
    enum TestError: Error, CustomStringConvertible {
        case timeout(description: String, lastState: String)
        case actionNotReceived(expected: String, receivedActions: [String])
        case unexpectedAction(expected: String, received: String)
        case unexpectedState(expected: String, actual: String)

        public var description: String {
            switch self {
            case let .timeout(description, lastState):
                return """
                Timeout: \(description)
                Last state: \(lastState)
                """
            case let .actionNotReceived(expected, receivedActions):
                return """
                Action not received: \(expected)
                Recent actions: \(receivedActions.joined(separator: ", "))
                """
            case let .unexpectedAction(expected, received):
                return """
                Unexpected action
                Expected: \(expected)
                Received: \(received)
                """
            case let .unexpectedState(expected, actual):
                return """
                Unexpected state
                Expected: \(expected)
                Actual: \(actual)
                """
            }
        }
    }
}

// MARK: - Convenience Factory

public extension AsyncTestStore {
    /// TestStore를 생성하고 작업을 수행한 후 자동으로 정리합니다.
    ///
    /// **사용 예시:**
    /// ```swift
    /// try await AsyncTestStore.withStore(viewModel: viewModel) { store in
    ///     store.send(.increment)
    ///     try await store.receive(.incrementCompleted)
    ///     #expect(store.state.count == 1)
    /// }
    /// ```
    static func withStore<T: Sendable>(
        viewModel: ViewModel,
        _ operation: (AsyncTestStore) async throws -> T
    ) async rethrows -> T {
        let store = AsyncTestStore(viewModel: viewModel)
        defer { store.cleanup() }
        return try await operation(store)
    }
}
