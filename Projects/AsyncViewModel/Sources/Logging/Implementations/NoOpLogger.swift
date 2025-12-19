//
//  NoOpLogger.swift
//  AsyncViewModel
//
//  Created by jimmy on 2025/12/19.
//

import Foundation

public struct NoOpLogger: ViewModelLogger {
    public var options: LoggingOptions = .init()

    public init() {}

    public func logAction(
        _: String,
        viewModel _: String,
        level _: LogLevel,
        file _: String,
        function _: String,
        line _: Int
    ) {}

    public func logStateChange(
        from _: String,
        to _: String,
        viewModel _: String,
        file _: String,
        function _: String,
        line _: Int
    ) {}

    public func logEffect(
        _: String,
        viewModel _: String,
        file _: String,
        function _: String,
        line _: Int
    ) {}

    public func logEffects(
        _: [String],
        viewModel _: String,
        file _: String,
        function _: String,
        line _: Int
    ) {}

    public func logStateDiff(
        changes _: [String: (old: String, new: String)],
        viewModel _: String,
        file _: String,
        function _: String,
        line _: Int
    ) {}

    public func logPerformance(
        operation _: String,
        duration _: TimeInterval,
        viewModel _: String,
        level _: LogLevel,
        file _: String,
        function _: String,
        line _: Int
    ) {}

    public func logError(
        _: SendableError,
        viewModel _: String,
        level _: LogLevel,
        file _: String,
        function _: String,
        line _: Int
    ) {}
}
