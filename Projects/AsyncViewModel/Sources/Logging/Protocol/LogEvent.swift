//
//  LogEvent.swift
//  AsyncViewModel
//
//  Created by jimmy on 2025/01/20.
//

import Foundation

// MARK: - LogEvent

/// 로그 이벤트 타입
///
/// ViewModel에서 발생하는 다양한 로그 이벤트를 나타냅니다.
/// Interceptor는 이 이벤트를 받아서 원하는 방식으로 처리할 수 있습니다.
public enum LogEvent: Sendable {
    /// Action 로그
    ///
    /// - Parameter action: Action 정보
    case action(ActionInfo)

    /// State 변경 로그
    ///
    /// - Parameter stateChange: State 변경 정보
    case stateChange(StateChangeInfo)

    /// 단일 Effect 로그
    ///
    /// - Parameter effect: Effect 정보
    case effect(EffectInfo)

    /// 여러 Effect 로그
    ///
    /// - Parameter effects: Effect 정보 배열
    case effects([EffectInfo])

    /// 성능 로그
    ///
    /// - Parameter performance: 성능 측정 정보
    case performance(PerformanceInfo)

    /// 에러 로그
    ///
    /// - Parameter error: 에러 정보
    case error(SendableError)
}
