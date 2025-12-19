# AsyncViewModel 로깅 아키텍처 개선

## 개요

AsyncViewModel의 로깅 시스템을 외부에서 주입받을 수 있도록 개선했습니다. ViewModelLogger 프로토콜을 통해 어떤 로깅 SDK든 통합할 수 있는 유연하고 확장 가능한 아키텍처를 제공합니다.

## 핵심 개념

🎯 **목적**: AsyncViewModel에서 사용자가 원하는 어떤 로깅 SDK든 자유롭게 통합할 수 있도록 함

✅ **지원 가능한 로깅 SDK**:
- [TraceKit](https://github.com/Jimmy-Jung/TraceKit) v1.1.1+ (권장 - 기본 포함)
- Firebase Crashlytics
- Sentry
- Datadog
- CocoaLumberjack
- SwiftyBeaver
- OSLog
- 커스텀 로깅 시스템

## 주요 변경사항

### 1. ViewModelLogger 프로토콜 추가

```swift
@MainActor
public protocol ViewModelLogger: Sendable {
    func logAction(_ action: String, viewModel: String, level: LogLevel, ...)
    func logStateChange(from oldState: String, to newState: String, ...)
    func logEffect(_ effect: String, viewModel: String, ...)
    func logPerformance(operation: String, duration: TimeInterval, ...)
    func logError(_ error: SendableError, viewModel: String, level: LogLevel, ...)
}
```

**위치**: `Sources/Core/ViewModelLogger.swift`

### 2. 기본 구현 제공

#### NoOpLogger
로깅을 수행하지 않는 구현. 프로덕션 환경이나 성능 최적화가 필요한 경우 사용.

```swift
let viewModel = MyViewModel()
viewModel.logger = NoOpLogger()
```

#### OSLogViewModelLogger
기존 os.log를 사용하는 구현. 기본 동작과 동일.

```swift
let viewModel = MyViewModel()
viewModel.logger = OSLogViewModelLogger(subsystem: "com.myapp")
```

### 3. TraceKitViewModelLogger 구현

[TraceKit](https://github.com/Jimmy-Jung/TraceKit) (v1.1.1+)과의 통합을 위한 브릿지.

**위치**: `Sources/Core/TraceKitViewModelLogger.swift`

```swift
// TraceKit 설정
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

> TraceKit은 AsyncViewModel의 기본 의존성으로 포함되어 있습니다.

### 4. AsyncViewModelProtocol 개선

로거 주입 프로퍼티 추가:

```swift
public protocol AsyncViewModelProtocol {
    // ... 기존 프로퍼티들
    
    /// 외부 로거 인스턴스
    var logger: (any ViewModelLogger)? { get set }
}
```

**기본 동작**: `logger`가 `nil`이면 전역 기본 로거(`OSLogViewModelLogger`)를 사용합니다.

## 아키텍처 다이어그램

```mermaid
graph TB
    subgraph "AsyncViewModel Core"
        AVM[AsyncViewModelProtocol]
        AVM --> VML[ViewModelLogger Protocol]
    end
    
    subgraph "로거 구현"
        VML --> NoOp[NoOpLogger]
        VML --> OSLog[OSLogViewModelLogger]
        VML --> TraceKitBridge[TraceKitViewModelLogger]
        VML --> Custom[Custom Logger]
    end
    
    subgraph "TraceKit"
        TraceKitBridge --> TraceKit[TraceKit]
        TraceKit --> Console[Console]
        TraceKit --> OSLog2[OSLog]
        TraceKit --> File[File]
        TraceKit --> External[External Services]
    end
```

## 사용 예시

### 1. 기본 사용 (변경 없음)

```swift
@AsyncViewModel(isLoggingEnabled: true, logLevel: .debug)
class MyViewModel: ObservableObject {
    // logger 프로퍼티가 nil이면 기존 os.log 사용
}
```

### 2. 로깅 비활성화

```swift
let viewModel = MyViewModel()
viewModel.logger = NoOpLogger()
```

### 3. 커스텀 로거 구현

```swift
@MainActor
struct ConsoleLogger: ViewModelLogger {
    func logAction(_ action: String, viewModel: String, level: LogLevel, ...) {
        print("[\(level.description)] \(viewModel) - Action: \(action)")
    }
    // ... 다른 메서드 구현
}

let viewModel = MyViewModel()
viewModel.logger = ConsoleLogger()
```

### 4. TraceKit 통합 (권장)

```swift
// 앱 초기화 시
Task { @TraceKitActor in
    await TraceKitBuilder
        .debug()
        .buildAsShared()
}

// ViewModel에 전역 로거 설정
Task { @MainActor in
    let logger = TraceKitViewModelLogger()
    LoggerConfiguration.setLogger(logger)
}

// 모든 ViewModel에 자동 적용됨
let viewModel = MyViewModel()
// logger 프로퍼티를 nil로 두면 전역 로거 사용
```

## 파일 구조

```
AsyncViewModel/
├── Sources/
│   └── Core/
│       ├── AsyncViewModelProtocol.swift      (수정)
│       ├── ViewModelLogger.swift             (신규)
│       ├── TraceKitViewModelLogger.swift     (신규)
│       └── LogLevel.swift                    (기존)
├── Tests/
│   └── AsyncViewModelTests/
│       └── ViewModelLoggerTests.swift        (신규)
└── Example/
    └── Sources/
        └── Examples/
            └── LoggerIntegrationExample.swift      (신규)
```

## 설계 원칙

1. **프로토콜 기반 추상화**: ViewModelLogger 프로토콜로 다양한 로깅 백엔드 지원
2. **기본값 제공**: OSLogViewModelLogger를 기본 로거로 제공하여 즉시 사용 가능
3. **유연성**: NoOp, OSLog, TraceKit, Custom 등 다양한 선택지 제공
4. **테스트 가능성**: MockLogger를 통한 테스트 지원
5. **성능**: NoOpLogger로 프로덕션 환경 최적화 가능

## TraceKit과의 통합 장점

1. **고급 기능**
   - 버퍼링 및 배치 처리
   - 샘플링 (로그 양 조절)
   - 정제 (민감정보 마스킹)
   - 크래시 로그 보존
   - 성능 측정 (Performance Tracing)

2. **다양한 Destination**
   - Console
   - OSLog
   - File
   - 외부 서비스 (Datadog, Sentry, Firebase 등)

3. **성능 최적화**
   - Actor 기반 스레드 안전성 (@TraceKitActor)
   - 비동기 처리
   - 효율적인 메모리 사용
   - Fire-and-Forget API로 UI 블로킹 방지

## 테스트

전체 테스트 스위트가 포함되어 있습니다:

```bash
swift test
```

주요 테스트:
- NoOpLogger 동작 확인
- 커스텀 로거 기록 확인
- 로깅 활성화/비활성화
- 로그 레벨 필터링
- 성능 메트릭 기록
- 후방 호환성

## 마이그레이션 가이드

### 기존 코드 (변경 불필요)

```swift
@AsyncViewModel(isLoggingEnabled: true, logLevel: .debug)
class MyViewModel: ObservableObject {
    // 기존대로 동작
}
```

### 커스텀 로거 사용

```swift
@AsyncViewModel(isLoggingEnabled: true, logLevel: .debug)
class MyViewModel: ObservableObject {
    init() {
        // 초기화 시 로거 설정
        self.logger = MyCustomLogger()
    }
}
```

### TraceKit 사용 (권장)

1. Package.swift에 TraceKit 의존성이 이미 추가되어 있음
2. 앱 초기화 시 TraceKit 설정
3. TraceKitViewModelLogger를 전역 기본 로거로 설정

## 로거 우선순위

AsyncViewModel은 전역 기본 로거를 사용합니다:

- **전역 기본 로거** (`LoggerConfiguration.logger`)
  - 모든 ViewModel에서 사용
  - 기본값: `OSLogViewModelLogger` (os.log 사용)
  - 앱 시작 시 한 번만 설정하면 모든 ViewModel에 적용

## 통합 가능한 로깅 SDK 목록

### 상용 서비스
- ✅ **Firebase Crashlytics** - Google의 크래시 리포팅 및 로깅
- ✅ **Sentry** - 에러 추적 및 성능 모니터링
- ✅ **Datadog** - 풀스택 관찰성 플랫폼
- ✅ **New Relic** - 애플리케이션 성능 모니터링
- ✅ **Bugsnag** - 에러 모니터링

### 오픈소스
- ✅ **TraceKit** - 고성능 구조화 로깅 프레임워크 (권장)
- ✅ **CocoaLumberjack** - 강력한 iOS 로깅 프레임워크
- ✅ **SwiftyBeaver** - 컬러풀한 콘솔 및 클라우드 로깅
- ✅ **OSLog** - Apple의 통합 로깅 시스템

### 커스텀
- ✅ 자체 로깅 시스템
- ✅ 파일 기반 로거
- ✅ 네트워크 로거

## 통합 방법

1. **ViewModelLogger 프로토콜 구현**
2. **앱 시작 시 전역 로거 설정**
3. **끝!** - 모든 ViewModel에 자동 적용

## 예제 코드 위치

- `ExternalLoggingSDKIntegration.swift` - 다양한 SDK 통합 예시
- `AppLoggerSetup.swift` - 앱 시작 시 설정 예시
- `LoggerIntegrationExample.swift` - 기본 사용 예시

## 다음 단계

1. **원하는 로깅 SDK 선택**
   - Firebase, Sentry, Datadog 등에서 선택

2. **ViewModelLogger 구현**
   - 5-10분이면 충분

3. **앱 시작 시 설정**
   - App init 또는 AppDelegate에서 1줄

4. **끝!**
   - 모든 ViewModel에 자동으로 적용됨

## 결론

AsyncViewModel의 로깅 시스템이 외부 주입 가능한 아키텍처로 개선되었습니다. 기존 코드와의 호환성을 유지하면서도 TraceKit과 같은 고급 로깅 시스템을 통합할 수 있는 유연성을 제공합니다.
