//
//  OSLogViewModelLogger.swift
//  AsyncViewModel
//
//  Created by jimmy on 2025/12/19.
//

import Foundation
import os.log

// MARK: - OSLogViewModelLogger

/// OSLog 기반 ViewModel 로거
///
/// Apple의 통합 로깅 시스템(os.log)을 사용하여 로그를 출력합니다.
/// LogFormatter를 통해 포맷팅을 위임하므로 커스텀 포맷터를 주입할 수 있습니다.
///
/// ## 사용 예시
///
/// ```swift
/// // 기본 사용
/// let logger = OSLogViewModelLogger()
///
/// // 커스텀 subsystem
/// let logger = OSLogViewModelLogger(subsystem: "com.myapp")
///
/// // 커스텀 포맷터
/// let logger = OSLogViewModelLogger(formatter: JSONLogFormatter())
/// ```
public struct OSLogViewModelLogger: ViewModelLogger {
    public var options: LoggingOptions = .init()
    public let formatter: LogFormatter
    private let subsystem: String

    public init(
        subsystem: String = "com.jimmy.AsyncViewModel",
        formatter: LogFormatter = DefaultLogFormatter()
    ) {
        self.subsystem = subsystem
        self.formatter = formatter
    }

    // MARK: - ViewModelLogger Implementation

    public func logAction(
        _ action: ActionInfo,
        viewModel: String,
        file _: String,
        function _: String,
        line _: Int
    ) {
        let logger = createLogger(category: viewModel)
        let actionDescription = formatter.formatAction(action, format: options.actionFormat)
        let message = "Action: \(actionDescription)"
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
        let message = formatter.formatStateChange(stateChange, format: options.stateFormat)
        logger.info("\(message, privacy: .public)")
    }

    public func logEffect(
        _ effect: EffectInfo,
        viewModel: String,
        file _: String,
        function _: String,
        line _: Int
    ) {
        let logger = createLogger(category: viewModel)
        let effectDescription = formatter.formatEffect(effect, format: options.effectFormat)
        logger.debug("Effect: \(effectDescription, privacy: .public)")
    }

    public func logEffects(
        _ effects: [EffectInfo],
        viewModel: String,
        file _: String,
        function _: String,
        line _: Int
    ) {
        let logger = createLogger(category: viewModel)
        let messages = formatter.formatEffects(effects, format: options.effectFormat)

        for message in messages {
            logger.debug("\(message, privacy: .public)")
        }
    }

    public func logPerformance(
        _ performance: PerformanceInfo,
        viewModel: String,
        file _: String,
        function _: String,
        line _: Int
    ) {
        guard let message = formatter.formatPerformance(performance, options: options) else {
            return
        }

        let logger = createLogger(category: viewModel)

        // 임계값 초과 시 warning, 아니면 debug
        if performance.exceededThreshold {
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
        let message = formatter.formatError(error)
        logger.error("\(message, privacy: .public)")
    }

    // MARK: - Private Helpers

    private func createLogger(category: String) -> os.Logger {
        os.Logger(subsystem: subsystem, category: category)
    }
}
