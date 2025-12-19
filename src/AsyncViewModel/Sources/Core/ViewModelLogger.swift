//
//  ViewModelLogger.swift
//  AsyncViewModel
//
//  Created by jimmy on 2025/12/18.
//

import Foundation
import os.log

// MARK: - PerformanceThreshold

/// 작업 종류별 성능 임계값 기준
///
/// 각 작업 유형에 적합한 성능 기준을 제공합니다.
/// 임계값을 초과하면 WARNING 로그가 출력됩니다.
public struct PerformanceThreshold: Sendable, Codable {
    /// 작업 종류
    public enum OperationType: String, Sendable, Codable {
        case actionProcessing = "Action processing"
        case effectOperation = "Effect operation"
        case stateUpdate = "State update"
        case custom = "Custom"

        /// 권장 임계값 (초)
        public var recommendedThreshold: TimeInterval {
            switch self {
            case .actionProcessing:
                return 0.050 // 50ms - Action 처리는 빨라야 함
            case .effectOperation:
                return 0.100 // 100ms - Effect는 비동기 작업 포함
            case .stateUpdate:
                return 0.016 // 16ms - 60fps 유지 (1/60 = 16.67ms)
            case .custom:
                return 0.100 // 기본값
            }
        }
    }

    /// 작업 타입
    public let type: OperationType

    /// 사용자 정의 임계값 (nil이면 권장값 사용)
    public let customThreshold: TimeInterval?

    /// 최종 임계값
    public var threshold: TimeInterval {
        customThreshold ?? type.recommendedThreshold
    }

    public init(type: OperationType, customThreshold: TimeInterval? = nil) {
        self.type = type
        self.customThreshold = customThreshold
    }

    /// 문자열에서 작업 타입 추론
    public static func infer(from operation: String) -> OperationType {
        let lowercased = operation.lowercased()
        if lowercased.contains("action") && lowercased.contains("processing") {
            return .actionProcessing
        } else if lowercased.contains("effect") {
            return .effectOperation
        } else if lowercased.contains("state") {
            return .stateUpdate
        } else {
            return .custom
        }
    }
}

// MARK: - LogFormat

/// 로그 출력 포맷
public enum LogFormat: Sendable, Codable {
    /// 한 줄로 요약 (최소한의 정보)
    case compact
    /// 기본 포맷 (균형 잡힌 가독성)
    case standard
    /// 상세 포맷 (모든 정보 포함)
    case detailed
}

// MARK: - LoggingOptions

/// 로깅 동작을 제어하는 옵션
///
/// ## 사용 예시
/// ```swift
/// var logger = TraceKitViewModelLogger()
/// logger.options.format = .compact
/// logger.options.performanceThreshold = 0.010 // 10ms 이하 생략
/// logger.options.showStateDiffOnly = true
/// logger.options.groupEffects = true
/// ViewModelLoggerConfiguration.shared.setLogger(logger)
/// ```
public struct LoggingOptions: Sendable, Codable {
    /// 로그 포맷
    public var format: LogFormat

    /// 성능 로그 임계값 (초 단위)
    ///
    /// **Deprecated**: `useSmartPerformanceThreshold`를 true로 설정하면 무시됩니다.
    /// 이 값보다 짧은 시간은 로그에 출력되지 않습니다.
    /// - 기본값: 0.001 (1ms)
    /// - 권장값: 개발 환경 0.001, 프로덕션 0.050
    public var performanceThreshold: TimeInterval

    /// 스마트 성능 임계값 사용 여부
    ///
    /// - true: 작업 종류에 따라 자동으로 적절한 임계값 적용
    ///   - Action processing: 50ms
    ///   - Effect operation: 100ms
    ///   - State update: 16ms (60fps 기준)
    /// - false: `performanceThreshold` 값 사용
    public var useSmartPerformanceThreshold: Bool

    /// State 변경 시 diff만 표시
    ///
    /// - true: 변경된 필드만 표시
    /// - false: 전체 State 표시 (기존 방식)
    public var showStateDiffOnly: Bool

    /// Effect 그룹화
    ///
    /// - true: 여러 Effect를 한 줄로 요약
    /// - false: 각 Effect를 개별 로그로 출력
    public var groupEffects: Bool

    /// 0초 성능 메트릭 표시 여부
    ///
    /// - true: 0.000s도 표시
    /// - false: 0초는 생략
    public var showZeroPerformance: Bool

    /// 최소 로그 레벨
    ///
    /// 이 레벨 미만의 로그는 출력하지 않습니다.
    /// - .verbose: 모든 로그 출력
    /// - .debug: DEBUG 이상만 출력
    /// - .info: INFO 이상만 출력 (권장 - 내부 액션 제외)
    /// - .warning: WARNING 이상만 출력
    /// - .error: ERROR만 출력
    public var minimumLevel: LogLevel

    /// 기본 초기화
    public init(
        format: LogFormat = .standard,
        performanceThreshold: TimeInterval = 0.001,
        useSmartPerformanceThreshold: Bool = true,
        showStateDiffOnly: Bool = true,
        groupEffects: Bool = true,
        showZeroPerformance: Bool = false,
        minimumLevel: LogLevel = .verbose
    ) {
        self.format = format
        self.performanceThreshold = performanceThreshold
        self.useSmartPerformanceThreshold = useSmartPerformanceThreshold
        self.showStateDiffOnly = showStateDiffOnly
        self.groupEffects = groupEffects
        self.showZeroPerformance = showZeroPerformance
        self.minimumLevel = minimumLevel
    }
}

// MARK: - LoggerConfiguration

/// AsyncViewModel의 전역 로거 설정
///
/// 앱 시작 시점에 전역 로거를 설정하여 모든 ViewModel에서 사용할 수 있습니다.
///
/// ## 사용 방법
///
/// ### 1. TraceKit 사용 (권장)
/// ```swift
/// import AsyncViewModel
/// import TraceKit
///
/// // TraceKit 초기화
/// Task { @TraceKitActor in
///     await TraceKitBuilder.debug().buildAsShared()
/// }
///
/// // AsyncViewModel 로거 설정
/// Task { @MainActor in
///     LoggerConfiguration.logger = TraceKitViewModelLogger()
/// }
/// ```
///
/// ### 2. 커스텀 로거 구현
/// ```swift
/// @MainActor
/// struct MyCustomLogger: ViewModelLogger {
///     func logAction(...) {
///         // 원하는 로깅 SDK 호출
///         print("Action: \(action)")
///     }
///     // ... 다른 메서드 구현
/// }
///
/// Task { @MainActor in
///     LoggerConfiguration.logger = MyCustomLogger()
/// }
/// ```
///
/// ### 3. 로깅 비활성화
/// ```swift
/// LoggerConfiguration.disableLogging()
/// ```
@MainActor
public enum LoggerConfiguration {
    private static var _logger: any ViewModelLogger = OSLogViewModelLogger()

    /// 전역 로거 - 모든 ViewModel에서 사용 (읽기 전용)
    ///
    /// 기본값: OSLogViewModelLogger (os.log 사용)
    ///
    /// ## 설정 예시
    /// ```swift
    /// // TraceKit 사용
    /// LoggerConfiguration.setLogger(TraceKitViewModelLogger())
    ///
    /// // 커스텀 로거 사용
    /// LoggerConfiguration.setLogger(MyCustomLogger())
    ///
    /// // 로깅 비활성화
    /// LoggerConfiguration.disableLogging()
    /// ```
    public static var logger: any ViewModelLogger {
        _logger
    }

    /// 전역 로거 설정
    ///
    /// - Parameter logger: 설정할 로거 인스턴스
    ///
    /// ## 사용 예시
    /// ```swift
    /// LoggerConfiguration.setLogger(TraceKitViewModelLogger())
    /// ```
    public static func setLogger(_ logger: any ViewModelLogger) {
        _logger = logger
    }

    /// 로깅 완전히 비활성화
    public static func disableLogging() {
        _logger = NoOpLogger()
    }

    /// 기본 OSLogViewModelLogger로 재설정
    public static func resetToDefault() {
        _logger = OSLogViewModelLogger()
    }
}

// MARK: - ViewModelLogger Protocol

/// AsyncViewModel을 위한 로깅 인터페이스
///
/// 이 프로토콜을 구현하여 다양한 로깅 백엔드를 연결할 수 있습니다.
/// - os.log (기본)
/// - TraceKit (권장)
/// - 커스텀 로거
/// - NoOp (로깅 비활성화)
@MainActor
public protocol ViewModelLogger: Sendable {
    /// 로깅 옵션
    var options: LoggingOptions { get set }

    /// 액션 로깅
    func logAction(
        _ action: String,
        viewModel: String,
        level: LogLevel,
        file: String,
        function: String,
        line: Int
    )

    /// 상태 변경 로깅
    func logStateChange(
        from oldState: String,
        to newState: String,
        viewModel: String,
        file: String,
        function: String,
        line: Int
    )

    /// Effect 실행 로깅
    func logEffect(
        _ effect: String,
        viewModel: String,
        file: String,
        function: String,
        line: Int
    )

    /// Effect 배열 그룹 로깅
    ///
    /// options.groupEffects가 true일 때 사용됩니다.
    func logEffects(
        _ effects: [String],
        viewModel: String,
        file: String,
        function: String,
        line: Int
    )

    /// State diff 로깅
    ///
    /// options.showStateDiffOnly가 true일 때 사용됩니다.
    /// - Parameter changes: 변경된 필드들 (키: 필드명, 값: (이전값, 새값))
    func logStateDiff(
        changes: [String: (old: String, new: String)],
        viewModel: String,
        file: String,
        function: String,
        line: Int
    )

    /// 성능 메트릭 로깅
    func logPerformance(
        operation: String,
        duration: TimeInterval,
        viewModel: String,
        level: LogLevel,
        file: String,
        function: String,
        line: Int
    )

    /// 에러 로깅
    func logError(
        _ error: SendableError,
        viewModel: String,
        level: LogLevel,
        file: String,
        function: String,
        line: Int
    )
}

// MARK: - NoOpLogger

/// 로깅을 수행하지 않는 기본 구현
///
/// 로깅이 필요 없거나 성능 최적화가 필요한 경우 사용합니다.
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

// MARK: - OSLogViewModelLogger

/// os.log를 사용하는 기본 로거 구현
///
/// 기존 AsyncViewModel의 로깅 동작과 동일한 방식으로 동작합니다.
public struct OSLogViewModelLogger: ViewModelLogger {
    public var options: LoggingOptions = .init()
    private let subsystem: String

    /// OSLogViewModelLogger 초기화
    /// - Parameter subsystem: os.log subsystem (기본값: "com.jimmy.AsyncViewModel")
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
        case .verbose:
            logger.debug("\(message, privacy: .public)")
        case .debug:
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
        // 임계값 체크
        if !options.showZeroPerformance, duration < options.performanceThreshold {
            return
        }

        let logger = createLogger(category: viewModel)
        let message = "Performance - \(operation): \(String(format: "%.3f", duration))s"

        switch level {
        case .verbose:
            logger.debug("\(message, privacy: .public)")
        case .debug:
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
        case .verbose:
            logger.debug("\(message, privacy: .public)")
        case .debug:
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

// MARK: - ViewModelLogger Extensions

public extension ViewModelLogger {
    /// 기본 file, function, line 파라미터를 사용하는 편의 메서드
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
