//
//  LogFormatter.swift
//  AsyncViewModel
//
//  Created by jimmy on 2025/01/21.
//

import Foundation

// MARK: - LogFormatter

/// 로그 포맷터 프로토콜
///
/// LoggingOptions에 따라 구조화된 로그 데이터를 문자열로 변환합니다.
/// ViewModelLogger 구현체는 이 프로토콜을 사용하여 포맷팅을 위임합니다.
///
/// ## 사용 예시
///
/// ```swift
/// let formatter = DefaultLogFormatter()
/// let message = formatter.formatAction(actionInfo, format: .standard)
/// print(message)  // "fetchData(id: 123)"
/// ```
public protocol LogFormatter: Sendable {
    /// Action 정보를 문자열로 포맷팅
    ///
    /// - Parameters:
    ///   - action: Action 정보
    ///   - format: 로그 포맷 (compact, standard, detailed)
    /// - Returns: 포맷팅된 문자열
    func formatAction(
        _ action: ActionInfo,
        format: LogFormat
    ) -> String

    /// State 변경 정보를 문자열로 포맷팅
    ///
    /// - Parameters:
    ///   - stateChange: State 변경 정보
    ///   - format: 로그 포맷 (compact, standard, detailed)
    /// - Returns: 포맷팅된 문자열
    func formatStateChange(
        _ stateChange: StateChangeInfo,
        format: LogFormat
    ) -> String

    /// 단일 Effect 정보를 문자열로 포맷팅
    ///
    /// - Parameters:
    ///   - effect: Effect 정보
    ///   - format: 로그 포맷 (compact, standard, detailed)
    /// - Returns: 포맷팅된 문자열
    func formatEffect(
        _ effect: EffectInfo,
        format: LogFormat
    ) -> String

    /// 여러 Effect 정보를 문자열로 포맷팅
    ///
    /// - Parameters:
    ///   - effects: Effect 정보 배열
    ///   - format: 로그 포맷 (compact, standard, detailed)
    /// - Returns: 포맷팅된 문자열 배열 (detailed일 때 개별 출력용)
    func formatEffects(
        _ effects: [EffectInfo],
        format: LogFormat
    ) -> [String]

    /// 성능 정보를 문자열로 포맷팅
    ///
    /// - Parameters:
    ///   - performance: 성능 측정 정보
    ///   - options: 로깅 옵션 (임계값, showZeroPerformance 등)
    /// - Returns: 포맷팅된 문자열 (nil이면 로깅하지 않음)
    func formatPerformance(
        _ performance: PerformanceInfo,
        options: LoggingOptions
    ) -> String?

    /// 에러 정보를 문자열로 포맷팅
    ///
    /// - Parameter error: 에러 정보
    /// - Returns: 포맷팅된 문자열
    func formatError(_ error: SendableError) -> String
}
