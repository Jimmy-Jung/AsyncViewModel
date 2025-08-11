//
//  AsyncEffect.swift
//  AsyncViewModel
//
//  Created by 정준영 on 2025/8/7.
//

import Foundation

/// ViewModel에서 반환할 수 있는 효과(Effect)를 정의합니다.
public enum AsyncEffect<Action: Equatable & Sendable, CancelID: Hashable & Sendable>: Equatable, Sendable {
    /// 아무것도 하지 않습니다.
    case none
    /// 일반적인 액션을 실행합니다.
    case action(Action)
    /// 비동기 작업을 실행합니다.
    case run(id: CancelID? = nil, operation: AsyncOperation<Action>)
    /// 특정 ID를 가진 작업을 취소합니다.
    case cancel(id: CancelID)
    /// 여러 Effect를 직렬로 병합합니다.
    case merge([AsyncEffect<Action, CancelID>])
    /// 여러 Effect를 병렬로 실행합니다.
    case concurrent([AsyncEffect<Action, CancelID>])

    public static func == (lhs: AsyncEffect<Action, CancelID>, rhs: AsyncEffect<Action, CancelID>) -> Bool {
        switch (lhs, rhs) {
        case (.none, .none):
            return true
        case let (.action(lhsAction), .action(rhsAction)):
            return lhsAction == rhsAction
        case let (.run(lhsId, _), .run(rhsId, _)):
            return lhsId == rhsId
        case let (.cancel(lhsId), .cancel(rhsId)):
            return lhsId == rhsId
        case let (.merge(lhsEffects), .merge(rhsEffects)):
            return lhsEffects == rhsEffects
        case let (.concurrent(lhsEffects), .concurrent(rhsEffects)):
            return lhsEffects == rhsEffects
        default:
            return false
        }
    }
}

// MARK: - Convenience Extensions

public extension AsyncEffect {
    /// 여러 Effect를 직렬로 병합하는 편의 메서드
    static func merge(_ effects: AsyncEffect<Action, CancelID>...) -> AsyncEffect<Action, CancelID> {
        return .merge(effects)
    }
    
    /// 여러 Effect를 병렬로 실행하는 편의 메서드
    static func concurrent(_ effects: AsyncEffect<Action, CancelID>...) -> AsyncEffect<Action, CancelID> {
        return .concurrent(effects)
    }

    /// 단일 액션을 반환하는 비동기 작업을 실행하는 편의 메서드
    static func runAction(
        id: CancelID? = nil,
        operation: @escaping @Sendable () async throws -> Action
    ) -> AsyncEffect<Action, CancelID> {
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
        id: CancelID? = nil,
        operation: @escaping @Sendable () async throws -> [Action]
    ) -> AsyncEffect<Action, CancelID> {
        return .run(id: id, operation: AsyncOperation { () async -> AsyncOperationResult<Action> in
            do {
                let actions = try await operation()
                return .actions(actions)
            } catch {
                return .error(SendableError(error))
            }
        })
    }

    // MARK: - Time-based Effects

    /// 지정된 시간만큼 대기하는 Effect
    static func sleep(
        id: CancelID? = nil,
        for duration: TimeInterval
    ) -> AsyncEffect<Action, CancelID> {
        return .run(id: id, operation: AsyncOperation { () async -> AsyncOperationResult<Action> in
            do {
                try await Task.sleep(nanoseconds: UInt64(duration * 1_000_000_000))
                return .none
            } catch {
                return .error(SendableError(error))
            }
        })
    }

    /// 지정된 시간만큼 대기한 후 액션을 반환하는 Effect
    static func sleepThen(
        id: CancelID? = nil,
        for duration: TimeInterval,
        action: Action
    ) -> AsyncEffect<Action, CancelID> {
        return .run(id: id, operation: AsyncOperation { () async -> AsyncOperationResult<Action> in
            do {
                try await Task.sleep(nanoseconds: UInt64(duration * 1_000_000_000))
                return .action(action)
            } catch {
                return .error(SendableError(error))
            }
        })
    }

    /// 디바운스 Effect: 연속된 호출을 일정 시간 후에만 실행
    static func debounce(
        id: CancelID,
        for duration: TimeInterval,
        operation: @escaping @Sendable () async throws -> Action
    ) -> AsyncEffect<Action, CancelID> {
        return .run(id: id, operation: AsyncOperation { () async -> AsyncOperationResult<Action> in
            do {
                try await Task.sleep(nanoseconds: UInt64(duration * 1_000_000_000))
                let action = try await operation()
                return .action(action)
            } catch {
                return .error(SendableError(error))
            }
        })
    }

    /// 스로틀 Effect: 일정 시간 간격으로만 실행
    static func throttle(
        id: CancelID,
        interval: TimeInterval,
        operation: @escaping @Sendable () async throws -> Action
    ) -> AsyncEffect<Action, CancelID> {
        return .run(id: id, operation: AsyncOperation { () async -> AsyncOperationResult<Action> in
            do {
                try await Task.sleep(nanoseconds: UInt64(interval * 1_000_000_000))
                let action = try await operation()
                return .action(action)
            } catch {
                return .error(SendableError(error))
            }
        })
    }
}
