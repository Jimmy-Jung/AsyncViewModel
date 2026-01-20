//
//  TraceKitViewModelLogger.swift
//  AsyncViewModel
//
//  Created by jimmy on 2025/12/18.
//

import AsyncViewModel
import Foundation
import TraceKit

// LogLevel removed - using category-based logging instead

@MainActor
public struct TraceKitViewModelLogger: ViewModelLogger {
    public var options: LoggingOptions = .init()

    public init() {}

    public func logAction(
        _ action: String,
        viewModel: String,
        file: String,
        function: String,
        line: Int
    ) {
        // LogCategory.action → info
        switch options.actionFormat {
        case .compact:
            let message = "\(action)"
            TraceKit.log(
                level: .info,
                message,
                category: viewModel,
                file: file,
                function: function,
                line: line
            )

        case .standard, .detailed:
            let message = "Action: \(action)"
            TraceKit.log(
                level: .info,
                message,
                category: viewModel,
                metadata: [
                    "type": .init("action"),
                    "action": .init(action),
                ],
                file: file,
                function: function,
                line: line
            )
        }
    }

    public func logStateChange(
        from oldState: String,
        to newState: String,
        viewModel: String,
        file: String,
        function: String,
        line: Int
    ) {
        let message = "State changed from:\n\(oldState)\n\nto:\n\(newState)"
        TraceKit.log(
            level: .info,
            message,
            category: viewModel,
            metadata: [
                "type": .init("state_change"),
                "old_state": .init(oldState),
                "new_state": .init(newState),
            ],
            file: file,
            function: function,
            line: line
        )
    }

    public func logEffect(
        _ effect: String,
        viewModel: String,
        file: String,
        function: String,
        line: Int
    ) {
        // LogCategory.effect → debug
        let message = "Effect: \(effect)"
        TraceKit.log(
            level: .debug,
            message,
            category: viewModel,
            metadata: [
                "type": .init("effect"),
                "effect": .init(effect),
            ],
            file: file,
            function: function,
            line: line
        )
    }

    public func logEffects(
        _ effects: [String],
        viewModel: String,
        file: String,
        function: String,
        line: Int
    ) {
        // LogCategory.effect → debug
        switch options.effectFormat {
        case .compact:
            let message = "[\(effects.count) effects]"
            TraceKit.log(
                level: .debug,
                message,
                category: viewModel,
                file: file,
                function: function,
                line: line
            )

        case .standard:
            let summary = effects.map { effect in
                effect.split(separator: "(").first.map(String.init) ?? effect
            }.joined(separator: ", ")

            let message = "Effects[\(effects.count)]: \(summary)"
            TraceKit.log(
                level: .debug,
                message,
                category: viewModel,
                metadata: ["effect_count": .init(effects.count)],
                file: file,
                function: function,
                line: line
            )

        case .detailed:
            for (index, effect) in effects.enumerated() {
                let message = "Effect \(index + 1)/\(effects.count): \(effect)"
                TraceKit.log(
                    level: .verbose,
                    message,
                    category: viewModel,
                    metadata: [
                        "type": .init("effect"),
                        "effect": .init(effect),
                        "index": .init(index),
                        "total": .init(effects.count),
                    ],
                    file: file,
                    function: function,
                    line: line
                )
            }
        }
    }

    public func logPerformance(
        operation: String,
        duration: TimeInterval,
        viewModel: String,
        file: String,
        function: String,
        line: Int
    ) {
        let (threshold, shouldWarn) = calculatePerformanceThreshold(operation: operation, duration: duration)

        if !options.showZeroPerformance, duration < threshold {
            return
        }

        // LogCategory.performance → debug (임계값 초과 시 warning)
        let finalLevel: TraceLevel = shouldWarn ? .warning : .debug

        switch options.actionFormat {
        case .compact:
            let icon = shouldWarn ? "⚠️" : "⚡️"
            let message = "\(icon) \(String(format: "%.3f", duration))s"
            TraceKit.log(
                level: finalLevel,
                message,
                category: viewModel,
                file: file,
                function: function,
                line: line
            )

        case .standard, .detailed:
            let prefix = shouldWarn ? "⚠️ SLOW" : "Performance"
            let message = "\(prefix) - \(operation): \(String(format: "%.3f", duration))s (threshold: \(String(format: "%.3f", threshold))s)"
            TraceKit.log(
                level: finalLevel,
                message,
                category: viewModel,
                metadata: [
                    "type": .init("performance"),
                    "operation": .init(operation),
                    "duration": .init(duration),
                    "threshold": .init(threshold),
                    "exceeded": .init(shouldWarn),
                ],
                file: file,
                function: function,
                line: line
            )
        }
    }

    public func logError(
        _ error: SendableError,
        viewModel: String,
        file: String,
        function: String,
        line: Int
    ) {
        // LogCategory.error → error
        let message = "Error: \(error.localizedDescription) [\(error.domain):\(error.code)]"
        TraceKit.log(
            level: .error,
            message,
            category: viewModel,
            metadata: [
                "type": .init("error"),
                "error_description": .init(error.localizedDescription),
                "error_domain": .init(error.domain),
                "error_code": .init(error.code),
            ],
            file: file,
            function: function,
            line: line
        )
    }

    // MARK: - Private Helpers

    private func formatCompactStateDiff(_ changes: [String: (old: String, new: String)]) -> String {
        let sortedChanges = changes.sorted(by: { $0.key < $1.key })

        let simpleChanges = sortedChanges.filter { _, values in
            !values.old.contains("(") && !values.new.contains("(")
        }

        let complexChanges = sortedChanges.filter { _, values in
            values.old.contains("(") || values.new.contains("(")
        }

        var messageParts: [String] = []

        if !simpleChanges.isEmpty {
            let simpleSummary = simpleChanges.map { key, values in
                "\(key): \(values.old) → \(values.new)"
            }.joined(separator: ", ")
            messageParts.append(simpleSummary)
        }

        if !complexChanges.isEmpty {
            let complexSummary = complexChanges.map { key, _ in
                "\(key) changed"
            }.joined(separator: ", ")
            messageParts.append("[\(complexSummary)]")
        }

        return messageParts.joined(separator: " ")
    }

    private func calculatePerformanceThreshold(operation: String, duration: TimeInterval) -> (threshold: TimeInterval, shouldWarn: Bool) {
        let threshold: TimeInterval
        let shouldWarn: Bool

        if let performanceThreshold = options.performanceThreshold {
            threshold = performanceThreshold.threshold
            shouldWarn = duration >= threshold
        } else {
            let operationType = PerformanceThreshold.infer(from: operation)
            threshold = operationType.recommendedThreshold
            shouldWarn = duration >= threshold
        }

        return (threshold, shouldWarn)
    }
}
