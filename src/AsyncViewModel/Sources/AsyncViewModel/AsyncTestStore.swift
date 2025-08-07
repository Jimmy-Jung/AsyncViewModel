//
//  AsyncTestStore.swift
//  AsyncViewModel
//
//  Created by 정준영 on 2025/8/7.
//

import Foundation

/// 테스트를 위한 AsyncViewModel 스토어
@available(macOS 10.15, *)
@MainActor
public class AsyncTestStore<ViewModel: AsyncViewModel> {
    public let viewModel: ViewModel
    private var receivedActions: [ViewModel.Action] = []

    public init(viewModel: ViewModel) {
        self.viewModel = viewModel
    }

    /// 액션을 ViewModel에 직접 전달합니다.
    public func perform(_ action: ViewModel.Action) {
        receivedActions.append(action)
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

    /// 직접 perform을 통해 전달된 액션들을 반환합니다.
    public var actions: [ViewModel.Action] {
        receivedActions
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
