//
//  TraceKitViewModelLogger.swift
//  AsyncViewModel
//
//  Created by jimmy on 2025/12/18.
//

import Foundation
import TraceKit

// MARK: - LogLevel to TraceLevel Mapping

extension LogLevel {
    /// LogLevel을 TraceLevel로 변환
    /// - Note: LogLevel과 TraceLevel이 동일한 구조를 가지므로 1:1 매핑
    var traceLevel: TraceLevel {
        switch self {
        case .verbose:
            return .verbose
        case .debug:
            return .debug
        case .info:
            return .info
        case .warning:
            return .warning
        case .error:
            return .error
        case .fatal:
            return .fatal
        }
    }
}

// MARK: - TraceKitViewModelLogger

/// TraceKit을 ViewModelLogger로 브릿지하는 구현체
///
/// ## 사용 방법
///
/// ### 1. TraceKit 초기화 및 설정
/// ```swift
/// @main
/// struct MyApp: App {
///     init() {
///         Task { @TraceKitActor in
///             // TraceKit을 공유 인스턴스로 빌드
///             await TraceKitBuilder
///                 .debug()
///                 .buildAsShared()
///         }
///
///         Task { @MainActor in
///             // TraceKitViewModelLogger를 전역 기본 로거로 설정
///             var logger = TraceKitViewModelLogger()
///
///             // 옵션 커스터마이징
///             logger.options.format = .standard
///             logger.options.performanceThreshold = 0.010 // 10ms
///             logger.options.showStateDiffOnly = true
///             logger.options.groupEffects = true
///
///             LoggerConfiguration.setLogger(logger)
///         }
///     }
/// }
/// ```
///
/// ### 2. ViewModel에서 사용
/// ```swift
/// @Observable
/// final class MyViewModel: AsyncViewModelProtocol {
///     // logger 프로퍼티를 nil로 두면 전역 기본 로거 사용
///     let logger: (any ViewModelLogger)? = nil
///
///     // ... 나머지 구현
/// }
/// ```
@MainActor
public struct TraceKitViewModelLogger: ViewModelLogger {
    public var options: LoggingOptions = .init()

    /// 초기화
    public init() {}

    // MARK: - ViewModelLogger Protocol

    public func logAction(
        _ action: String,
        viewModel: String,
        level: LogLevel,
        file: String,
        function: String,
        line: Int
    ) {
        // 레벨 필터링
        guard level.rawValue >= options.minimumLevel.rawValue else { return }

        switch options.format {
        case .compact:
            // 간결: 메시지만, metadata 최소화
            let message = "\(action)"
            TraceKit.log(
                level: level.traceLevel,
                message,
                category: viewModel,
                file: file,
                function: function,
                line: line
            )

        case .standard, .detailed:
            // 기존 방식
            let message = "Action: \(action)"
            TraceKit.log(
                level: level.traceLevel,
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
        // 레벨 필터링
        guard LogLevel.debug.rawValue >= options.minimumLevel.rawValue else { return }

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
        // 레벨 필터링
        guard LogLevel.debug.rawValue >= options.minimumLevel.rawValue else { return }

        switch options.format {
        case .compact:
            // 간결: 개수만 표시, metadata 없음
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
                // "cancel(id: ...)" -> "cancel"
                // "action(...)" -> "action"
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

    public func logStateDiff(
        changes: [String: (old: String, new: String)],
        viewModel: String,
        file: String,
        function: String,
        line: Int
    ) {
        // 레벨 필터링
        guard LogLevel.info.rawValue >= options.minimumLevel.rawValue else { return }

        switch options.format {
        case .compact:
            // 간결: 변경된 필드만, 각 줄로 구분하여 가독성 향상
            // primitive 값과 complex 값 분리
            let sortedChanges = changes.sorted(by: { $0.key < $1.key })

            // 간단한 값들 (한 줄에 표시)
            let simpleChanges = sortedChanges.filter { _, values in
                // CalculatorState 같은 complex type 제외
                !values.old.contains("(") && !values.new.contains("(")
            }

            // 복잡한 값들 (별도 표시 또는 생략)
            let complexChanges = sortedChanges.filter { _, values in
                values.old.contains("(") || values.new.contains("(")
            }

            // 출력 메시지 구성
            var messageParts: [String] = []

            // 간단한 변경사항
            if !simpleChanges.isEmpty {
                let simpleSummary = simpleChanges.map { key, values in
                    "\(key): \(values.old) → \(values.new)"
                }.joined(separator: ", ")
                messageParts.append(simpleSummary)
            }

            // 복잡한 변경사항 (타입명만 표시)
            if !complexChanges.isEmpty {
                let complexSummary = complexChanges.map { key, _ in
                    "\(key) changed"
                }.joined(separator: ", ")
                messageParts.append("[\(complexSummary)]")
            }

            let message = messageParts.joined(separator: " ")

            TraceKit.log(
                level: .info,
                message,
                category: viewModel,
                file: file,
                function: function,
                line: line
            )

        case .standard:
            let changeDescriptions = changes.sorted(by: { $0.key < $1.key }).map { key, values in
                "\(key): \(values.old) → \(values.new)"
            }.joined(separator: "\n  - ")

            let message = "State changed:\n  - \(changeDescriptions)"

            var metadata: [String: AnyCodable] = ["type": AnyCodable("state_change")]
            for (key, values) in changes {
                metadata["old_\(key)"] = AnyCodable(values.old)
                metadata["new_\(key)"] = AnyCodable(values.new)
            }

            TraceKit.log(
                level: .info,
                message,
                category: viewModel,
                metadata: metadata,
                file: file,
                function: function,
                line: line
            )

        case .detailed:
            let changeDescriptions = changes.sorted(by: { $0.key < $1.key }).map { key, values in
                "  \(key):\n    old: \(values.old)\n    new: \(values.new)"
            }.joined(separator: "\n")

            let message = "State changed:\n\(changeDescriptions)"

            var metadata: [String: AnyCodable] = ["type": AnyCodable("state_change")]
            for (key, values) in changes {
                metadata["old_\(key)"] = AnyCodable(values.old)
                metadata["new_\(key)"] = AnyCodable(values.new)
            }

            TraceKit.log(
                level: .info,
                message,
                category: viewModel,
                metadata: metadata,
                file: file,
                function: function,
                line: line
            )
        }
    }

    public func logPerformance(
        operation: String,
        duration: TimeInterval,
        viewModel: String,
        level: LogLevel,
        file: String,
        function: String,
        line: Int
    ) {
        // 레벨 필터링
        guard level.rawValue >= options.minimumLevel.rawValue else { return }

        // 스마트 임계값 사용
        let threshold: TimeInterval
        let shouldWarn: Bool

        if options.useSmartPerformanceThreshold {
            let operationType = PerformanceThreshold.infer(from: operation)
            threshold = operationType.recommendedThreshold
            shouldWarn = duration >= threshold
        } else {
            threshold = options.performanceThreshold
            shouldWarn = false
        }

        // 임계값 체크
        if !options.showZeroPerformance, duration < threshold {
            return
        }

        // 임계값 초과 시 WARNING 레벨로 승격
        let finalLevel = shouldWarn ? LogLevel.warning.traceLevel : level.traceLevel

        switch options.format {
        case .compact:
            // 간결: 성능 정보만, metadata 없음
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
            // 기존 방식
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
        level: LogLevel,
        file: String,
        function: String,
        line: Int
    ) {
        let message = "Error: \(error.localizedDescription) [\(error.domain):\(error.code)]"
        TraceKit.log(
            level: level.traceLevel,
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
}
