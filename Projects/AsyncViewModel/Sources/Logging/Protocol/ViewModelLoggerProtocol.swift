//
//  ViewModelLoggerProtocol.swift
//  AsyncViewModel
//
//  Created by jimmy on 2025/12/19.
//

import Foundation

@MainActor
public protocol ViewModelLogger: Sendable {
    var options: LoggingOptions { get set }

    func logAction(
        _ action: String,
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

    func logEffect(
        _ effect: String,
        viewModel: String,
        file: String,
        function: String,
        line: Int
    )

    func logEffects(
        _ effects: [String],
        viewModel: String,
        file: String,
        function: String,
        line: Int
    )

    func logPerformance(
        operation: String,
        duration: TimeInterval,
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
        _ action: String,
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

    /// 구조화된 State 변경 로그
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
        _ effect: String,
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
        _ effects: [String],
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
        operation: String,
        duration: TimeInterval,
        viewModel: String,
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) {
        logPerformance(
            operation: operation,
            duration: duration,
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
