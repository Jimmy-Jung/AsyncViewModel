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
        level: LogLevel,
        file: String,
        function: String,
        line: Int
    )

    func logStateChange(
        from oldState: String,
        to newState: String,
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

    func logStateDiff(
        changes: [String: (old: String, new: String)],
        viewModel: String,
        file: String,
        function: String,
        line: Int
    )

    func logPerformance(
        operation: String,
        duration: TimeInterval,
        viewModel: String,
        level: LogLevel,
        file: String,
        function: String,
        line: Int
    )

    func logError(
        _ error: SendableError,
        viewModel: String,
        level: LogLevel,
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
        level: LogLevel = .info,
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) {
        logAction(
            action,
            viewModel: viewModel,
            level: level,
            file: file,
            function: function,
            line: line
        )
    }

    func logStateChange(
        from oldState: String,
        to newState: String,
        viewModel: String,
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) {
        logStateChange(
            from: oldState,
            to: newState,
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

    func logStateDiff(
        changes: [String: (old: String, new: String)],
        viewModel: String,
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) {
        logStateDiff(
            changes: changes,
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
        level: LogLevel = .info,
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) {
        logPerformance(
            operation: operation,
            duration: duration,
            viewModel: viewModel,
            level: level,
            file: file,
            function: function,
            line: line
        )
    }

    func logError(
        _ error: SendableError,
        viewModel: String,
        level: LogLevel = .error,
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) {
        logError(
            error,
            viewModel: viewModel,
            level: level,
            file: file,
            function: function,
            line: line
        )
    }
}
