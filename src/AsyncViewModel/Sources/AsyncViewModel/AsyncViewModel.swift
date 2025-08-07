//
//  AsyncViewModel.swift
//  AsyncViewModel
//
//  Created by 정준영 on 2025/8/3.
//

import Foundation

// MARK: - AsyncViewModel Protocol

/// 개선된 비동기 작업을 처리하는 ViewModel 프로토콜
///
/// 단방향 데이터 흐름을 위한 비동기 방식의 ViewModel입니다.
/// Input -> Action -> Reduce -> State 업데이트 + Effect 흐름으로 데이터가 처리됩니다.
@MainActor
public protocol AsyncViewModel: ObservableObject {
    associatedtype Input: Sendable
    associatedtype Action: Equatable & Sendable
    associatedtype State: Equatable & Sendable
    associatedtype CancelID: Hashable & Sendable

    /// 현재 상태
    var state: State { get set }

    /// 진행 중인 작업을 관리하는 딕셔너리
    var tasks: [AnyHashable: Task<Void, Never>] { get set }

    /// 입력 이벤트를 전송하여 처리를 시작합니다.
    func send(_ input: Input)

    /// 입력을 Action으로 변환합니다. (동기)
    func transform(_ input: Input) -> [Action]

    /// 순수 함수로 상태를 변경하고 부수 효과를 반환합니다.
    func reduce(state: inout State, action: Action) -> [AsyncEffect<Action>]

    /// 에러 처리를 위한 메서드
    func handleError(_ error: SendableError)
}

// MARK: - Default Implementation

public extension AsyncViewModel {
    /// 입력을 처리하는 개선된 메서드
    func send(_ input: Input) {
        let actions = transform(input)

        for action in actions {
            perform(action)
        }
    }

    /// 액션을 직접 처리하는 메서드
    func perform(_ action: Action) {
        let effects = reduce(state: &state, action: action)

        for effect in effects {
            Task { [weak self] in
                await self?.handleEffect(effect)
            }
        }
    }

    private func handleEffect(_ effect: AsyncEffect<Action>) async {
        switch effect {
        case .none:
            break

        case let .action(action):
            await MainActor.run {
                perform(action)
            }

        case let .run(id, operation):
            // 기존 작업이 있다면 취소
            if let id = id {
                let hashableId = AnyHashable(id)
                tasks[hashableId]?.cancel()
            }

            let task = Task {
                let result = await operation()

                await MainActor.run { [weak self] in
                    switch result {
                    case let .action(action):
                        self?.perform(action)
                    case let .actions(actions):
                        actions.forEach { self?.perform($0) }
                    case .none:
                        break
                    case let .error(error):
                        self?.handleError(error)
                    }
                }
            }

            if let id = id {
                let hashableId = AnyHashable(id)
                tasks[hashableId] = task

                Task {
                    await task.value
                    await MainActor.run { [weak self] in
                        self?.tasks[hashableId] = nil
                    }
                }
            }

        case let .cancel(id):
            let hashableId = AnyHashable(id)
            tasks[hashableId]?.cancel()
            tasks[hashableId] = nil

        case let .merge(effects):
            for effect in effects {
                await handleEffect(effect)
            }
        }
    }

    /// 에러 처리를 위한 기본 구현
    func handleError(_ error: SendableError) {
        print("AsyncViewModel error: \(error.localizedDescription)")
    }
}
