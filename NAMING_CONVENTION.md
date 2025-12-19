# ViewModelLogger 네이밍 컨벤션

## 원칙

`ViewModelLogger` 프로토콜을 채택한 구현체는 `*ViewModelLogger` 네이밍 패턴을 따릅니다.

## 패턴

```
[SDK/기능이름]ViewModelLogger
```

## 예시

### ✅ 올바른 네이밍

| 구현체 | 설명 | 위치 |
|--------|------|------|
| `NoOpLogger` | 로깅 비활성화 | Core (예외: 간단한 구현) |
| `OSLogViewModelLogger` | Apple os.log 사용 | Core |
| `TraceKitViewModelLogger` | TraceKit 사용 (권장) | Core |
| `FirebaseViewModelLogger` | Firebase Crashlytics | Example |
| `SentryViewModelLogger` | Sentry | Example |
| `DatadogViewModelLogger` | Datadog | Example |
| `ConsoleViewModelLogger` | 콘솔 출력 | Example |
| `FileViewModelLogger` | 파일 저장 | Example |
| `CompositeViewModelLogger` | 복합 로거 | Example |
| `ConditionalViewModelLogger` | 조건부 로거 | Example |

### ❌ 잘못된 네이밍

| 잘못된 이름 | 문제점 | 올바른 이름 |
|-------------|--------|-------------|
| `TraceKitBridge` | "Bridge" 접미사 부적절 | `TraceKitViewModelLogger` |
| `LoggerBridge` | 프로토콜명 불명확 | `[SDK]ViewModelLogger` |
| `FirebaseLogger` | 일반적이지만 일관성 부족 | `FirebaseViewModelLogger` |
| `MyLogger` | SDK/기능 불명확 | `MySDKViewModelLogger` |
| `CustomLog` | 패턴 불일치 | `CustomViewModelLogger` |

## 예외 규칙

### 1. 간단한 유틸리티 구현체

매우 간단하고 명확한 경우 짧은 이름 허용:

```swift
// ✅ 허용 (간단하고 명확)
struct NoOpLogger: ViewModelLogger { }

// ✅ 더 명확하게 하려면
struct NoOpViewModelLogger: ViewModelLogger { }
```

### 2. 래퍼/데코레이터 패턴

기능을 설명하는 접두사 사용:

```swift
// ✅ 조건부 래퍼
struct ConditionalViewModelLogger: ViewModelLogger { }

// ✅ 복합 래퍼
struct CompositeViewModelLogger: ViewModelLogger { }

// ✅ 필터링 래퍼
struct FilteredViewModelLogger: ViewModelLogger { }
```

## 파일명

구현체 클래스명과 동일하거나 관련 구현체를 그룹화:

```
✅ TraceKitViewModelLogger.swift (TraceKit 통합 구현 - Core에 포함)
✅ FirebaseViewModelLogger.swift
✅ ExternalLoggingSDKIntegration.swift (여러 SDK 구현체 포함)
```

## 이점

1. **일관성**: 모든 ViewModelLogger 구현체를 쉽게 식별
2. **명확성**: SDK나 기능을 이름으로 즉시 파악
3. **검색 용이성**: IDE에서 "ViewModelLogger" 검색 시 모든 구현체 발견
4. **유지보수**: 새로운 개발자도 패턴을 쉽게 이해

## 구현 예시

### TraceKit 통합 (권장)

```swift
// ✅ TraceKitViewModelLogger.swift (Core에 포함됨)
import AsyncViewModel
import TraceKit

@MainActor
public struct TraceKitViewModelLogger: ViewModelLogger {
    public init() {}
    
    public func logAction(...) {
        TraceKit.log(
            level: level.traceLevel,
            message,
            category: viewModel,
            ...
        )
    }
}
```

### Firebase 통합

```swift
// ✅ ExternalLoggingSDKIntegration.swift
import AsyncViewModel
import FirebaseCrashlytics

@MainActor
public struct FirebaseViewModelLogger: ViewModelLogger {
    public func logAction(...) {
        Crashlytics.crashlytics().log("[\(viewModel)] \(action)")
    }
}
```

### 커스텀 콘솔 로거

```swift
// ✅ AppLoggerSetup.swift
import AsyncViewModel

@MainActor
public struct ConsoleViewModelLogger: ViewModelLogger {
    public func logAction(...) {
        print("[\(level)] [\(viewModel)] \(action)")
    }
}
```

## 기존 코드 마이그레이션

### Before (❌ 잘못된 네이밍)
```swift
let bridge = RealTraceKitBridge()
LoggerConfiguration.setLogger(bridge)
```

### After (✅ 올바른 네이밍)
```swift
let logger = TraceKitViewModelLogger()
ViewModelLoggerConfiguration.shared.setDefaultLogger(logger)
```

## 요약

- ✅ `[SDK/기능]ViewModelLogger` 패턴 사용
- ✅ 일관성 유지
- ✅ 명확한 이름 선택
- ❌ "Bridge", "Wrapper" 등 불필요한 접미사 지양
- ❌ 프로토콜과 무관한 네이밍 지양
