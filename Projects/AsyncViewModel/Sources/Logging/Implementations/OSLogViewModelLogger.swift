//
//  OSLogViewModelLogger.swift
//  AsyncViewModel
//
//  Created by jimmy on 2025/12/19.
//

import Foundation
import os.log

public struct OSLogViewModelLogger: ViewModelLogger {
    public var options: LoggingOptions = .init()
    private let subsystem: String

    public init(subsystem: String = "com.jimmy.AsyncViewModel") {
        self.subsystem = subsystem
    }

    public func logAction(
        _ action: String,
        viewModel: String,
        level: LogLevel,
        file _: String,
        function _: String,
        line _: Int
    ) {
        let logger = createLogger(category: viewModel)
        let message = "Action: \(action)"

        switch level {
        case .verbose, .debug:
            logger.debug("\(message, privacy: .public)")
        case .info:
            logger.info("\(message, privacy: .public)")
        case .warning:
            logger.warning("\(message, privacy: .public)")
        case .error:
            logger.error("\(message, privacy: .public)")
        case .fatal:
            logger.fault("\(message, privacy: .public)")
        }
    }

    public func logStateChange(
        from oldState: String,
        to newState: String,
        viewModel: String,
        file _: String,
        function _: String,
        line _: Int
    ) {
        let logger = createLogger(category: viewModel)
        logger.info("State changed from:\n\(oldState, privacy: .public)")
        logger.info("State changed to:\n\(newState, privacy: .public)")
    }

    public func logEffect(
        _ effect: String,
        viewModel: String,
        file _: String,
        function _: String,
        line _: Int
    ) {
        let logger = createLogger(category: viewModel)
        logger.debug("Effect: \(effect, privacy: .public)")
    }

    public func logEffects(
        _ effects: [String],
        viewModel: String,
        file _: String,
        function _: String,
        line _: Int
    ) {
        let logger = createLogger(category: viewModel)

        switch options.format {
        case .compact:
            let message = "\(effects.count) effects"
            logger.debug("\(message, privacy: .public)")

        case .standard:
            let summary = effects.map { effect in
                effect.split(separator: "(").first.map(String.init) ?? effect
            }.joined(separator: ", ")
            let message = "Effects[\(effects.count)]: \(summary)"
            logger.debug("\(message, privacy: .public)")

        case .detailed:
            for (index, effect) in effects.enumerated() {
                let message = "Effect \(index + 1)/\(effects.count): \(effect)"
                logger.debug("\(message, privacy: .public)")
            }
        }
    }

    public func logStateDiff(
        changes: [String: (old: String, new: String)],
        viewModel: String,
        file _: String,
        function _: String,
        line _: Int
    ) {
        let logger = createLogger(category: viewModel)

        switch options.format {
        case .compact:
            let summary = changes.keys.sorted().joined(separator: ", ")
            logger.info("State: \(summary, privacy: .public)")

        case .standard:
            let changeDescriptions = changes.sorted(by: { $0.key < $1.key }).map { key, values in
                "\(key): \(values.old) → \(values.new)"
            }.joined(separator: "\n  - ")
            let message = "State changed:\n  - \(changeDescriptions)"
            logger.info("\(message, privacy: .public)")

        case .detailed:
            let changeDescriptions = changes.sorted(by: { $0.key < $1.key }).map { key, values in
                "  \(key):\n    old: \(values.old)\n    new: \(values.new)"
            }.joined(separator: "\n")
            let message = "State changed:\n\(changeDescriptions)"
            logger.info("\(message, privacy: .public)")
        }
    }

    public func logPerformance(
        operation: String,
        duration: TimeInterval,
        viewModel: String,
        level: LogLevel,
        file _: String,
        function _: String,
        line _: Int
    ) {
        let threshold: TimeInterval
        if let performanceThreshold = options.performanceThreshold {
            threshold = performanceThreshold.threshold
        } else {
            let operationType = PerformanceThreshold.infer(from: operation)
            threshold = operationType.recommendedThreshold
        }

        if !options.showZeroPerformance, duration < threshold {
            return
        }

        let logger = createLogger(category: viewModel)
        let message = "Performance - \(operation): \(String(format: "%.3f", duration))s"

        switch level {
        case .verbose, .debug:
            logger.debug("\(message, privacy: .public)")
        case .info:
            logger.info("\(message, privacy: .public)")
        case .warning:
            logger.warning("\(message, privacy: .public)")
        case .error:
            logger.error("\(message, privacy: .public)")
        case .fatal:
            logger.fault("\(message, privacy: .public)")
        }
    }

    public func logError(
        _ error: SendableError,
        viewModel: String,
        level: LogLevel,
        file _: String,
        function _: String,
        line _: Int
    ) {
        let logger = createLogger(category: viewModel)
        let message = "Error: \(error.localizedDescription) [\(error.domain):\(error.code)]"

        switch level {
        case .verbose, .debug:
            logger.debug("\(message, privacy: .public)")
        case .info:
            logger.info("\(message, privacy: .public)")
        case .warning:
            logger.warning("\(message, privacy: .public)")
        case .error:
            logger.error("\(message, privacy: .public)")
        case .fatal:
            logger.fault("\(message, privacy: .public)")
        }
    }

    private func createLogger(category: String) -> os.Logger {
        os.Logger(subsystem: subsystem, category: category)
    }
}
