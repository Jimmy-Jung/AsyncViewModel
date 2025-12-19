# AsyncViewModel 아키텍처

## 로깅 시스템 설계 원칙

AsyncViewModel의 로깅 시스템은 의존성 역전 원칙(DIP)에 기반하여 설계되었습니다.

## 계층 구조

```
┌─────────────────────────────────────┐
│         Application Layer           │
│  (Example, User's App)              │
│  - 원하는 로깅 SDK 선택             │
│  - ViewModelLogger 구현             │
└────────────┬────────────────────────┘
             │ depends on
             ▼
┌─────────────────────────────────────┐
│      AsyncViewModel Core            │
│  - ViewModelLogger 프로토콜만 제공  │
│  - 구체적 구현 의존성 없음 ✅        │
└─────────────────────────────────────┘
```

## 핵심 원칙

### ✅ DO: 올바른 의존성

1. **Application → AsyncViewModel Core**
   - 앱은 AsyncViewModel Core를 의존
   - 앱은 원하는 로깅 SDK를 선택하여 의존
   - 앱에서 `ViewModelLogger` 프로토콜을 구현하여 연결

2. **AsyncViewModel Core → Protocol만**
   - Core는 `ViewModelLogger` 프로토콜만 정의
   - 어떤 로깅 라이브러리도 직접 의존하지 않음

### ❌ DON'T: 잘못된 의존성

1. **AsyncViewModel Core → 구체적 로깅 SDK**
   - ❌ Core가 Logger/Sentry/Firebase 등을 직접 import
   - ❌ Core가 특정 로깅 SDK의 타입을 알고 있음
   - ❌ Core에 구체적 구현 포함

## 파일 구조

### AsyncViewModel Core

```
AsyncViewModel/Sources/Core/
├── AsyncViewModelProtocol.swift
│   └── var logger: (any ViewModelLogger)?
│
└── ViewModelLogger.swift
    ├── ViewModelLogger 프로토콜       (인터페이스)
    ├── NoOpLogger                      (로깅 비활성화)
    ├── OSLogViewModelLogger            (기본 os.log)
    └── LoggerConfiguration    (전역 설정)
```

**특징**:
- 외부 로깅 SDK import 없음
- 프로토콜과 기본 구현만 제공
- 완전한 독립성 유지

### Application Layer

```
Example/Sources/Examples/
├── ExternalLoggingSDKIntegration.swift
│   ├── TraceKit 예시 (권장)
│   ├── FirebaseLogger 예시
│   ├── SentryLogger 예시
│   └── DatadogLogger 예시
│
└── AppLoggerSetup.swift
    └── 앱 시작 시 로거 설정
```

**특징**:
- 원하는 로깅 SDK import
- `ViewModelLogger` 구현
- 앱 시작 시 전역 로거 설정

## 사용 흐름

### 1. Core: 인터페이스 정의

```swift
// ViewModelLogger.swift
@MainActor
public protocol ViewModelLogger: Sendable {
    func logAction(
        _ action: String,
        viewModel: String,
        level: LogLevel,
        file: String,
        function: String,
        line: Int
    )
    
    func logStateChange(
        from oldState: String,
        to newState: String,
        viewModel: String,
        file: String,
        function: String,
        line: Int
    )
    
    // ... 기타 메서드
}
```

### 2. App: 구현체 작성

#### 예시 1: TraceKit (권장)

TraceKit은 AsyncViewModel Core에 이미 포함되어 있습니다.

```swift
import AsyncViewModel
import TraceKit

// TraceKit 초기화
Task { @TraceKitActor in
    await TraceKitBuilder
        .debug()
        .buildAsShared()
}

// AsyncViewModel에 연결
Task { @MainActor in
    let logger = TraceKitViewModelLogger()
    LoggerConfiguration.setLogger(logger)
}
```

#### 예시 2: Firebase Crashlytics

```swift
import AsyncViewModel
import FirebaseCrashlytics

@MainActor
struct FirebaseLogger: ViewModelLogger {
    func logAction(...) {
        Crashlytics.crashlytics().log("[\(viewModel)] \(action)")
    }
    
    func logError(...) {
        let nsError = NSError(
            domain: error.domain,
            code: error.code,
            userInfo: [NSLocalizedDescriptionKey: error.message]
        )
        Crashlytics.crashlytics().record(error: nsError)
    }
}
```

#### 예시 3: Sentry

```swift
import AsyncViewModel
import Sentry

@MainActor
struct SentryLogger: ViewModelLogger {
    func logAction(...) {
        let breadcrumb = Breadcrumb(level: mapLevel(level), category: viewModel)
        breadcrumb.message = action
        SentrySDK.addBreadcrumb(breadcrumb)
    }
}
```

### 3. App: 전역 로거 설정

```swift
// AppDelegate.swift
import AsyncViewModel
import TraceKit

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    func application(...) -> Bool {
        // TraceKit 초기화
        Task { @TraceKitActor in
            await TraceKitBuilder
                .debug()
                .buildAsShared()
        }
        
        // AsyncViewModel에 연결
        Task { @MainActor in
            let logger = TraceKitViewModelLogger()
            LoggerConfiguration.setLogger(logger)
        }
        return true
    }
}
```

## 로거 우선순위

AsyncViewModel은 다음 우선순위로 로거를 선택합니다:

```
1순위: viewModel.logger               (인스턴스별 로거)
    ↓ nil인 경우
2순위: LoggerConfiguration.logger  (전역 로거)
    ↓ nil인 경우
3순위: os.log                         (기본 로거)
```

### 사용 예시

```swift
// 전역 로거 설정 (앱 전체)
ViewModelLoggerConfiguration.shared.setLogger(
    TraceKitViewModelLogger()  // 권장
)
// 기본값: OSLogViewModelLogger (os.log 사용)
// 모든 ViewModel에서 자동으로 사용됨
```

## 장점

### 1. 의존성 역전 원칙 (DIP)
- Core는 추상화(`ViewModelLogger`)에만 의존
- 구체적 구현은 앱에서 주입
- 느슨한 결합

### 2. 유연성
- 어떤 로깅 SDK든 사용 가능
- TraceKit, Firebase, Sentry, Datadog, 커스텀 등
- 런타임에 변경 가능

### 3. 테스트 가능성
- MockLogger로 쉽게 테스트
- Core에 외부 의존성이 없어 단위 테스트 간단
- 빠른 테스트 실행

### 4. 모듈 독립성
- AsyncViewModel Core를 독립적으로 배포
- 외부 SDK 없이도 사용 가능 (NoOp, OSLog)
- SPM, CocoaPods, Carthage 등 자유롭게 배포

### 5. 단일 책임 원칙 (SRP)
- Core: 로깅 인터페이스 정의
- App: 로깅 구현 선택

### 6. 개방-폐쇄 원칙 (OCP)
- Core 수정 없이 새로운 로거 추가
- 확장에는 열려있고 수정에는 닫혀있음

## 고급 사용법

### 1. 복합 로거 (여러 SDK 동시 사용)

```swift
@MainActor
struct CompositeViewModelLogger: ViewModelLogger {
    private let loggers: [any ViewModelLogger]
    
    init(loggers: [any ViewModelLogger]) {
        self.loggers = loggers
    }
    
    func logAction(...) {
        loggers.forEach { $0.logAction(...) }
    }
}

// 사용
let composite = CompositeViewModelLogger(loggers: [
    TraceKitViewModelLogger(),
    FirebaseLogger(),
    SentryLogger()
])

LoggerConfiguration.setLogger(composite)
```

### 2. 조건부 로거

```swift
@MainActor
struct ConditionalViewModelLogger: ViewModelLogger {
    private let baseLogger: any ViewModelLogger
    private let condition: @MainActor @Sendable () -> Bool
    
    func logAction(...) {
        if condition() {
            baseLogger.logAction(...)
        }
    }
}

// 디버그 빌드에서만 로깅
let logger = ConditionalViewModelLogger(
    baseLogger: TraceKitViewModelLogger(),
    condition: { 
        #if DEBUG
        return true
        #else
        return false
        #endif
    }
)
```

### 3. 필터링 로거

```swift
@MainActor
struct FilteredViewModelLogger: ViewModelLogger {
    private let baseLogger: any ViewModelLogger
    private let minLevel: LogLevel
    
    func logAction(...) {
        guard level.rawValue >= minLevel.rawValue else { return }
        baseLogger.logAction(...)
    }
}
```

## 요약

- ✅ AsyncViewModel Core는 로깅 **인터페이스**만 제공
- ✅ 앱에서 로깅 **구현**을 선택하고 주입
- ✅ 깔끔한 의존성 방향 (Core → Protocol ← App)
- ✅ 높은 유연성과 테스트 가능성
- ✅ SOLID 원칙 준수
- ✅ 모듈 독립성 보장
