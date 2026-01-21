//
//  ViewModelLoggingConfig.swift
//  AsyncViewModel
//
//  Created by jimmy on 2025/12/24.
//

import Foundation

// MARK: - LogCategory

/// 로깅 카테고리
public enum LogCategory: String, Sendable, Codable, CaseIterable {
    case action
    case stateChange
    case effect
    case performance
    case error
}

// MARK: - ViewModelLoggingConfig

/// ViewModel별 로깅 설정
///
/// 매크로가 자동으로 생성하는 프로퍼티로, 컴파일 타임 설정을 런타임에 활용합니다.
/// 불변 데이터 구조체이므로 actor 격리가 필요 없습니다.
///
/// ## 사용 예시
///
/// ```swift
/// // 매크로에서 자동 생성
/// @AsyncViewModel
/// final class MyViewModel: ObservableObject { ... }
///
/// // 커스텀 Logger 지정
/// @AsyncViewModel(logger: .custom(DebugLogger()))
/// final class DebugViewModel: ObservableObject { ... }
///
/// // 로깅 모드 + Logger + 포맷 조합
/// @AsyncViewModel(logging: .minimal, logger: .custom(Logger()), format: .detailed)
/// final class CustomViewModel: ObservableObject { ... }
/// ```
public struct ViewModelLoggingConfig: @unchecked Sendable {
    /// 로깅 모드 (무엇을 로깅할지)
    public let mode: LoggingMode

    /// Logger 모드 (어디에 로깅할지)
    public let loggerMode: LoggerMode

    /// ViewModel별 커스텀 로깅 옵션 (nil이면 전역 설정 사용)
    public let customOptions: LoggingOptions?

    /// 실제 사용할 로깅 옵션 (커스텀 설정이 있으면 사용, 없으면 전역 설정)
    @MainActor
    public var options: LoggingOptions {
        customOptions ?? AsyncViewModelConfiguration.shared.loggingOptions
    }

    /// 커스텀 옵션이 설정되어 있는지
    public var hasCustomOptions: Bool {
        customOptions != nil
    }

    /// 로깅이 활성화되어 있는지
    public var isEnabled: Bool {
        mode.isEnabled
    }

    /// 특정 카테고리가 활성화되어 있는지
    public func isCategoryEnabled(_ category: LogCategory) -> Bool {
        mode.isCategoryEnabled(category)
    }

    /// 기본 설정 (전역 옵션 사용)
    public static let `default` = ViewModelLoggingConfig(
        mode: .enabled,
        loggerMode: .shared,
        customOptions: nil
    )

    /// 비활성화 설정
    public static let disabled = ViewModelLoggingConfig(
        mode: .disabled,
        loggerMode: .shared,
        customOptions: nil
    )

    /// 최소 설정
    public static let minimal = ViewModelLoggingConfig(
        mode: .minimal,
        loggerMode: .shared,
        customOptions: nil
    )

    // MARK: - Initializers

    /// 기본 생성자 (전역 옵션 사용)
    public init(mode: LoggingMode) {
        self.mode = mode
        loggerMode = .shared
        customOptions = nil
    }

    /// Logger 포함 생성자
    public init(mode: LoggingMode, loggerMode: LoggerMode) {
        self.mode = mode
        self.loggerMode = loggerMode
        customOptions = nil
    }

    /// 전체 옵션 생성자
    public init(
        mode: LoggingMode,
        loggerMode: LoggerMode,
        customOptions: LoggingOptions?
    ) {
        self.mode = mode
        self.loggerMode = loggerMode
        self.customOptions = customOptions
    }

    // MARK: - Builder Methods

    /// 현재 customOptions 또는 기본값을 기반으로 새 옵션 생성
    private func currentOrNewOptions() -> LoggingOptions {
        customOptions ?? LoggingOptions()
    }

    /// 모든 카테고리에 동일한 포맷 설정 (이 ViewModel에서만 적용)
    ///
    /// - Parameter format: 로그 포맷 (.compact, .standard, .detailed)
    /// - Returns: 새로운 ViewModelLoggingConfig
    public func withFormat(_ format: LogFormat) -> ViewModelLoggingConfig {
        let newOptions = LoggingOptions(
            actionFormat: format,
            stateFormat: format,
            effectFormat: format
        )
        return ViewModelLoggingConfig(
            mode: mode,
            loggerMode: loggerMode,
            customOptions: newOptions
        )
    }

    /// Action 로그 포맷 설정 (이 ViewModel에서만 적용)
    ///
    /// - Parameter format: Action 로그 포맷 (.compact, .standard, .detailed)
    /// - Returns: 새로운 ViewModelLoggingConfig
    public func withActionFormat(_ format: LogFormat) -> ViewModelLoggingConfig {
        var newOptions = currentOrNewOptions()
        newOptions.actionFormat = format
        return ViewModelLoggingConfig(
            mode: mode,
            loggerMode: loggerMode,
            customOptions: newOptions
        )
    }

    /// State 로그 포맷 설정 (이 ViewModel에서만 적용)
    ///
    /// - Parameter format: State 로그 포맷 (.compact, .standard, .detailed)
    /// - Returns: 새로운 ViewModelLoggingConfig
    public func withStateFormat(_ format: LogFormat) -> ViewModelLoggingConfig {
        var newOptions = currentOrNewOptions()
        newOptions.stateFormat = format
        return ViewModelLoggingConfig(
            mode: mode,
            loggerMode: loggerMode,
            customOptions: newOptions
        )
    }

    /// Effect 로그 포맷 설정 (이 ViewModel에서만 적용)
    ///
    /// - Parameter format: Effect 로그 포맷 (.compact, .standard, .detailed)
    /// - Note: compact/standard는 그룹화하여 표시, detailed는 개별적으로 표시
    /// - Returns: 새로운 ViewModelLoggingConfig
    public func withEffectFormat(_ format: LogFormat) -> ViewModelLoggingConfig {
        var newOptions = currentOrNewOptions()
        newOptions.effectFormat = format
        return ViewModelLoggingConfig(
            mode: mode,
            loggerMode: loggerMode,
            customOptions: newOptions
        )
    }

    /// 성능 임계값 설정 (이 ViewModel에서만 적용)
    ///
    /// - Parameter threshold: 성능 임계값
    /// - Returns: 새로운 ViewModelLoggingConfig
    public func withPerformanceThreshold(_ threshold: PerformanceThreshold?) -> ViewModelLoggingConfig {
        var newOptions = currentOrNewOptions()
        newOptions.performanceThreshold = threshold
        return ViewModelLoggingConfig(
            mode: mode,
            loggerMode: loggerMode,
            customOptions: newOptions
        )
    }

    /// 0 성능 표시 여부 설정 (이 ViewModel에서만 적용)
    ///
    /// - Parameter enabled: true면 0 성능도 표시
    /// - Returns: 새로운 ViewModelLoggingConfig
    public func withZeroPerformance(_ enabled: Bool) -> ViewModelLoggingConfig {
        var newOptions = currentOrNewOptions()
        newOptions.showZeroPerformance = enabled
        return ViewModelLoggingConfig(
            mode: mode,
            loggerMode: loggerMode,
            customOptions: newOptions
        )
    }

    /// 전역 설정 사용으로 리셋 (커스텀 옵션 제거)
    ///
    /// - Returns: 전역 설정을 사용하는 ViewModelLoggingConfig
    public func usingGlobalOptions() -> ViewModelLoggingConfig {
        ViewModelLoggingConfig(
            mode: mode,
            loggerMode: loggerMode,
            customOptions: nil
        )
    }
}
