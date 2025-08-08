//
//  AsyncViewModel.swift
//  AsyncViewModel
//
//  Created by 정준영 on 2025/8/3.
//

import Foundation
import os.log

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
    
    /// Effect 직렬 처리를 위한 큐
    var effectQueue: [AsyncEffect<Action>] { get set }
    
    /// Effect 처리 상태
    var isProcessingEffects: Bool { get set }

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
        effectQueue.append(contentsOf: effects)
        
        Task {
            await processNextEffect()
        }
    }
    
    private func processNextEffect() async {
        guard !isProcessingEffects else { return }
        isProcessingEffects = true
        
        while !effectQueue.isEmpty {
            let effect = effectQueue.removeFirst()
            await handleEffect(effect)
        }
        
        isProcessingEffects = false
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
            
        case let .concurrent(effects):
            // 메인 액터 격리를 유지한 병렬 처리: 각 작업을 메인 액터에서 생성/대기하여
            // 'sending' 경고 없이 안전하게 실행합니다.
            let tasks = effects.map { effect in
                Task { @MainActor in
                    await handleEffect(effect)
                }
            }
            for task in tasks {
                await task.value
            }
        }
    }

    /// 에러 처리를 위한 기본 구현
    func handleError(_ error: SendableError) {
        let logger = Logger(subsystem: "com.jimmy.AsyncViewModel", category: String(describing: Self.self))
        logger.error("AsyncViewModel error: \(error.localizedDescription, privacy: .public) [\(error.domain, privacy: .public):\(error.code, privacy: .public)]")
    }
}
