# AsyncViewModel 외부 로깅 SDK 통합 빠른 시작

## 5분 안에 원하는 로깅 SDK 통합하기

### 1단계: ViewModelLogger 구현 (2분)

원하는 로깅 SDK의 API를 호출하는 구조체를 만듭니다.

```swift
import AsyncViewModel

@MainActor
struct MyCustomLogger: ViewModelLogger {
    func logAction(_ action: String, viewModel: String, level: LogLevel, ...) {
        // 여기에 원하는 로깅 SDK 호출
        YourLoggingSDK.log("[\(viewModel)] Action: \(action)")
    }
    
    func logStateChange(from oldState: String, to newState: String, ...) {
        YourLoggingSDK.log("[\(viewModel)] State changed")
    }
    
    func logEffect(_ effect: String, ...) {
        // Effect는 선택적으로 로깅
    }
    
    func logPerformance(operation: String, duration: TimeInterval, ...) {
        YourLoggingSDK.trackPerformance(operation, duration)
    }
    
    func logError(_ error: SendableError, ...) {
        YourLoggingSDK.reportError(error)
    }
}
```

### 2단계: 앱 시작 시 설정 (1분)

#### SwiftUI
```swift
@main
struct MyApp: App {
    init() {
        Task { @MainActor in
            let logger = MyCustomLogger()
            LoggerConfiguration.setLogger(logger)
        }
    }
}
```

#### UIKit
```swift
func application(_ application: UIApplication, ...) -> Bool {
    Task { @MainActor in
        let logger = MyCustomLogger()
        LoggerConfiguration.setLogger(logger)
    }
    return true
}
```

### 3단계: 끝!

이제 모든 AsyncViewModel에서 자동으로 MyCustomLogger가 사용됩니다.

```swift
@AsyncViewModel(isLoggingEnabled: true)
class MyViewModel: ObservableObject {
    // 아무것도 안 해도 MyCustomLogger 사용됨!
}
```

## 실전 예시

### TraceKit (권장)

[TraceKit](https://github.com/Jimmy-Jung/TraceKit) v1.1.1+는 AsyncViewModel에 기본 포함되어 있습니다.

```swift
import TraceKit

// 1. 앱 초기화 시 TraceKit 설정
Task { @TraceKitActor in
    await TraceKitBuilder
        .debug()
        .buildAsShared()
}

// 2. AsyncViewModel에 통합
Task { @MainActor in
    let logger = TraceKitViewModelLogger()
    LoggerConfiguration.setLogger(logger)
}

// 3. 끝! 모든 ViewModel에 자동 적용됨
```

TraceKit의 장점:
- 고급 버퍼링 및 샘플링
- 민감정보 자동 마스킹
- 크래시 로그 보존
- 성능 측정 지원
- 다양한 Destination (Console, OSLog, File, 외부 서비스)
- Actor 기반 스레드 안전성

### Firebase Crashlytics

```swift
import FirebaseCrashlytics

@MainActor
struct FirebaseLogger: ViewModelLogger {
    func logAction(...) {
        Crashlytics.crashlytics().log("[\(viewModel)] \(action)")
    }
    
    func logError(_ error: SendableError, ...) {
        let nsError = NSError(domain: error.domain, code: error.code, ...)
        Crashlytics.crashlytics().record(error: nsError)
    }
    
    // 나머지 메서드 구현...
}

// 사용
ViewModelLoggerConfiguration.shared.setDefaultLogger(FirebaseLogger())
```

### Sentry

```swift
import Sentry

@MainActor
struct SentryLogger: ViewModelLogger {
    func logAction(...) {
        let breadcrumb = Breadcrumb(level: .info, category: viewModel)
        breadcrumb.message = action
        SentrySDK.addBreadcrumb(breadcrumb)
    }
    
    func logError(_ error: SendableError, ...) {
        SentrySDK.capture(error: error as Error)
    }
    
    // 나머지 메서드 구현...
}

// 사용
ViewModelLoggerConfiguration.shared.setDefaultLogger(SentryLogger())
```

### 여러 SDK 동시 사용

```swift
let logger = CompositeViewModelLogger(loggers: [
    FirebaseLogger(),
    SentryLogger(),
    ConsoleLogger()  // 개발 시 콘솔 출력
])

LoggerConfiguration.setLogger(logger)
```

## 팁

### 환경별 로거

```swift
#if DEBUG
ViewModelLoggerConfiguration.shared.setDefaultLogger(ConsoleLogger())
#else
ViewModelLoggerConfiguration.shared.setDefaultLogger(FirebaseLogger())
#endif
```

### 특정 ViewModel만 다른 로거

```swift
// 전역: Firebase 사용
ViewModelLoggerConfiguration.shared.setDefaultLogger(FirebaseLogger())

// 결제 ViewModel만 특별 로거
let paymentVM = PaymentViewModel()
paymentVM.logger = SecureLogger()  // 개인정보 보호 강화
```

### 프로덕션 최적화

```swift
// 로깅 완전히 비활성화로 성능 최적화
LoggerConfiguration.disableLogging()
```

## 더 알아보기

- `LOGGING_ARCHITECTURE.md` - 전체 아키텍처 설명
- `ExternalLoggingSDKIntegration.swift` - 다양한 SDK 통합 예시
- `AppLoggerSetup.swift` - 실전 설정 예시
