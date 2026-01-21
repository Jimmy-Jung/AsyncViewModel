//
//  LoggingMode.swift
//  AsyncViewModel
//
//  Created by 정준영 on 2025/01/21.
//

import Foundation

// MARK: - LoggingMode

/// 로깅 모드 - "무엇을 로깅할지"만 담당
///
/// @AsyncViewModel 매크로의 logging 파라미터로 사용됩니다.
/// 컴파일 타임에 설정되어 런타임 성능 오버헤드가 없습니다.
///
/// ## 사용 예시
///
/// ```swift
/// // 모든 로깅 활성화 (기본값)
/// @AsyncViewModel
/// final class MyViewModel: ObservableObject { ... }
///
/// // 로깅 비활성화
/// @AsyncViewModel(logging: .disabled)
/// final class SilentViewModel: ObservableObject { ... }
///
/// // 에러만 로깅
/// @AsyncViewModel(logging: .minimal)
/// final class MinimalViewModel: ObservableObject { ... }
///
/// // 특정 카테고리만 로깅
/// @AsyncViewModel(logging: .only(.action, .error))
/// final class SelectiveViewModel: ObservableObject { ... }
///
/// // 특정 카테고리 제외
/// @AsyncViewModel(logging: .excluding(.stateChange))
/// final class QuietViewModel: ObservableObject { ... }
/// ```
public enum LoggingMode: Sendable {
    // MARK: - Cases

    /// 모든 카테고리 로깅
    case enabled

    /// 로깅 비활성화
    case disabled

    /// 에러만 로깅
    case minimal

    /// 특정 카테고리만 로깅
    case only(Set<LogCategory>)

    /// 특정 카테고리 제외
    case excluding(Set<LogCategory>)

    // MARK: - Convenience Factory Methods

    /// 특정 카테고리만 로깅 (가변 인자)
    public static func only(_ categories: LogCategory...) -> LoggingMode {
        .only(Set(categories))
    }

    /// 특정 카테고리 제외 (가변 인자)
    public static func excluding(_ categories: LogCategory...) -> LoggingMode {
        .excluding(Set(categories))
    }

    // MARK: - Preset Modes

    /// State 변경 로그 제외 (가장 시끄러운 로그)
    public static var noStateChanges: LoggingMode {
        .excluding(.stateChange)
    }

    /// 성능 + 에러만
    public static var performanceOnly: LoggingMode {
        .only(.performance, .error)
    }

    // MARK: - Query Methods

    /// 로깅이 활성화되어 있는지
    public var isEnabled: Bool {
        switch self {
        case .enabled, .minimal, .only, .excluding:
            return true
        case .disabled:
            return false
        }
    }

    /// 특정 카테고리가 활성화되어 있는지
    public func isCategoryEnabled(_ category: LogCategory) -> Bool {
        switch self {
        case .enabled:
            return true
        case .disabled:
            return false
        case .minimal:
            return category == .error
        case let .only(categories):
            return categories.contains(category)
        case let .excluding(categories):
            return !categories.contains(category)
        }
    }
}

// MARK: - LoggerMode

/// Logger 설정 - "어디에 로깅할지"만 담당
///
/// @AsyncViewModel 매크로의 logger 파라미터로 사용됩니다.
///
/// ## 사용 예시
///
/// ```swift
/// // 전역 shared Logger 사용 (기본값)
/// @AsyncViewModel
/// final class MyViewModel: ObservableObject { ... }
///
/// // 커스텀 Logger 사용
/// @AsyncViewModel(logger: .custom(DebugLogger()))
/// final class DebugViewModel: ObservableObject { ... }
///
/// // 로깅 모드와 Logger 조합
/// @AsyncViewModel(logging: .minimal, logger: .custom(TraceKitLogger()))
/// final class MinimalDebugViewModel: ObservableObject { ... }
/// ```
public enum LoggerMode: Sendable {
    /// 전역 shared Logger 사용 (기본값)
    case shared

    /// 커스텀 Logger 사용
    case custom(any ViewModelLogger)
}

// MARK: - LogFormatConfig

/// 로그 포맷 설정 - "어떻게 출력할지"만 담당
///
/// @AsyncViewModel 매크로의 format 파라미터로 사용됩니다.
///
/// ## 사용 예시
///
/// ```swift
/// // 모든 카테고리에 동일 포맷 적용
/// @AsyncViewModel(format: .compact)
/// @AsyncViewModel(format: .standard)
/// @AsyncViewModel(format: .detailed)
///
/// // 카테고리별 개별 포맷 설정
/// @AsyncViewModel(format: .perCategory(action: .compact, state: .detailed))
///
/// // 특정 카테고리만 변경 (나머지는 standard)
/// @AsyncViewModel(format: .action(.compact))
/// @AsyncViewModel(format: .state(.detailed))
/// ```
public enum LogFormatConfig: Sendable {
    // MARK: - Unified Format (모든 카테고리에 동일 적용)

    /// 모든 카테고리에 compact 포맷 적용
    case compact

    /// 모든 카테고리에 standard 포맷 적용 (기본값)
    case standard

    /// 모든 카테고리에 detailed 포맷 적용
    case detailed

    // MARK: - Per-Category Format

    /// 카테고리별 개별 포맷 설정
    case perCategory(
        action: LogFormat = .standard,
        state: LogFormat = .standard,
        effect: LogFormat = .standard
    )

    // MARK: - Convenience Factory Methods

    /// Action만 다른 포맷 사용 (나머지는 standard)
    public static func action(_ format: LogFormat) -> LogFormatConfig {
        .perCategory(action: format)
    }

    /// State만 다른 포맷 사용 (나머지는 standard)
    public static func state(_ format: LogFormat) -> LogFormatConfig {
        .perCategory(state: format)
    }

    /// Effect만 다른 포맷 사용 (나머지는 standard)
    public static func effect(_ format: LogFormat) -> LogFormatConfig {
        .perCategory(effect: format)
    }

    // MARK: - Conversion to LoggingOptions

    /// LoggingOptions로 변환
    public func toLoggingOptions() -> LoggingOptions {
        switch self {
        case .compact:
            return LoggingOptions(
                actionFormat: .compact,
                stateFormat: .compact,
                effectFormat: .compact
            )
        case .standard:
            return LoggingOptions(
                actionFormat: .standard,
                stateFormat: .standard,
                effectFormat: .standard
            )
        case .detailed:
            return LoggingOptions(
                actionFormat: .detailed,
                stateFormat: .detailed,
                effectFormat: .detailed
            )
        case let .perCategory(action, state, effect):
            return LoggingOptions(
                actionFormat: action,
                stateFormat: state,
                effectFormat: effect
            )
        }
    }
}
