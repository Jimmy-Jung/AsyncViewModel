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
        file _: String,
        function _: String,
        line _: Int
    ) {
        let logger = createLogger(category: viewModel)
        let message = "Action: \(action)"
        // LogCategory.action → info
        logger.info("\(message, privacy: .public)")
    }

    public func logStateChange(
        _ stateChange: StateChangeInfo,
        viewModel: String,
        file _: String,
        function _: String,
        line _: Int
    ) {
        let logger = createLogger(category: viewModel)

        switch options.stateFormat {
        case .compact:
            // 변경된 프로퍼티만 한 줄로 출력
            if stateChange.changes.isEmpty {
                logger.info("State: no changes")
            } else {
                let changedProps = stateChange.changes.map { change in
                    "\(change.propertyName): \(change.oldValue.value) → \(change.newValue.value)"
                }.joined(separator: ", ")
                let message = "State: \(changedProps)"
                logger.info("\(message, privacy: .public)")
            }

        case .standard:
            // 변경 정보를 구조화된 형태로 출력
            if stateChange.changes.isEmpty {
                logger.info("State unchanged")
            } else {
                let changeDescriptions = stateChange.changes.map { change in
                    "  \(change.propertyName): \(change.oldValue.value) → \(change.newValue.value)"
                }.joined(separator: "\n")
                let message = "State changed (\(stateChange.changes.count) properties):\n\(changeDescriptions)"
                logger.info("\(message, privacy: .public)")
            }

        case .detailed:
            // 전체 State 구조를 출력
            let oldStateStr = stateChange.oldState.detailedDescription
            let newStateStr = stateChange.newState.detailedDescription

            if stateChange.changes.isEmpty {
                logger.info("State unchanged:\n\(newStateStr, privacy: .public)")
            } else {
                let changeDescriptions = stateChange.changes.map { change in
                    "  \(change.propertyName) (\(change.oldValue.typeName)):\n    old: \(change.oldValue.value)\n    new: \(change.newValue.value)"
                }.joined(separator: "\n")

                let message = """
                State changed (\(stateChange.changes.count) properties):
                \(changeDescriptions)

                Full state:
                \(newStateStr)
                """
                logger.info("\(message, privacy: .public)")
            }
        }
    }

    public func logEffect(
        _ effect: String,
        viewModel: String,
        file _: String,
        function _: String,
        line _: Int
    ) {
        let logger = createLogger(category: viewModel)
        // LogCategory.effect → debug
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
        // LogCategory.effect → debug

        switch options.effectFormat {
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

    public func logPerformance(
        operation: String,
        duration: TimeInterval,
        viewModel: String,
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

        // LogCategory.performance → debug (임계값 초과 시 warning)
        if duration >= threshold {
            logger.warning("\(message, privacy: .public)")
        } else {
            logger.debug("\(message, privacy: .public)")
        }
    }

    public func logError(
        _ error: SendableError,
        viewModel: String,
        file _: String,
        function _: String,
        line _: Int
    ) {
        let logger = createLogger(category: viewModel)
        let message = "Error: \(error.localizedDescription) [\(error.domain):\(error.code)]"
        // LogCategory.error → error
        logger.error("\(message, privacy: .public)")
    }

    private func createLogger(category: String) -> os.Logger {
        os.Logger(subsystem: subsystem, category: category)
    }
}
