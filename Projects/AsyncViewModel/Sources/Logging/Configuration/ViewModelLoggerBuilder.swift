//
//  ViewModelLoggerBuilder.swift
//  AsyncViewModel
//
//  Created by jimmy on 2025/12/29.
//

import Foundation

@MainActor
public final class ViewModelLoggerBuilder: @unchecked Sendable {
    private var logger: (any ViewModelLogger)?
    private var options: LoggingOptions

    public init() {
        self.options = LoggingOptions()
    }

    @discardableResult
    public func addLogger(_ logger: any ViewModelLogger) -> Self {
        self.logger = logger
        return self
    }

    @discardableResult
    public func withFormat(_ format: LogFormat) -> Self {
        options.format = format
        return self
    }

    @discardableResult
    public func withPerformanceThreshold(_ threshold: PerformanceThreshold?) -> Self {
        options.performanceThreshold = threshold
        return self
    }

    @discardableResult
    public func withStateDiffOnly(_ enabled: Bool = true) -> Self {
        options.showStateDiffOnly = enabled
        return self
    }

    @discardableResult
    public func withGroupEffects(_ enabled: Bool = true) -> Self {
        options.groupEffects = enabled
        return self
    }

    @discardableResult
    public func withZeroPerformance(_ enabled: Bool = true) -> Self {
        options.showZeroPerformance = enabled
        return self
    }

    @discardableResult
    public func withMinimumLevel(_ level: LogLevel) -> Self {
        options.minimumLevel = level
        return self
    }

    public func build() -> any ViewModelLogger {
        guard var logger = logger else {
            return NoOpLogger()
        }

        logger.options = options
        return logger
    }

    @discardableResult
    public func buildAsShared() -> any ViewModelLogger {
        let logger = build()
        LoggerConfiguration.setLogger(logger)
        return logger
    }
}

public extension ViewModelLoggerBuilder {
    static func debug() -> ViewModelLoggerBuilder {
        ViewModelLoggerBuilder()
            .addLogger(OSLogViewModelLogger())
            .withFormat(.detailed)
            .withMinimumLevel(.verbose)
            .withStateDiffOnly(false)
            .withGroupEffects(false)
            .withZeroPerformance(true)
    }

    static func production() -> ViewModelLoggerBuilder {
        ViewModelLoggerBuilder()
            .addLogger(OSLogViewModelLogger())
            .withFormat(.compact)
            .withMinimumLevel(.warning)
            .withStateDiffOnly(true)
            .withGroupEffects(true)
            .withZeroPerformance(false)
    }

    static func disabled() -> ViewModelLoggerBuilder {
        ViewModelLoggerBuilder()
            .addLogger(NoOpLogger())
    }
}
