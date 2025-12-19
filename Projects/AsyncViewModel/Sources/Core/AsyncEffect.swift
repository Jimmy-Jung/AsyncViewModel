//
//  AsyncEffect.swift
//  AsyncViewModel
//
//  Created by 정준영 on 2025/8/7.
//

import Foundation

/// ViewModel에서 반환할 수 있는 효과(Effect)를 정의합니다.
///
/// Effect는 선언적이며, 실제 실행은 ViewModel이 담당합니다.
/// Equatable이므로 테스트에서 검증할 수 있으며, Sendable이므로 동시성 환경에서 안전합니다.
public enum AsyncEffect<Action: Equatable & Sendable, CancelID: Hashable & Sendable>: Equatable, Sendable {
    case none
    case action(Action)
    case run(id: CancelID? = nil, operation: AsyncOperation<Action>)
    case cancel(id: CancelID)
    
    /// 여러 Effect를 병렬로 실행합니다.
    ///
    /// 처리 전략:
    /// - .run 효과들의 operation은 백그라운드에서 진짜 병렬로 실행됩니다.
    /// - 모든 operation 결과를 수집한 후 MainActor에서 순차 처리됩니다.
    /// - .action, .cancel 등 다른 효과들은 순차적으로 처리됩니다.
    ///
    /// 사용 예시:
    /// ```swift
    /// return .concurrent([
    ///     .run { try await api.fetchUser() },
    ///     .run { try await api.fetchPosts() },
    ///     .run { try await api.fetchComments() }
    /// ])
    /// ```
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
        case let (.concurrent(lhsEffects), .concurrent(rhsEffects)):
            return lhsEffects == rhsEffects
        default:
            return false
        }
    }
}

// MARK: - Convenience Extensions

public extension AsyncEffect {
    static func concurrent(_ effects: AsyncEffect<Action, CancelID>...) -> AsyncEffect<Action, CancelID> {
        return .concurrent(effects)
    }

    static func run(
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
    
    static func runCatchingError(
        id: CancelID? = nil,
        errorAction: @escaping @Sendable (SendableError) -> Action,
        operation: @escaping @Sendable () async throws -> Action
    ) -> AsyncEffect<Action, CancelID> {
        return .run(id: id, operation: AsyncOperation { () async -> AsyncOperationResult<Action> in
            do {
                let action = try await operation()
                return .action(action)
            } catch {
                return .action(errorAction(SendableError(error)))
            }
        })
    }

    // MARK: - Time-based Effects

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

    /// 디바운스 Effect: 연속된 호출에서 마지막 호출만 실행
    ///
    /// 동작 방식:
    /// ```
    /// 0ms:   'a' 입력 → debounce 시작
    /// 100ms: 'b' 입력 → 이전 취소, 새로 시작
    /// 200ms: 'c' 입력 → 이전 취소, 새로 시작
    /// 700ms: (500ms 경과) → 검색 실행! "abc"
    /// ```
    ///
    /// 사용 예시:
    /// ```swift
    /// case let .searchTextChanged(query):
    ///     state.query = query
    ///     return [
    ///         .cancel(id: .search),
    ///         .debounce(id: .search, for: 0.5) {
    ///             try await searchAPI.search(query)
    ///         }
    ///     ]
    /// ```
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

    /// 스로틀 Effect: 일정 시간 간격으로만 실행을 허용
    ///
    /// 동작 방식:
    /// ```
    /// Debounce (마지막만 실행):
    /// 입력: •••••••••••••••••
    /// 실행:                  ✓
    ///
    /// Throttle (간격마다 실행):
    /// 입력: •••••••••••••••••
    /// 실행: ✓      ✓      ✓
    /// ```
    ///
    /// 사용 예시:
    /// ```swift
    /// case .scrollPositionChanged(let position):
    ///     state.scrollPosition = position
    ///     return [
    ///         .cancel(id: .trackScroll),
    ///         .throttle(id: .trackScroll, interval: 0.5) {
    ///             try await analytics.trackScroll(position)
    ///         }
    ///     ]
    /// ```
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
