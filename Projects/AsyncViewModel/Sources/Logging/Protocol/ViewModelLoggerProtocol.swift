//
//  ViewModelLoggerProtocol.swift
//  AsyncViewModel
//
//  Created by jimmy on 2025/12/19.
//

import Foundation

@MainActor
public protocol ViewModelLogger: Sendable {
    /// 로깅 옵션
    ///
    /// AsyncViewModelProtocol에서 ViewModel별 설정을 주입합니다.
    var options: LoggingOptions { get set }

    /// 구조화된 Action 로그
    ///
    /// ActionInfo를 통해 로거가 직접 포맷팅을 제어할 수 있습니다.
    func logAction(
        _ action: ActionInfo,
        viewModel: String,
        file: String,
        function: String,
        line: Int
    )

    /// 구조화된 State 변경 로그
    ///
    /// StateChangeInfo를 통해 로거가 직접 포맷팅을 제어할 수 있습니다.
    func logStateChange(
        _ stateChange: StateChangeInfo,
        viewModel: String,
        file: String,
        function: String,
        line: Int
    )

    /// 구조화된 단일 Effect 로그
    ///
    /// EffectInfo를 통해 로거가 직접 포맷팅을 제어할 수 있습니다.
    func logEffect(
        _ effect: EffectInfo,
        viewModel: String,
        file: String,
        function: String,
        line: Int
    )

    /// 구조화된 여러 Effect 로그
    ///
    /// EffectInfo 배열을 통해 로거가 직접 포맷팅을 제어할 수 있습니다.
    func logEffects(
        _ effects: [EffectInfo],
        viewModel: String,
        file: String,
        function: String,
        line: Int
    )

    /// 구조화된 성능 측정 로그
    ///
    /// PerformanceInfo를 통해 로거가 직접 포맷팅을 제어할 수 있습니다.
    func logPerformance(
        _ performance: PerformanceInfo,
        viewModel: String,
        file: String,
        function: String,
        line: Int
    )

    func logError(
        _ error: SendableError,
        viewModel: String,
        file: String,
        function: String,
        line: Int
    )
}

// MARK: - ViewModelLogger Extensions

public extension ViewModelLogger {
    func logAction(
        _ action: ActionInfo,
        viewModel: String,
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) {
        logAction(
            action,
            viewModel: viewModel,
            file: file,
            function: function,
            line: line
        )
    }

    func logStateChange(
        _ stateChange: StateChangeInfo,
        viewModel: String,
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) {
        logStateChange(
            stateChange,
            viewModel: viewModel,
            file: file,
            function: function,
            line: line
        )
    }

    func logEffect(
        _ effect: EffectInfo,
        viewModel: String,
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) {
        logEffect(
            effect,
            viewModel: viewModel,
            file: file,
            function: function,
            line: line
        )
    }

    func logEffects(
        _ effects: [EffectInfo],
        viewModel: String,
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) {
        logEffects(
            effects,
            viewModel: viewModel,
            file: file,
            function: function,
            line: line
        )
    }

    func logPerformance(
        _ performance: PerformanceInfo,
        viewModel: String,
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) {
        logPerformance(
            performance,
            viewModel: viewModel,
            file: file,
            function: function,
            line: line
        )
    }

    func logError(
        _ error: SendableError,
        viewModel: String,
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) {
        logError(
            error,
            viewModel: viewModel,
            file: file,
            function: function,
            line: line
        )
    }
}
