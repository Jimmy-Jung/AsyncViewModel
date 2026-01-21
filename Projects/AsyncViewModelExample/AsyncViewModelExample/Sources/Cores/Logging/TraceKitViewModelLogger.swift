//
//  TraceKitViewModelLogger.swift
//  AsyncViewModelExample
//
//  Created by jimmy on 2025/01/21.
//

import AsyncViewModel
import Foundation
import TraceKit

// MARK: - TraceKitViewModelLogger

/// TraceKit 기반 ViewModel 로거
///
/// TraceKit 로깅 시스템을 사용하여 AsyncViewModel의 로그를 출력합니다.
/// LogFormatter를 통해 포맷팅을 위임하므로 커스텀 포맷터를 주입할 수 있습니다.
///
/// ## 사용 예시
///
/// ```swift
/// // AppDelegate에서 설정
/// let config = AsyncViewModelConfiguration.shared
/// config.changeLogger(TraceKitViewModelLogger())
/// ```
public struct TraceKitViewModelLogger: ViewModelLogger {
    public var options: LoggingOptions = .init()
    public let formatter: LogFormatter

    public init(formatter: LogFormatter = DefaultLogFormatter()) {
        self.formatter = formatter
    }

    // MARK: - ViewModelLogger Implementation

    public func logAction(
        _ action: ActionInfo,
        viewModel: String,
        file: String,
        function: String,
        line: Int
    ) {
        let actionDescription = formatter.formatAction(action, format: options.actionFormat)
        let message = "Action: \(actionDescription)"

        // 디버깅용: 직접 print도 출력
        print("🔵 [TraceKitLogger] \(message)")

        TraceKit.info(
            message,
            category: viewModel,
            file: file,
            function: function,
            line: line
        )
    }

    public func logStateChange(
        _ stateChange: StateChangeInfo,
        viewModel: String,
        file: String,
        function: String,
        line: Int
    ) {
        let message = formatter.formatStateChange(stateChange, format: options.stateFormat)

        // 디버깅용: 직접 print도 출력
        print("🟢 [TraceKitLogger] State Changed")

        TraceKit.info(
            message,
            category: viewModel,
            file: file,
            function: function,
            line: line
        )
    }

    public func logEffect(
        _ effect: EffectInfo,
        viewModel: String,
        file: String,
        function: String,
        line: Int
    ) {
        let effectDescription = formatter.formatEffect(effect, format: options.effectFormat)
        let message = "Effect: \(effectDescription)"

        TraceKit.debug(
            message,
            category: viewModel,
            file: file,
            function: function,
            line: line
        )
    }

    public func logEffects(
        _ effects: [EffectInfo],
        viewModel: String,
        file: String,
        function: String,
        line: Int
    ) {
        let messages = formatter.formatEffects(effects, format: options.effectFormat)

        for message in messages {
            TraceKit.debug(
                message,
                category: viewModel,
                file: file,
                function: function,
                line: line
            )
        }
    }

    public func logPerformance(
        _ performance: PerformanceInfo,
        viewModel: String,
        file: String,
        function: String,
        line: Int
    ) {
        guard let message = formatter.formatPerformance(performance, options: options) else {
            return
        }

        // 임계값 초과 시 warning, 아니면 debug
        if performance.exceededThreshold {
            TraceKit.warning(
                message,
                category: viewModel,
                file: file,
                function: function,
                line: line
            )
        } else {
            TraceKit.debug(
                message,
                category: viewModel,
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
        let message = formatter.formatError(error)

        TraceKit.error(
            message,
            category: viewModel,
            file: file,
            function: function,
            line: line
        )
    }
}
