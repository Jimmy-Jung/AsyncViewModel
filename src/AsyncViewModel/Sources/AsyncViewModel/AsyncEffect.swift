//
//  AsyncEffect.swift
//  AsyncViewModel
//
//  Created by 정준영 on 2025/8/7.
//

import Foundation

/// ViewModel에서 반환할 수 있는 효과(Effect)를 정의합니다.
///
/// Effect는 상태 변경 외에 발생하는 부수 효과(Side Effect)를 나타냅니다.
/// 비동기 작업, 작업 취소, 다른 액션 트리거 등을 표현할 수 있습니다.
///
/// **핵심 원칙**:
/// - Effect는 선언적입니다. "무엇을 할지" 선언하고, 실제 실행은 ViewModel이 담당합니다.
/// - Effect는 Equatable이므로 테스트에서 검증할 수 있습니다.
/// - Effect는 Sendable이므로 동시성 환경에서 안전합니다.
public enum AsyncEffect<Action: Equatable & Sendable, CancelID: Hashable & Sendable>: Equatable, Sendable {
    /// 아무것도 하지 않습니다.
    ///
    /// 상태만 변경하고 추가 작업이 필요 없을 때 사용합니다.
    ///
    /// 사용 예시:
    /// ```swift
    /// case .updateCounter:
    ///     state.count += 1
    ///     return []  // 또는 [.none]
    /// ```
    case none
    
    /// 다른 액션을 즉시 실행합니다.
    ///
    /// 하나의 액션이 다른 액션을 트리거할 때 사용합니다.
    /// 액션 체이닝이나 워크플로우 구성에 유용합니다.
    ///
    /// 사용 예시:
    /// ```swift
    /// case .loginSuccess:
    ///     state.isLoggedIn = true
    ///     return [.action(.loadUserProfile)]
    ///     // 로그인 후 자동으로 프로필 로드
    /// ```
    case action(Action)
    
    /// 비동기 작업을 실행합니다.
    ///
    /// 네트워크 요청, 파일 I/O, 데이터베이스 작업 등 비동기 작업을 실행합니다.
    /// 직접 사용하기보다는 편의 메서드를 사용하세요.
    ///
    /// - Parameters:
    ///   - id: 작업을 식별하고 취소하기 위한 고유 ID (선택적)
    ///   - operation: AsyncOperation 인스턴스
    ///
    case run(id: CancelID? = nil, operation: AsyncOperation<Action>)
    
    /// 특정 ID를 가진 작업을 취소합니다.
    ///
    /// 진행 중인 비동기 작업을 중단할 때 사용합니다.
    /// 검색 취소, 타임아웃, 사용자의 명시적 취소 등에 활용됩니다.
    ///
    /// 사용 예시:
    /// ```swift
    /// case .cancelSearch:
    ///     state.isSearching = false
    ///     return [.cancel(id: .search)]
    ///
    /// case .userNavigatedAway:
    ///     return [
    ///         .cancel(id: .dataLoad),
    ///         .cancel(id: .imageDownload)
    ///     ]
    /// ```
    ///
    /// - Note: 취소된 작업은 자동으로 tasks 딕셔너리에서 제거됩니다.
    case cancel(id: CancelID)
    
    
    /// 여러 Effect를 병렬로 실행합니다.
    ///
    /// **진정한 병렬 처리**:
    /// - `.run` 효과들의 operation은 백그라운드에서 진짜 병렬로 실행됩니다.
    /// - 네트워크 요청, 데이터베이스 쿼리 등이 동시에 처리됩니다.
    /// - 모든 operation이 완료된 후, 결과는 MainActor에서 순차적으로 처리됩니다.
    /// - `.action`, `.cancel` 등 다른 효과들은 순차적으로 처리됩니다.
    ///
    /// 사용 예시:
    /// ```swift
    /// // 3개의 네트워크 요청을 동시에 실행
    /// return .concurrent([
    ///     .run { try await api.fetchUser() },
    ///     .run { try await api.fetchPosts() },
    ///     .run { try await api.fetchComments() }
    /// ])
    ///
    /// // 성능 향상:
    /// // 순차: 500ms + 300ms + 200ms = 1000ms
    /// // 병렬: max(500ms, 300ms, 200ms) = 500ms ⚡
    /// ```
    ///
    /// - Important: 독립적인 작업만 병렬로 실행하세요. 순서가 중요한 작업은 배열로 순차 실행하세요.
    /// - Note: 가변 인자 버전인 `.concurrent(_:)` 편의 메서드를 사용하면 더 간편합니다.
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
    // MARK: - Basic Convenience Methods
    
    
    /// 여러 Effect를 병렬로 실행하는 편의 메서드 (가변 인자 버전)
    ///
    /// 배열 대신 가변 인자를 사용하여 더 간결한 문법을 제공합니다.
    /// `.run` 효과들의 operation은 백그라운드에서 진짜 병렬로 실행됩니다.
    ///
    /// - Parameter effects: 병렬로 실행할 Effect들
    /// - Returns: 병렬 실행 Effect
    ///
    /// 사용 예시:
    /// ```swift
    /// // 3개의 API 호출을 동시에 실행
    /// return .concurrent(
    ///     .run { try await api.fetchUser() },
    ///     .run { try await api.fetchPosts() },
    ///     .run { try await api.fetchComments() }
    /// )
    /// ```
    ///
    /// - Note: 독립적인 작업들을 병렬로 실행하면 성능이 크게 향상됩니다.
    static func concurrent(_ effects: AsyncEffect<Action, CancelID>...) -> AsyncEffect<Action, CancelID> {
        return .concurrent(effects)
    }


    
    // MARK: - Convenience Methods
    
    /// 단일 액션을 반환하는 비동기 작업을 실행하는 편의 메서드
    ///
    /// 가장 일반적으로 사용되는 편의 메서드입니다. 비동기 작업의 결과를
    /// Action으로 변환하고, 에러가 발생하면 자동으로 `handleError(_:)`를 호출합니다.
    ///
    /// - Parameters:
    ///   - id: 작업을 식별하고 취소하기 위한 고유 ID (선택적)
    ///   - operation: Action을 반환하는 비동기 클로저
    /// - Returns: 비동기 작업을 실행하는 Effect
    ///
    /// 사용 예시:
    /// ```swift
    /// case .loadUser:
    ///     return [
    ///         .run(id: .fetchUser) {
    ///             try await userAPI.fetch()
    ///         }
    ///     ]
    /// ```
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
    
    // MARK: - Error Handling Convenience Methods
    
    /// 에러를 Action으로 변환하는 비동기 작업을 실행하는 편의 메서드
    ///
    /// 에러가 발생하면 `handleError(_:)` 대신 제공된 `errorAction`으로 변환하여
    /// 에러를 상태의 일부로 관리할 수 있습니다. 프로덕션 앱에서 권장되는 패턴입니다.
    ///
    /// - Parameters:
    ///   - id: 작업을 식별하고 취소하기 위한 고유 ID (선택적)
    ///   - errorAction: SendableError를 Action으로 변환하는 클로저
    ///   - operation: Action을 반환하는 비동기 클로저
    /// - Returns: 에러 처리가 포함된 Effect
    ///
    /// 사용 예시:
    /// ```swift
    /// case .loadData:
    ///     state.isLoading = true
    ///     return [
    ///         .runCatchingError(
    ///             id: .dataLoad,
    ///             errorAction: { error in
    ///                 .loadFailed(error.localizedDescription)
    ///             }
    ///         ) {
    ///             let data = try await api.fetchData()
    ///             return .dataLoaded(data)
    ///         }
    ///     ]
    ///
    /// case let .loadFailed(message):
    ///     state.isLoading = false
    ///     state.errorMessage = message
    ///     return []
    /// ```
    ///
    /// **장점**:
    /// - 에러가 상태의 일부가 되어 UI에서 표시 가능
    /// - 테스트하기 쉬움
    /// - 액션 히스토리에 에러가 기록됨
    ///
    /// - Important: 프로덕션 환경에서는 이 메서드 사용을 권장합니다.
    /// - SeeAlso: `run(id:operation:)` - 기본 에러 처리 (로깅만)
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

    /// 지정된 시간만큼 대기하는 Effect
    ///
    /// 순수하게 대기만 하는 Effect입니다. 액션을 반환하지 않습니다.
    ///
    /// - Parameters:
    ///   - id: 작업을 식별하고 취소하기 위한 고유 ID (선택적)
    ///   - duration: 대기할 시간 (초 단위)
    /// - Returns: 대기 Effect
    ///
    /// 사용 예시:
    /// ```swift
    /// case .showNotification:
    ///     state.showNotification = true
    ///     return [
    ///         .sleep(for: 3.0),  // 3초 대기
    ///         .action(.hideNotification)
    ///     ]
    /// ```
    ///
    /// - Note: 대기 후 액션을 실행하려면 `sleepThen(for:action:)`을 사용하세요.
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
    ///
    /// `sleep(for:)` + `action(_:)`의 조합을 간편하게 사용할 수 있습니다.
    ///
    /// - Parameters:
    ///   - id: 작업을 식별하고 취소하기 위한 고유 ID (선택적)
    ///   - duration: 대기할 시간 (초 단위)
    ///   - action: 대기 후 실행할 액션
    /// - Returns: 대기 후 액션을 실행하는 Effect
    ///
    /// 사용 예시:
    /// ```swift
    /// case .showTemporaryMessage:
    ///     state.message = "저장되었습니다"
    ///     state.showMessage = true
    ///     return [
    ///         .sleepThen(for: 3.0, action: .hideMessage)
    ///     ]
    ///
    /// // vs 기존 방식
    /// return [
    ///     .sleep(for: 3.0),
    ///     .action(.hideMessage)
    /// ]  // sleepThen이 더 명확!
    /// ```
    ///
    /// - Note: 타이머나 지연된 액션 실행에 유용합니다.
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
    /// 사용자 입력이 완료될 때까지 기다렸다가 실행합니다.
    /// 검색, 자동 저장, 실시간 유효성 검사 등에 유용합니다.
    ///
    /// - Parameters:
    ///   - id: 작업을 식별하기 위한 고유 ID (필수)
    ///   - duration: 대기할 시간 (초 단위)
    ///   - operation: Action을 반환하는 비동기 클로저
    /// - Returns: 디바운스 Effect
    ///
    /// 동작 방식:
    /// ```
    /// 시간 →
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
    ///         .cancel(id: .search),  // 이전 검색 취소
    ///         .debounce(id: .search, for: 0.5) {
    ///             try await searchAPI.search(query)
    ///         }
    ///     ]
    /// ```
    ///
    /// **권장 debounce 시간**:
    /// - 검색: 0.3 ~ 0.5초
    /// - 자동 저장: 1.0 ~ 2.0초
    /// - 유효성 검사: 0.3초
    ///
    /// - Important: 같은 ID로 이전 작업을 취소하는 방식이므로 ID는 필수입니다.
    /// - SeeAlso: `throttle(id:interval:operation:)` - 일정 간격으로 실행
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
    /// 같은 ID로 여러 번 호출되면 이전 것이 취소되고 마지막 것만 실행됩니다.
    /// 스크롤 이벤트, 버튼 연타 방지, 실시간 차트 업데이트 등에 유용합니다.
    ///
    /// - Parameters:
    ///   - id: 작업을 식별하기 위한 고유 ID (필수)
    ///   - interval: 실행 간격 (초 단위)
    ///   - operation: Action을 반환하는 비동기 클로저
    /// - Returns: 스로틀 Effect
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
    ///
    /// **권장 interval 시간**:
    /// - 스크롤 추적: 0.3 ~ 0.5초
    /// - 버튼 연타 방지: 0.5 ~ 1.0초
    /// - 실시간 차트: 0.1 ~ 0.3초
    ///
    /// - Note: 현재 구현은 "Trailing Throttle" 방식입니다. 같은 ID로 이전 작업을 
    ///   취소하고 새로운 작업을 시작하므로, 실제로는 debounce와 유사하게 동작합니다.
    ///   연속된 호출에서 마지막 호출이 interval 이후에 실행됩니다.
    /// - Important: 같은 ID로 이전 작업을 취소하는 방식이므로 ID는 필수입니다.
    /// - SeeAlso: `debounce(id:for:operation:)` - 마지막 호출만 실행
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
