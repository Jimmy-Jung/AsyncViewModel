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

// MARK: - ViewModelLoggingMode

/// ViewModel별 로깅 모드
///
/// @AsyncViewModel 매크로의 logging 파라미터로 사용됩니다.
/// 컴파일 타임에 설정되어 런타임 성능 오버헤드가 없습니다.
///
/// ## 사용 예시
///
/// ```swift
/// // 기본 사용 (shared logger)
/// @AsyncViewModel(logging: .enabled)
/// final class MyViewModel: ObservableObject { ... }
///
/// // 커스텀 Logger 지정
/// @AsyncViewModel(logging: .enabled(.custom(DebugLogger())))
/// final class DebugViewModel: ObservableObject { ... }
///
/// // 로깅 비활성화
/// @AsyncViewModel(logging: .disabled)
/// final class SilentViewModel: ObservableObject { ... }
/// ```
public enum ViewModelLoggingMode: Sendable {
    // MARK: - Logger

    /// Logger 모드 (ViewModel별 설정용)
    public enum Logger: Sendable {
        /// 전역 shared Logger 사용 (기본값)
        case shared

        /// 해당 ViewModel에서만 사용할 커스텀 Logger
        case custom(any ViewModelLogger)
    }

    // MARK: - Cases

    /// 모든 로깅 활성화
    case enabled(Logger)

    /// 모든 로깅 비활성화
    case disabled

    /// 최소 로깅 (에러만)
    case minimal(Logger)

    /// 커스텀 카테고리 설정
    case custom(
        categories: Set<LogCategory>,
        logger: Logger = .shared
    )

    // MARK: - Convenience Static Properties (하위 호환성)

    /// 모든 로깅 활성화 (shared Logger 사용)
    public static var enabled: ViewModelLoggingMode { .enabled(.shared) }

    /// 최소 로깅 (에러만, shared Logger 사용)
    public static var minimal: ViewModelLoggingMode { .minimal(.shared) }

    // MARK: - Factory Methods

    /// 특정 카테고리만 활성화
    public static func only(_ categories: LogCategory...) -> ViewModelLoggingMode {
        .custom(categories: Set(categories), logger: .shared)
    }

    /// 특정 카테고리만 활성화 (Logger 지정)
    public static func only(_ categories: LogCategory..., logger: Logger) -> ViewModelLoggingMode {
        .custom(categories: Set(categories), logger: logger)
    }

    /// 특정 카테고리 제외
    public static func excluding(_ categories: LogCategory...) -> ViewModelLoggingMode {
        let allCategories = Set(LogCategory.allCases)
        let excluded = Set(categories)
        return .custom(categories: allCategories.subtracting(excluded), logger: .shared)
    }

    /// 특정 카테고리 제외 (Logger 지정)
    public static func excluding(_ categories: LogCategory..., logger: Logger) -> ViewModelLoggingMode {
        let allCategories = Set(LogCategory.allCases)
        let excluded = Set(categories)
        return .custom(categories: allCategories.subtracting(excluded), logger: logger)
    }

    /// State 변경 로깅만 비활성화 (가장 시끄러운 로그)
    public static var noStateChanges: ViewModelLoggingMode {
        .excluding(.stateChange)
    }

    /// 성능 로깅만 활성화
    public static var performanceOnly: ViewModelLoggingMode {
        .only(.performance, .error)
    }

    // MARK: - Logger Accessor

    /// 현재 모드의 Logger 반환
    public var logger: Logger {
        switch self {
        case let .enabled(logger):
            return logger
        case .disabled:
            return .shared
        case let .minimal(logger):
            return logger
        case let .custom(_, logger):
            return logger
        }
    }
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
/// @AsyncViewModel(logging: .enabled)
/// final class MyViewModel: ObservableObject { ... }
///
/// // 커스텀 Logger 지정
/// @AsyncViewModel(logging: .enabled(.custom(DebugLogger())))
/// final class DebugViewModel: ObservableObject { ... }
///
/// // 또는 직접 생성
/// let config = ViewModelLoggingConfig(mode: .enabled)
///     .withFormat(.detailed)
///     .withStateDiffOnly(true)
/// ```
public struct ViewModelLoggingConfig: @unchecked Sendable {
    /// 로깅 모드 (Logger 포함)
    public let mode: ViewModelLoggingMode

    /// ViewModel별 커스텀 로깅 옵션 (nil이면 전역 설정 사용)
    public let customOptions: LoggingOptions?

    /// Logger 모드 (mode에서 추출)
    public var loggerMode: ViewModelLoggingMode.Logger {
        mode.logger
    }

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
        switch mode {
        case .enabled, .minimal, .custom:
            return true
        case .disabled:
            return false
        }
    }

    /// 특정 카테고리가 활성화되어 있는지
    public func isCategoryEnabled(_ category: LogCategory) -> Bool {
        guard isEnabled else { return false }

        switch mode {
        case .enabled:
            return true
        case .disabled:
            return false
        case .minimal:
            return category == .error
        case let .custom(categories, _):
            return categories.contains(category)
        }
    }

    /// 기본 설정 (전역 옵션 사용)
    public static let `default` = ViewModelLoggingConfig(
        mode: .enabled,
        customOptions: nil
    )

    /// 비활성화 설정
    public static let disabled = ViewModelLoggingConfig(
        mode: .disabled,
        customOptions: nil
    )

    /// 최소 설정
    public static let minimal = ViewModelLoggingConfig(
        mode: .minimal,
        customOptions: nil
    )

    // MARK: - Initializers

    /// 기본 생성자 (전역 옵션 사용)
    public init(mode: ViewModelLoggingMode) {
        self.mode = mode
        customOptions = nil
    }

    /// 전체 옵션 생성자
    public init(
        mode: ViewModelLoggingMode,
        customOptions: LoggingOptions?
    ) {
        self.mode = mode
        self.customOptions = customOptions
    }

    // MARK: - Builder Methods

    /// 현재 customOptions 또는 기본값을 기반으로 새 옵션 생성
    private func currentOrNewOptions() -> LoggingOptions {
        customOptions ?? LoggingOptions()
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
            customOptions: newOptions
        )
    }

    /// 전역 설정 사용으로 리셋 (커스텀 옵션 제거)
    ///
    /// - Returns: 전역 설정을 사용하는 ViewModelLoggingConfig
    public func usingGlobalOptions() -> ViewModelLoggingConfig {
        ViewModelLoggingConfig(
            mode: mode,
            customOptions: nil
        )
    }
}
