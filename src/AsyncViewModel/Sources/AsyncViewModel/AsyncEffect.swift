//
//  AsyncEffect.swift
//  AsyncViewModel
//
//  Created by 정준영 on 2025/8/7.
//

import Foundation

/// ViewModel에서 반환할 수 있는 효과(Effect)를 정의합니다.
public enum AsyncEffect<Action: Equatable & Sendable>: Equatable {
    /// 아무것도 하지 않습니다.
    case none
    /// 일반적인 액션을 실행합니다.
    case action(Action)
    /// 비동기 작업을 실행합니다.
    case run(id: (any Hashable & Sendable)? = nil, operation: AsyncOperation<Action>)
    /// 특정 ID를 가진 작업을 취소합니다.
    case cancel(id: any Hashable & Sendable)
    /// 여러 Effect를 병합합니다.
    case merge([AsyncEffect<Action>])

    public static func == (lhs: AsyncEffect<Action>, rhs: AsyncEffect<Action>) -> Bool {
        switch (lhs, rhs) {
        case (.none, .none):
            return true
        case let (.action(lhsAction), .action(rhsAction)):
            return lhsAction == rhsAction
        case let (.run(lhsId, _), .run(rhsId, _)):
            return lhsId?.hashValue == rhsId?.hashValue
        case let (.cancel(lhsId), .cancel(rhsId)):
            return lhsId.hashValue == rhsId.hashValue
        case let (.merge(lhsEffects), .merge(rhsEffects)):
            return lhsEffects == rhsEffects
        default:
            return false
        }
    }
}

// MARK: - Convenience Extensions

public extension AsyncEffect {
    /// 여러 Effect를 병합하는 편의 메서드
    static func merge(_ effects: AsyncEffect<Action>...) -> AsyncEffect<Action> {
        return .merge(effects)
    }

    /// 단일 액션을 반환하는 비동기 작업을 실행하는 편의 메서드
    static func runAction(
        id: (any Hashable & Sendable)? = nil,
        operation: @escaping @Sendable () async throws -> Action
    ) -> AsyncEffect<Action> {
        return .run(id: id, operation: AsyncOperation { () async -> AsyncOperationResult<Action> in
            do {
                let action = try await operation()
                return .action(action)
            } catch {
                return .error(SendableError(error))
            }
        })
    }

    /// 여러 액션을 반환하는 비동기 작업을 실행하는 편의 메서드
    static func runActions(
        id: (any Hashable & Sendable)? = nil,
        operation: @escaping @Sendable () async throws -> [Action]
    ) -> AsyncEffect<Action> {
        return .run(id: id, operation: AsyncOperation { () async -> AsyncOperationResult<Action> in
            do {
                let actions = try await operation()
                return .actions(actions)
            } catch {
                return .error(SendableError(error))
            }
        })
    }
}
