//
//  AsyncViewModelConfiguration.swift
//  AsyncViewModel
//
//  Created by jimmy on 2025/01/20.
//

import Foundation

// MARK: - AsyncViewModelConfiguration

/// AsyncViewModel의 Logger와 Interceptor를 통합 관리하는 Configuration
///
/// 앱 시작 시 Logger와 Interceptor를 설정하여 모든 ViewModel에서 사용할 수 있습니다.
///
/// ## 사용 예시
///
/// ```swift
/// // AppDelegate에서 설정
/// let config = AsyncViewModelConfiguration.shared
///
/// // Logger 변경 (선택사항, 기본은 OSLog)
/// config.changeLogger(TraceKitLogger())
///
/// // Interceptor 등록 (여러 개 가능)
/// config.addInterceptors([
///     AnalyticsInterceptor(),
///     DebugInterceptor()
/// ])
/// ```
@MainActor
public final class AsyncViewModelConfiguration: @unchecked Sendable {
    // MARK: - Singleton

    public static let shared = AsyncViewModelConfiguration()

    private init() {}

    // MARK: - Logger (단일)

    /// 현재 Logger (기본값: OSLogViewModelLogger)
    public private(set) var logger: any ViewModelLogger = OSLogViewModelLogger()

    /// Logger 변경
    ///
    /// - Parameter logger: 새로운 Logger
    public func changeLogger(_ logger: any ViewModelLogger) {
        self.logger = logger
    }

    /// 기본 Logger로 리셋
    public func resetLogger() {
        logger = OSLogViewModelLogger()
    }

    // MARK: - Global Logging Options

    /// 전역 로깅 옵션
    ///
    /// 개별 ViewModel에서 별도 설정하지 않으면 이 옵션이 사용됩니다.
    public private(set) var loggingOptions: LoggingOptions = .init()

    /// 전역 Action 로그 포맷 설정
    ///
    /// - Parameter actionFormat: Action 로그 포맷 (.compact, .standard, .detailed)
    public func configure(actionFormat: LogFormat) {
        loggingOptions.actionFormat = actionFormat
    }

    /// 전역 State 로그 포맷 설정
    ///
    /// - Parameter stateFormat: State 로그 포맷 (.compact, .standard, .detailed)
    public func configure(stateFormat: LogFormat) {
        loggingOptions.stateFormat = stateFormat
    }

    /// 전역 Effect 로그 포맷 설정
    ///
    /// - Parameter effectFormat: Effect 로그 포맷 (.compact, .standard, .detailed)
    /// - Note: compact/standard는 그룹화하여 표시, detailed는 개별적으로 표시
    public func configure(effectFormat: LogFormat) {
        loggingOptions.effectFormat = effectFormat
    }

    /// 전역 성능 임계값 설정
    ///
    /// - Parameter threshold: 성능 임계값
    public func configure(performanceThreshold: PerformanceThreshold?) {
        loggingOptions.performanceThreshold = performanceThreshold
    }

    /// 전역 로깅 옵션 전체 설정
    ///
    /// - Parameter options: 로깅 옵션
    public func configure(options: LoggingOptions) {
        loggingOptions = options
    }

    /// 전역 로깅 옵션을 기본값으로 리셋
    public func resetLoggingOptions() {
        loggingOptions = LoggingOptions()
    }

    // MARK: - Interceptors (복수)

    /// 등록된 Interceptor 목록
    public private(set) var interceptors: [any ViewModelInterceptor] = []

    /// Interceptor 등록
    ///
    /// - Parameter interceptor: 등록할 Interceptor
    public func addInterceptor(_ interceptor: any ViewModelInterceptor) {
        interceptors.append(interceptor)
    }

    /// 여러 Interceptor 등록
    ///
    /// - Parameter interceptors: 등록할 Interceptor 배열
    public func addInterceptors(_ interceptors: [any ViewModelInterceptor]) {
        self.interceptors.append(contentsOf: interceptors)
    }

    /// 특정 Interceptor 제거
    ///
    /// - Parameter id: 제거할 Interceptor의 식별자
    public func removeInterceptor(id: String) {
        interceptors.removeAll { $0.id == id }
    }

    /// 모든 Interceptor 제거
    public func removeAllInterceptors() {
        interceptors.removeAll()
    }

    // MARK: - Dispatch

    /// 등록된 모든 Interceptor에 이벤트 전달
    ///
    /// - Parameters:
    ///   - event: 로그 이벤트
    ///   - viewModel: ViewModel 이름
    ///   - file: 파일 경로
    ///   - function: 함수 이름
    ///   - line: 라인 번호
    func dispatch(
        _ event: LogEvent,
        viewModel: String,
        file: String,
        function: String,
        line: Int
    ) {
        for interceptor in interceptors {
            interceptor.intercept(
                event,
                viewModel: viewModel,
                file: file,
                function: function,
                line: line
            )
        }
    }

    // MARK: - Logger Resolution

    /// 모드에 따른 Logger 반환
    ///
    /// - Parameter mode: Logger 모드
    /// - Returns: 해당 모드에 맞는 Logger
    public func logger(for mode: LoggerMode) -> any ViewModelLogger {
        switch mode {
        case .shared:
            return logger
        case let .custom(customLogger):
            return customLogger
        }
    }
}
