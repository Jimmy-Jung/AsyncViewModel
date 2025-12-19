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
    private var receivedActions: [ViewModel.Action] = []
    private var originalObserver: ((ViewModel.Action) -> Void)?

    public init(viewModel: ViewModel) {
        self.viewModel = viewModel
        
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

    public enum TestError: Error {
        case timeout
        case unexpectedState
        case unexpectedAction
    }
}
