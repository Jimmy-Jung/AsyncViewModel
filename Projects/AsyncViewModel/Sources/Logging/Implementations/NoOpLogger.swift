//
//  NoOpLogger.swift
//  AsyncViewModel
//
//  Created by jimmy on 2025/12/19.
//

import Foundation

// MARK: - NoOpLogger

/// 아무 것도 출력하지 않는 로거
///
/// 로깅을 비활성화하고 싶을 때 사용합니다.
/// 프로덕션 빌드나 테스트에서 로그 출력을 억제할 때 유용합니다.
public struct NoOpLogger: ViewModelLogger {
    public var options: LoggingOptions = .init()

    public init() {}

    public func logAction(
        _: ActionInfo,
        viewModel _: String,
        file _: String,
        function _: String,
        line _: Int
    ) {}

    public func logStateChange(
        _: StateChangeInfo,
        viewModel _: String,
        file _: String,
        function _: String,
        line _: Int
    ) {}

    public func logEffect(
        _: EffectInfo,
        viewModel _: String,
        file _: String,
        function _: String,
        line _: Int
    ) {}

    public func logEffects(
        _: [EffectInfo],
        viewModel _: String,
        file _: String,
        function _: String,
        line _: Int
    ) {}

    public func logPerformance(
        _: PerformanceInfo,
        viewModel _: String,
        file _: String,
        function _: String,
        line _: Int
    ) {}

    public func logError(
        _: SendableError,
        viewModel _: String,
        file _: String,
        function _: String,
        line _: Int
    ) {}
}
