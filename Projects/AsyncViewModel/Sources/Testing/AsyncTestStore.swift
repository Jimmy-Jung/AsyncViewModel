//
//  AsyncTestStore.swift
//  AsyncViewModel
//
//  Created by jimmy on 2025/12/29.
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
        self.testTimer = TestTimer()
        
        // TestTimer를 ViewModel에 주입
        viewModel.timer = testTimer
        
        self.originalObserver = viewModel.actionObserver
        
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
    
    public func waitForEffects(timeout: TimeInterval = 1.0) async throws {
        let startTime = Date()
        
        while !viewModel.tasks.isEmpty || viewModel.isProcessingEffects {
            if Date().timeIntervalSince(startTime) > timeout {
                throw TestError.timeout
            }
            try await Task.sleep(nanoseconds: 10_000_000)
        }
    }

    public func wait(for predicate: @escaping (ViewModel.State) -> Bool, timeout: TimeInterval = 1.0) async throws {
        let startTime = Date()

        while !predicate(state) {
            if Date().timeIntervalSince(startTime) > timeout {
                throw TestError.timeout
            }
            try await Task.sleep(nanoseconds: 10_000_000)
        }
    }
    
    /// 가상 시간을 진행시킵니다. (TestTimer의 tick 호출)
    ///
    /// **사용 예시:**
    /// ```swift
    /// store.send(.startTimer)
    /// await store.tick(by: 1.0) // 1초 진행
    /// #expect(store.state.timerFired == true)
    /// ```
    public func tick(by duration: TimeInterval) async {
        await testTimer.tick(by: duration)
    }
    
    /// 모든 대기 중인 sleep을 즉시 완료시킵니다.
    public func flush() async {
        await testTimer.flush()
    }

    public enum TestError: Error {
        case timeout
        case unexpectedState
        case unexpectedAction
    }
}
