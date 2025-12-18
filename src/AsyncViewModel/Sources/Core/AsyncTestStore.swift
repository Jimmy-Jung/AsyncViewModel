//
//  AsyncTestStore.swift
//  AsyncViewModel
//
//  Created by 정준영 on 2025/8/7.
//

import Foundation

/// 테스트를 위한 AsyncViewModel 스토어
///
/// 이 클래스는 ViewModel의 모든 액션을 자동으로 추적하고,
/// 테스트에서 상태 변화를 쉽게 검증할 수 있도록 돕습니다.
///
/// 사용 예시:
/// ```swift
/// let store = AsyncTestStore(viewModel: viewModel)
/// store.send(.increment)
/// try await store.wait(for: { $0.count == 1 })
/// XCTAssertEqual(store.actions, [.increment, .incrementCompleted])
/// ```
///
/// **중요**: 테스트 완료 후 `cleanup()`을 호출하여 observer를 복원하는 것을 권장합니다.
@available(macOS 10.15, *)
@MainActor
public class AsyncTestStore<ViewModel: AsyncViewModelProtocol> {
    public let viewModel: ViewModel
    private var receivedActions: [ViewModel.Action] = []
    private var originalObserver: ((ViewModel.Action) -> Void)?

    public init(viewModel: ViewModel) {
        self.viewModel = viewModel
        
        // 기존 observer 백업
        self.originalObserver = viewModel.actionObserver
        
        // 모든 액션을 자동으로 기록하도록 observer 설정
        viewModel.actionObserver = { [weak self] action in
            self?.receivedActions.append(action)
            // 기존 observer도 호출
            self?.originalObserver?(action)
        }
    }
    
    /// Observer를 원래 상태로 복원합니다.
    ///
    /// 테스트 완료 후 호출하여 ViewModel의 observer를 원래 상태로 되돌립니다.
    /// Swift 6의 엄격한 동시성 모델로 인해 deinit에서 자동 복원이 불가능하므로,
    /// 명시적으로 이 메서드를 호출해야 합니다.
    ///
    /// 사용 예시:
    /// ```swift
    /// let store = AsyncTestStore(viewModel: viewModel)
    /// defer { store.cleanup() }
    /// // 테스트 코드...
    /// ```
    public func cleanup() {
        viewModel.actionObserver = originalObserver
    }

    /// 액션을 ViewModel에 직접 전달합니다.
    ///
    /// 주의: 이 메서드를 통해 전달된 액션은 자동으로 `actions` 배열에 기록됩니다.
    public func perform(_ action: ViewModel.Action) {
        viewModel.perform(action)
    }

    /// 입력을 ViewModel에 직접 전달합니다.
    public func send(_ input: ViewModel.Input) {
        viewModel.send(input)
    }

    /// 현재 상태를 반환합니다.
    public var state: ViewModel.State {
        viewModel.state
    }

    /// 모든 기록된 액션들을 반환합니다.
    ///
    /// 이 배열은 `send()` 또는 `perform()`을 통해 직접 전달된 액션뿐만 아니라,
    /// Effect를 통해 발생한 모든 액션을 포함합니다.
    public var actions: [ViewModel.Action] {
        receivedActions
    }
    
    /// 기록된 액션들을 초기화합니다.
    ///
    /// 여러 테스트 케이스를 순차적으로 실행할 때 유용합니다.
    public func clearActions() {
        receivedActions.removeAll()
    }
    
    /// 진행 중인 모든 작업이 완료될 때까지 기다립니다.
    public func waitForEffects(timeout: TimeInterval = 1.0) async throws {
        let startTime = Date()
        
        while !viewModel.tasks.isEmpty || viewModel.isProcessingEffects {
            if Date().timeIntervalSince(startTime) > timeout {
                throw TestError.timeout
            }
            try await Task.sleep(nanoseconds: 10_000_000) // 10ms
        }
    }

    /// 특정 상태가 되기를 기다립니다.
    public func wait(for predicate: @escaping (ViewModel.State) -> Bool, timeout: TimeInterval = 1.0) async throws {
        let startTime = Date()

        while !predicate(state) {
            if Date().timeIntervalSince(startTime) > timeout {
                throw TestError.timeout
            }
            try await Task.sleep(nanoseconds: 10_000_000) // 10ms
        }
    }

    public enum TestError: Error {
        case timeout
        case unexpectedState
        case unexpectedAction
    }
}
