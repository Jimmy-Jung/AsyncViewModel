//
//  AppLoggerSetup.swift
//  AsyncViewModelExample
//
//  Created by jimmy on 2025/12/18.
//

import AsyncViewModel
import SwiftUI
import TraceKit

/// 앱 시작 시점에 AsyncViewModel 로거 설정 예시

// MARK: - SwiftUI App에서 설정

// 주의: 실제 앱에서는 @main을 사용하세요. 이 파일은 예시용이므로 주석 처리되어 있습니다.
/*
 @main
 struct AsyncViewModelExampleApp: App {

     init() {
         // 앱 시작 시 로거 설정
         setupGlobalLogger()
     }

     var body: some Scene {
         WindowGroup {
             MainMenuView()
         }
     }

     /// 전역 로거 설정
     private func setupGlobalLogger() {
         Task { @MainActor in
             #if DEBUG
             // 개발 환경: 콘솔 로거 사용
             let consoleLogger = ExampleConsoleLogger()
             LoggerConfiguration.setLogger(consoleLogger)

             print("✅ AsyncViewModel: Global Console Logger configured")
             #else
             // 프로덕션 환경: 로깅 비활성화
             LoggerConfiguration.disableLogging()
             #endif
         }
     }
 }
 */

// MARK: - UIKit AppDelegate에서 설정 (예시)

class ExampleAppDelegate: UIResponder, UIApplicationDelegate {
    func application(
        _: UIApplication,
        didFinishLaunchingWithOptions _: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        // 앱 시작 시 로거 설정
        setupGlobalLogger()

        return true
    }

    /// 전역 로거 설정
    private func setupGlobalLogger() {
        Task { @MainActor in
            #if DEBUG
                // 개발 환경: OS Log 사용
                let osLogger = OSLogViewModelLogger(subsystem: "com.myapp")
                AsyncViewModelConfiguration.shared.changeLogger(osLogger)
            #else
                // 프로덕션 환경: 로깅 비활성화
                AsyncViewModelConfiguration.shared.changeLogger(NoOpLogger())
            #endif
        }
    }
}

// MARK: - TraceKit 통합 예시 (권장)

/// TraceKit을 사용하는 앱에서 AsyncViewModel 로거 설정 예시
///
/// ## 기본 설정 (간결한 로그, 스마트 임계값)
/// ```swift
/// Task { @TraceKitActor in
///     await TraceKitBuilder.debug().buildAsShared()
/// }
///
/// Task { @MainActor in
///     var logger = TraceKitViewModelLogger()
///     logger.options.actionFormat = .compact
///     logger.options.effectFormat = .compact
///     logger.options.performanceThreshold = nil // 스마트 임계값 사용 (기본값)
///     AsyncViewModelConfiguration.shared.changeLogger(logger)
/// }
/// ```
///
/// ## 커스텀 임계값 설정
/// ```swift
/// Task { @MainActor in
///     var logger = TraceKitViewModelLogger()
///     logger.options.actionFormat = .standard
///     // Action processing: 10ms 초과 시 경고
///     logger.options.performanceThreshold = PerformanceThreshold(
///         type: .actionProcessing,
///         customThreshold: 0.010
///     )
///     AsyncViewModelConfiguration.shared.changeLogger(logger)
/// }
/// ```
///
/// ## 개발 환경 설정 (균형잡힌 로그)
/// ```swift
/// Task { @MainActor in
///     var logger = TraceKitViewModelLogger()
///     logger.options.actionFormat = .standard
///     logger.options.stateFormat = .standard
///     logger.options.effectFormat = .standard
///     logger.options.performanceThreshold = nil // 스마트 임계값
///     AsyncViewModelConfiguration.shared.changeLogger(logger)
/// }
/// ```
///
/// ## 디버깅 환경 설정 (상세한 로그)
/// ```swift
/// Task { @MainActor in
///     var logger = TraceKitViewModelLogger()
///     logger.options.actionFormat = .detailed
///     logger.options.stateFormat = .detailed
///     logger.options.effectFormat = .detailed
///     logger.options.performanceThreshold = PerformanceThreshold(
///         type: .custom,
///         customThreshold: 0.0 // 모든 성능 로그
///     )
///     logger.options.showZeroPerformance = true
///     AsyncViewModelConfiguration.shared.changeLogger(logger)
/// }
/// ```

// 주의: AsyncViewModelExampleApp은 위에서 주석 처리되어 있습니다
/*
 extension AsyncViewModelExampleApp {

     /// TraceKit을 사용한 고급 설정
     ///
     /// - Note: TraceKit은 이미 AsyncViewModel의 의존성으로 포함되어 있습니다
     private func setupTraceKitIntegration() {
         // TraceKit 초기화
         Task { @TraceKitActor in
             await TraceKitBuilder
                 .debug()
                 .buildAsShared()

             await TraceKit.async.info("✅ TraceKit initialized")
         }

         // AsyncViewModel에 연결
         Task { @MainActor in
             let logger = TraceKitViewModelLogger()
             LoggerConfiguration.setLogger(logger)

             TraceKit.info("✅ AsyncViewModel TraceKit logger configured")
         }
     }
 }
 */

// MARK: - 환경별 설정 예시

extension AsyncViewModelConfiguration {
    /// 개발 환경 설정
    @MainActor
    static func setupForDevelopment() {
        let logger = ExampleConsoleLogger()
        AsyncViewModelConfiguration.shared.changeLogger(logger)
        print("🔧 Development Logger: Console")
    }

    /// 스테이징 환경 설정
    @MainActor
    static func setupForStaging() {
        let logger = OSLogViewModelLogger(subsystem: "com.myapp.staging")
        AsyncViewModelConfiguration.shared.changeLogger(logger)
        print("🔧 Staging Logger: OSLog")
    }

    /// 프로덕션 환경 설정
    @MainActor
    static func setupForProduction() {
        // 프로덕션에서는 로깅 비활성화로 성능 최적화
        AsyncViewModelConfiguration.shared.changeLogger(NoOpLogger())
        print("🔧 Production Logger: Disabled")
    }
}

// MARK: - 커스텀 콘솔 로거 구현 (예시)

@MainActor
struct ExampleConsoleLogger: ViewModelLogger {
    var options: LoggingOptions = .init()

    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss.SSS"
        return formatter
    }()

    func logAction(
        _ action: String,
        viewModel: String,
        file _: String,
        function _: String,
        line _: Int
    ) {
        let timestamp = dateFormatter.string(from: Date())
        print("[\(timestamp)] [ACTION] [\(viewModel)] Action: \(action)")
    }

    func logStateChange(
        _ stateChange: StateChangeInfo,
        viewModel: String,
        file _: String,
        function _: String,
        line _: Int
    ) {
        let timestamp = dateFormatter.string(from: Date())
        print("[\(timestamp)] [INFO] [\(viewModel)] State changed:")
        print("  From: \(stateChange.oldState.compactDescription)")
        print("  To: \(stateChange.newState.compactDescription)")
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
        print("[\(timestamp)] [DEBUG] [\(viewModel)] Effects[\(effects.count)]: \(effects.joined(separator: ", "))")
    }

    func logPerformance(
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

        let timestamp = dateFormatter.string(from: Date())
        let durationStr = String(format: "%.3f", duration)
        print("[\(timestamp)] [PERF] [\(viewModel)] Performance - \(operation): \(durationStr)s")
    }

    func logError(
        _ error: SendableError,
        viewModel: String,
        file _: String,
        function _: String,
        line _: Int
    ) {
        let timestamp = dateFormatter.string(from: Date())
        print("[\(timestamp)] [ERROR] [\(viewModel)] Error: \(error.localizedDescription)")
    }
}

// MARK: - 사용 예시 요약

/*

  ## 앱 시작 시 전역 로거 설정 방법

  ### 1. SwiftUI App

  ```swift
  @main
  struct MyApp: App {
      init() {
          Task { @MainActor in
              // 개발 환경
              LoggerConfiguration.setupForDevelopment()

              // 또는 직접 설정
              let logger = ConsoleLogger()
              LoggerConfiguration.setLogger(logger)
          }
      }
  }
  ```

  ### 2. UIKit AppDelegate

  ```swift
  func application(_ application: UIApplication, ...) -> Bool {
      Task { @MainActor in
          LoggerConfiguration.setupForProduction()
      }
      return true
  }
  ```

  ### 3. 환경별 자동 설정

  ```swift
  init() {
      Task { @MainActor in
          #if DEBUG
          LoggerConfiguration.setupForDevelopment()
          #elseif STAGING
          LoggerConfiguration.setupForStaging()
          #else
          LoggerConfiguration.setupForProduction()
          #endif
      }
  }
  ```

  ### 4. TraceKit 통합 (권장)

 ```swift
 init() {
     // TraceKit 초기화
     Task { @TraceKitActor in
         await TraceKitBuilder.debug().buildAsShared()
     }

     // AsyncViewModel에 연결
     Task { @MainActor in
         let logger = TraceKitViewModelLogger()
         LoggerConfiguration.setLogger(logger)
     }
 }
 ```

  ## 로거 사용 방식

  AsyncViewModel은 전역 기본 로거를 사용합니다:
  - `LoggerConfiguration.logger`
  - 기본값: `OSLogViewModelLogger` (os.log 사용)
  - 앱 시작 시 한 번만 설정하면 모든 ViewModel에 적용

  ## 장점

  - ✅ 단순하고 명확한 구조
  - ✅ 앱 전체에 일관된 로깅 적용
  - ✅ 환경별 로거 쉽게 전환
  - ✅ 개별 ViewModel에서 로거 설정 불필요
  - ✅ 기본 OSLogViewModelLogger 제공으로 즉시 사용 가능

  */
