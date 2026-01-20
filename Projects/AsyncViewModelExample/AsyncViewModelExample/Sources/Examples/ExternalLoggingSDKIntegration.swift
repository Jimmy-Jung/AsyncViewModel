//
//  ExternalLoggingSDKIntegration.swift
//  AsyncViewModelExample
//
//  Created by jimmy on 2025/12/18.
//

import AsyncViewModel
import Foundation

/// 다양한 외부 로깅 SDK를 AsyncViewModel과 통합하는 예시
///
/// ViewModelLogger 프로토콜을 구현하면 어떤 로깅 SDK든 사용할 수 있습니다:
/// - TraceKit (권장 - 이미 포함됨)
/// - Firebase Crashlytics
/// - Sentry
/// - Datadog
/// - CocoaLumberjack
/// - SwiftyBeaver
/// - OSLog (커스텀 래퍼)
/// - 커스텀 로깅 시스템

// MARK: - 0. TraceKit 통합 (권장)

/// TraceKit을 사용하는 로거 (이미 AsyncViewModel에 포함됨)
///
/// TraceKit은 AsyncViewModel의 기본 의존성이므로 별도 설치 불필요
/// TraceKitViewModelLogger가 Core에 포함되어 있어 바로 사용 가능
///
/// 사용 예시:
/// ```swift
/// // 1. TraceKit 초기화
/// Task { @TraceKitActor in
///     await TraceKitBuilder
///         .debug()
///         .buildAsShared()
/// }
///
/// // 2. AsyncViewModel에 연결
/// Task { @MainActor in
///     let logger = TraceKitViewModelLogger()
///     LoggerConfiguration.setLogger(logger)
/// }
/// ```
///
/// TraceKit 장점:
/// - 고급 버퍼링 및 샘플링
/// - 민감정보 자동 마스킹
/// - 크래시 로그 보존
/// - 성능 측정 지원
/// - 다양한 Destination (Console, OSLog, File, 외부 서비스)
/// - Actor 기반 스레드 안전성

// MARK: - 1. Firebase Crashlytics 통합

/// Firebase Crashlytics를 사용하는 로거
///
/// 의존성 추가:
/// ```swift
/// .package(url: "https://github.com/firebase/firebase-ios-sdk", from: "10.0.0")
/// ```
@MainActor
struct FirebaseViewModelLogger: ViewModelLogger {
    var options: LoggingOptions = .init()

    func logAction(
        _ action: String,
        viewModel: String,
        file _: String,
        function _: String,
        line _: Int
    ) {
        // Firebase Crashlytics 사용 예시
        /*
         import FirebaseCrashlytics

         let message = "[\(viewModel)] Action: \(action)"
         Crashlytics.crashlytics().log(message)

         // 커스텀 키로도 기록
         Crashlytics.crashlytics().setCustomValue(action, forKey: "last_action")
         Crashlytics.crashlytics().setCustomValue(viewModel, forKey: "view_model")
         */

        print("[Firebase] [ACTION] [\(viewModel)] Action: \(action)")
    }

    func logStateChange(
        _ stateChange: StateChangeInfo,
        viewModel _: String,
        file _: String,
        function _: String,
        line _: Int
    ) {
        _ = stateChange // Firebase에서 필요 시 사용
        /*
         import FirebaseCrashlytics

         Crashlytics.crashlytics().log("[\(viewModel)] State changed")
         Crashlytics.crashlytics().setCustomValue(stateChange.newState.compactDescription, forKey: "current_state")
         */
    }

    func logEffect(
        _: String,
        viewModel _: String,
        file _: String,
        function _: String,
        line _: Int
    ) {
        // Effect는 상세 정보이므로 Firebase에는 기록하지 않을 수 있음
    }

    func logEffects(
        _: [String],
        viewModel _: String,
        file _: String,
        function _: String,
        line _: Int
    ) {
        // 그룹화된 Effect도 Firebase에는 기록하지 않을 수 있음
    }

    func logPerformance(
        operation _: String,
        duration _: TimeInterval,
        viewModel _: String,
        file _: String,
        function _: String,
        line _: Int
    ) {
        /*
         import FirebasePerformance

         // Firebase Performance Monitoring 사용
         let trace = Performance.startTrace(name: "\(viewModel)_\(operation)")
         // ... 작업 수행
         trace.stop()
         */
    }

    func logError(
        _: SendableError,
        viewModel _: String,
        file _: String,
        function _: String,
        line _: Int
    ) {
        /*
         import FirebaseCrashlytics

         let nsError = NSError(
             domain: error.domain,
             code: error.code,
             userInfo: [NSLocalizedDescriptionKey: error.localizedDescription]
         )
         Crashlytics.crashlytics().record(error: nsError)
         */
    }
}

// MARK: - 2. Sentry 통합

/// Sentry를 사용하는 로거
///
/// 의존성 추가:
/// ```swift
/// .package(url: "https://github.com/getsentry/sentry-cocoa", from: "8.0.0")
/// ```
@MainActor
struct SentryViewModelLogger: ViewModelLogger {
    var options: LoggingOptions = .init()

    func logAction(
        _ action: String,
        viewModel: String,
        file _: String,
        function _: String,
        line _: Int
    ) {
        /*
         import Sentry

         let breadcrumb = Breadcrumb(level: .info, category: viewModel)
         breadcrumb.message = "Action: \(action)"
         breadcrumb.data = [
             "action": action,
             "view_model": viewModel,
             "file": file,
             "line": line
         ]
         SentrySDK.addBreadcrumb(breadcrumb)
         */

        print("[Sentry] [ACTION] [\(viewModel)] Action: \(action)")
    }

    func logStateChange(
        _ stateChange: StateChangeInfo,
        viewModel _: String,
        file _: String,
        function _: String,
        line _: Int
    ) {
        _ = stateChange // Sentry에서 필요 시 사용
        /*
         import Sentry

         let breadcrumb = Breadcrumb(level: .info, category: viewModel)
         breadcrumb.message = "State changed"
         breadcrumb.data = [
             "old_state": stateChange.oldState.compactDescription,
             "new_state": stateChange.newState.compactDescription
         ]
         SentrySDK.addBreadcrumb(breadcrumb)
         */
    }

    func logEffect(
        _: String,
        viewModel _: String,
        file _: String,
        function _: String,
        line _: Int
    ) {
        // Breadcrumb으로 기록
    }

    func logEffects(
        _: [String],
        viewModel _: String,
        file _: String,
        function _: String,
        line _: Int
    ) {
        // Breadcrumb으로 기록
    }

    func logPerformance(
        operation _: String,
        duration _: TimeInterval,
        viewModel _: String,
        file _: String,
        function _: String,
        line _: Int
    ) {
        /*
         import Sentry

         let transaction = SentrySDK.startTransaction(
             name: "\(viewModel).\(operation)",
             operation: "view_model.operation"
         )
         // ... 작업 수행
         transaction.finish()
         */
    }

    func logError(
        _: SendableError,
        viewModel _: String,
        file _: String,
        function _: String,
        line _: Int
    ) {
        /*
         import Sentry

         let nsError = NSError(
             domain: error.domain,
             code: error.code,
             userInfo: [NSLocalizedDescriptionKey: error.localizedDescription]
         )

         SentrySDK.capture(error: nsError) { scope in
             scope.setContext(value: [
                 "view_model": viewModel,
                 "file": file,
                 "line": line
             ], key: "async_view_model")
         }
         */
    }

    /*
     private func mapToSentryLevel(_ level: LogLevel) -> SentryLevel {
         switch level {
         case .debug: return .debug
         case .info: return .info
         case .warning: return .warning
         case .error: return .error
         }
     }
     */
}

// MARK: - 3. Datadog 통합

/// Datadog을 사용하는 로거
///
/// 의존성 추가:
/// ```swift
/// .package(url: "https://github.com/DataDog/dd-sdk-ios", from: "2.0.0")
/// ```
@MainActor
struct DatadogViewModelLogger: ViewModelLogger {
    var options: LoggingOptions = .init()

    func logAction(
        _ action: String,
        viewModel: String,
        file _: String,
        function _: String,
        line _: Int
    ) {
        /*
         import DatadogCore
         import DatadogLogs

         logger.log(
             level: .info,
             message: "Action: \(action)",
             attributes: [
                 "view_model": viewModel,
                 "action": action,
                 "file": file,
                 "line": line
             ]
         )
         */

        print("[Datadog] [ACTION] [\(viewModel)] Action: \(action)")
    }

    func logStateChange(
        _ stateChange: StateChangeInfo,
        viewModel _: String,
        file _: String,
        function _: String,
        line _: Int
    ) {
        _ = stateChange // Datadog에서 필요 시 사용
        /*
         logger.info(
             "State changed",
             attributes: [
                 "view_model": viewModel,
                 "old_state": stateChange.oldState.compactDescription,
                 "new_state": stateChange.newState.compactDescription
             ]
         )
         */
    }

    func logEffect(
        _: String,
        viewModel _: String,
        file _: String,
        function _: String,
        line _: Int
    ) {}

    func logEffects(
        _: [String],
        viewModel _: String,
        file _: String,
        function _: String,
        line _: Int
    ) {}

    func logPerformance(
        operation _: String,
        duration _: TimeInterval,
        viewModel _: String,
        file _: String,
        function _: String,
        line _: Int
    ) {
        /*
         import DatadogTrace

         let span = Tracer.shared().startSpan(
             operationName: "\(viewModel).\(operation)"
         )
         span.setTag(key: "duration", value: duration)
         span.finish()
         */
    }

    func logError(
        _: SendableError,
        viewModel _: String,
        file _: String,
        function _: String,
        line _: Int
    ) {
        /*
         logger.error(
             error.localizedDescription,
             error: error as Error,
             attributes: [
                 "view_model": viewModel,
                 "error_code": error.code,
                 "error_domain": error.domain
             ]
         )
         */
    }
}

// MARK: - 4. CocoaLumberjack 통합

/// CocoaLumberjack을 사용하는 로거
@MainActor
struct CocoaLumberjackViewModelLogger: ViewModelLogger {
    var options: LoggingOptions = .init()

    func logAction(
        _: String,
        viewModel _: String,
        file _: String,
        function _: String,
        line _: Int
    ) {
        /*
         import CocoaLumberjack

         let message = DDLogMessage(
             message: "[\(viewModel)] Action: \(action)",
             level: .info,
             flag: .info,
             context: 0,
             file: file,
             function: function,
             line: UInt(line),
             tag: nil,
             options: [],
             timestamp: Date()
         )
         DDLog.log(asynchronous: true, message: message)
         */
    }

    func logStateChange(
        _ stateChange: StateChangeInfo,
        viewModel _: String,
        file _: String,
        function _: String,
        line _: Int
    ) {
        _ = stateChange
    }

    func logEffect(
        _: String,
        viewModel _: String,
        file _: String,
        function _: String,
        line _: Int
    ) {}

    func logEffects(
        _: [String],
        viewModel _: String,
        file _: String,
        function _: String,
        line _: Int
    ) {}

    func logPerformance(
        operation _: String,
        duration _: TimeInterval,
        viewModel _: String,
        file _: String,
        function _: String,
        line _: Int
    ) {}

    func logError(
        _: SendableError,
        viewModel _: String,
        file _: String,
        function _: String,
        line _: Int
    ) {}
}

// MARK: - 5. 여러 로거 조합 (Composite Logger)

/// 여러 로깅 SDK를 동시에 사용하는 복합 로거
///
/// 사용 예시:
/// ```swift
/// let compositeLogger = CompositeViewModelLogger(loggers: [
///     FirebaseViewModelLogger(),
///     SentryViewModelLogger(),
///     ConsoleLogger()
/// ])
/// LoggerConfiguration.setLogger(compositeLogger)
/// ```
@MainActor
struct CompositeViewModelLogger: ViewModelLogger {
    var options: LoggingOptions = .init()
    private let loggers: [any ViewModelLogger]

    init(loggers: [any ViewModelLogger]) {
        self.loggers = loggers
    }

    func logAction(
        _ action: String,
        viewModel: String,
        file: String,
        function: String,
        line: Int
    ) {
        for logger in loggers {
            logger.logAction(action, viewModel: viewModel, file: file, function: function, line: line)
        }
    }

    func logStateChange(
        _ stateChange: StateChangeInfo,
        viewModel: String,
        file: String,
        function: String,
        line: Int
    ) {
        for logger in loggers {
            logger.logStateChange(stateChange, viewModel: viewModel, file: file, function: function, line: line)
        }
    }

    func logEffect(
        _ effect: String,
        viewModel: String,
        file: String,
        function: String,
        line: Int
    ) {
        for logger in loggers {
            logger.logEffect(effect, viewModel: viewModel, file: file, function: function, line: line)
        }
    }

    func logEffects(
        _ effects: [String],
        viewModel: String,
        file: String,
        function: String,
        line: Int
    ) {
        for logger in loggers {
            logger.logEffects(effects, viewModel: viewModel, file: file, function: function, line: line)
        }
    }

    func logPerformance(
        operation: String,
        duration: TimeInterval,
        viewModel: String,
        file: String,
        function: String,
        line: Int
    ) {
        for logger in loggers {
            logger.logPerformance(operation: operation, duration: duration, viewModel: viewModel, file: file, function: function, line: line)
        }
    }

    func logError(
        _ error: SendableError,
        viewModel: String,
        file: String,
        function: String,
        line: Int
    ) {
        for logger in loggers {
            logger.logError(error, viewModel: viewModel, file: file, function: function, line: line)
        }
    }
}

// MARK: - 6. 조건부 로거 (Conditional Logger)

/// 조건에 따라 로깅을 필터링하는 래퍼 로거
@MainActor
struct ConditionalViewModelLogger: ViewModelLogger {
    var options: LoggingOptions = .init()
    private let baseLogger: any ViewModelLogger
    private let shouldLog: (String) -> Bool

    init(
        baseLogger: any ViewModelLogger,
        shouldLog: @escaping (String) -> Bool
    ) {
        self.baseLogger = baseLogger
        self.shouldLog = shouldLog
    }

    func logAction(
        _ action: String,
        viewModel: String,
        file: String,
        function: String,
        line: Int
    ) {
        guard shouldLog(viewModel) else { return }
        baseLogger.logAction(action, viewModel: viewModel, file: file, function: function, line: line)
    }

    func logStateChange(
        _ stateChange: StateChangeInfo,
        viewModel: String,
        file: String,
        function: String,
        line: Int
    ) {
        guard shouldLog(viewModel) else { return }
        baseLogger.logStateChange(stateChange, viewModel: viewModel, file: file, function: function, line: line)
    }

    func logEffect(
        _ effect: String,
        viewModel: String,
        file: String,
        function: String,
        line: Int
    ) {
        guard shouldLog(viewModel) else { return }
        baseLogger.logEffect(effect, viewModel: viewModel, file: file, function: function, line: line)
    }

    func logEffects(
        _ effects: [String],
        viewModel: String,
        file: String,
        function: String,
        line: Int
    ) {
        guard shouldLog(viewModel) else { return }
        baseLogger.logEffects(effects, viewModel: viewModel, file: file, function: function, line: line)
    }

    func logPerformance(
        operation: String,
        duration: TimeInterval,
        viewModel: String,
        file: String,
        function: String,
        line: Int
    ) {
        guard shouldLog(viewModel) else { return }
        baseLogger.logPerformance(operation: operation, duration: duration, viewModel: viewModel, file: file, function: function, line: line)
    }

    func logError(
        _ error: SendableError,
        viewModel: String,
        file: String,
        function: String,
        line: Int
    ) {
        guard shouldLog(viewModel) else { return }
        baseLogger.logError(error, viewModel: viewModel, file: file, function: function, line: line)
    }
}

// MARK: - 사용 예시

@MainActor
struct ExternalLoggingSDKSetupExamples {
    /// Firebase만 사용
    static func setupFirebase() {
        let logger = FirebaseViewModelLogger()
        AsyncViewModelConfiguration.shared.changeLogger(logger)
    }

    /// Sentry만 사용
    static func setupSentry() {
        let logger = SentryViewModelLogger()
        AsyncViewModelConfiguration.shared.changeLogger(logger)
    }

    /// Firebase + Sentry 동시 사용
    static func setupFirebaseAndSentry() {
        let compositeLogger = CompositeViewModelLogger(loggers: [
            FirebaseViewModelLogger(),
            SentryViewModelLogger(),
        ])
        AsyncViewModelConfiguration.shared.changeLogger(compositeLogger)
    }

    /// 개발 환경: 콘솔 + Firebase
    /// 프로덕션 환경: Sentry + Datadog
    static func setupEnvironmentSpecific() {
        #if DEBUG
            let logger = CompositeViewModelLogger(loggers: [
                SimpleConsoleLogger(),
                FirebaseViewModelLogger(),
            ])
        #else
            let logger = CompositeViewModelLogger(loggers: [
                SentryViewModelLogger(),
                DatadogViewModelLogger(),
            ])
        #endif

        AsyncViewModelConfiguration.shared.changeLogger(logger)
    }

    /// 특정 ViewModel만 로깅
    static func setupConditionalLogging() {
        let baseLogger = FirebaseViewModelLogger()

        let conditionalLogger = ConditionalViewModelLogger(
            baseLogger: baseLogger,
            shouldLog: { viewModel in
                // 특정 ViewModel만 로깅
                viewModel.contains("Calculator")
            }
        )

        AsyncViewModelConfiguration.shared.changeLogger(conditionalLogger)
    }
}

// MARK: - 콘솔 로거 (개발용 예시)

@MainActor
struct SimpleConsoleLogger: ViewModelLogger {
    var options: LoggingOptions = .init()

    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss.SSS"
        return formatter
    }()

    func logAction(
        _ action: String,
        viewModel: String,
        file: String,
        function _: String,
        line: Int
    ) {
        let timestamp = dateFormatter.string(from: Date())
        let fileName = (file as NSString).lastPathComponent
        print("[\(timestamp)] [ACTION] [\(viewModel)] Action: \(action) (\(fileName):\(line))")
    }

    func logStateChange(
        _ stateChange: StateChangeInfo,
        viewModel: String,
        file _: String,
        function _: String,
        line _: Int
    ) {
        _ = stateChange
        let timestamp = dateFormatter.string(from: Date())
        print("[\(timestamp)] [INFO] [\(viewModel)] State changed")
    }

    func logEffect(
        _ effect: String,
        viewModel: String,
        file _: String,
        function _: String,
        line _: Int
    ) {
        let timestamp = dateFormatter.string(from: Date())
        print("[\(timestamp)] [DEBUG] [\(viewModel)] Effect: \(effect)")
    }

    func logEffects(
        _ effects: [String],
        viewModel: String,
        file _: String,
        function _: String,
        line _: Int
    ) {
        let timestamp = dateFormatter.string(from: Date())
        print("[\(timestamp)] [DEBUG] [\(viewModel)] Effects[\(effects.count)]")
    }

    func logPerformance(
        operation: String,
        duration: TimeInterval,
        viewModel: String,
        file _: String,
        function _: String,
        line _: Int
    ) {
        let timestamp = dateFormatter.string(from: Date())
        let durationStr = String(format: "%.3f", duration)
        print("[\(timestamp)] [PERF] [\(viewModel)] ⚡️ \(operation): \(durationStr)s")
    }

    func logError(
        _ error: SendableError,
        viewModel: String,
        file _: String,
        function _: String,
        line _: Int
    ) {
        let timestamp = dateFormatter.string(from: Date())
        print("[\(timestamp)] [ERROR] [\(viewModel)] ❌ \(error.localizedDescription) [\(error.domain):\(error.code)]")
    }
}
