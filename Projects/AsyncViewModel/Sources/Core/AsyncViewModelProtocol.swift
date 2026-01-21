//
//  AsyncViewModelProtocol.swift
//  AsyncViewModel
//
//  Created by 정준영 on 2025/8/3.
//

import Foundation
import os.log

// MARK: - AsyncViewModelProtocol

/// 개선된 비동기 작업을 처리하는 ViewModel 프로토콜
///
/// 단방향 데이터 흐름을 위한 비동기 방식의 ViewModel입니다.
/// Input -> Action -> Reduce -> State 업데이트 + Effect 흐름으로 데이터가 처리됩니다.
@MainActor
public protocol AsyncViewModelProtocol: ObservableObject {
    associatedtype Input: Sendable
    associatedtype Action: Equatable & Sendable
    associatedtype State: Equatable & Sendable
    associatedtype CancelID: Hashable & Sendable

    var state: State { get set }
    var tasks: [CancelID: Task<Void, Never>] { get set }
    var effectQueue: [AsyncEffect<Action, CancelID>] { get set }
    var isProcessingEffects: Bool { get set }
    var timer: any AsyncTimer { get set }
    var actionObserver: ((Action) -> Void)? { get set }
    var stateChangeObserver: ((State, State) -> Void)? { get set }
    var effectObserver: ((AsyncEffect<Action, CancelID>) -> Void)? { get set }
    var performanceObserver: ((String, TimeInterval) -> Void)? { get set }

    /// ViewModel별 로깅 설정 (매크로가 자동 생성)
    var loggingConfig: ViewModelLoggingConfig { get }

    func send(_ input: Input)
    func transform(_ input: Input) -> [Action]
    func reduce(state: inout State, action: Action) -> [AsyncEffect<Action, CancelID>]
    func handleError(_ error: SendableError)
}

// MARK: - Default Implementation

public extension AsyncViewModelProtocol {
    /// 기본 로깅 설정 (매크로가 생성하지 않은 경우)
    var loggingConfig: ViewModelLoggingConfig {
        .default
    }

    func send(_ input: Input) {
        let actions = transform(input)
        for action in actions {
            perform(action)
        }
    }

    /// Action을 직접 실행합니다.
    ///
    /// ⚠️ **주의**: 이 메서드는 ViewModel 내부에서만 사용해야 합니다.
    ///
    /// 외부에서 ViewModel과 상호작용할 때는 반드시 `send(_:)` 메서드를 사용하세요.
    /// `perform`은 다음과 같은 내부 용도로만 사용됩니다:
    /// - `handleError`에서 에러 처리 Action 실행
    /// - `reduce`에서 반환된 Effect의 Action 처리
    /// - 테스트 코드에서 직접 Action 주입
    ///
    /// **올바른 사용:**
    /// ```swift
    /// // ✅ 외부에서
    /// viewModel.send(.buttonTapped)
    ///
    /// // ✅ ViewModel 내부에서
    /// func handleError(_ error: SendableError) {
    ///     perform(.errorOccurred(error))
    /// }
    /// ```
    ///
    /// **잘못된 사용:**
    /// ```swift
    /// // ❌ 외부에서 직접 Action 호출
    /// viewModel.perform(.dataLoaded(data))
    /// ```
    ///
    /// - Parameter action: 실행할 Action
    func perform(_ action: Action) {
        let startTime = CFAbsoluteTimeGetCurrent()

        logAction(action)
        actionObserver?(action)

        let oldState = state
        let effects = reduce(state: &state, action: action)

        logStateChangeIfNeeded(from: oldState, to: state)
        effectQueue.append(contentsOf: effects)
        logEffectsIfNeeded(effects)

        let duration = CFAbsoluteTimeGetCurrent() - startTime
        logPerformance("Action processing", duration: duration)

        Task {
            await processNextEffect()
        }
    }

    func handleError(_: SendableError) {}
}
