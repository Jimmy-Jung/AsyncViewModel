# ViewModelLoggerBuilder 사용 가이드

## 개요

`ViewModelLoggerBuilder`는 TraceKit 스타일의 빌더 패턴을 사용하여 AsyncViewModel의 로거를 구성합니다.

## 기본 사용법

### 1. OSLog 로거 사용

```swift
@MainActor
func setupLogger() {
    await ViewModelLoggerBuilder()
        .addLogger(OSLogViewModelLogger(subsystem: "com.myapp"))
        .withFormat(.compact)
        .withMinimumLevel(.info)
        .buildAsShared()
}
```

### 2. 커스텀 로거 사용

```swift
@MainActor
func setupLogger() {
    await ViewModelLoggerBuilder()
        .addLogger(MyCustomLogger())
        .withFormat(.detailed)
        .withMinimumLevel(.verbose)
        .buildAsShared()
}
```

### 3. TraceKit 로거 사용 (Example 프로젝트)

```swift
@MainActor
func setupLogger() {
    await ViewModelLoggerBuilder()
        .addLogger(TraceKitViewModelLogger())
        .withFormat(.standard)
        .withMinimumLevel(.debug)
        .buildAsShared()
}
```

## 프리셋 사용

### Debug 프리셋
```swift
await ViewModelLoggerBuilder.debug()
    .buildAsShared()
```

설정:
- Logger: `OSLogViewModelLogger`
- Format: `.detailed`
- MinimumLevel: `.verbose`
- StateDiffOnly: `false`
- GroupEffects: `false`
- ZeroPerformance: `true`

### Production 프리셋
```swift
await ViewModelLoggerBuilder.production()
    .buildAsShared()
```

설정:
- Logger: `OSLogViewModelLogger`
- Format: `.compact`
- MinimumLevel: `.warning`
- StateDiffOnly: `true`
- GroupEffects: `true`
- ZeroPerformance: `false`

### 로깅 비활성화
```swift
await ViewModelLoggerBuilder.disabled()
    .buildAsShared()
```

## 설정 메서드

### withFormat(_ format: LogFormat)
로그 출력 포맷 설정
- `.compact`: 한 줄 요약
- `.standard`: 기본 포맷
- `.detailed`: 상세 포맷

```swift
.withFormat(.compact)
```

### withPerformanceThreshold(_ threshold: PerformanceThreshold?)
성능 로그 임계값 설정

```swift
// 커스텀 임계값
.withPerformanceThreshold(
    PerformanceThreshold(type: .actionProcessing, customThreshold: 0.05)
)

// 스마트 임계값 (자동 추론)
.withPerformanceThreshold(nil)
```

### withStateDiffOnly(_ enabled: Bool = true)
State diff만 표시 (전체 State 대신)

```swift
.withStateDiffOnly(true)
```

### withGroupEffects(_ enabled: Bool = true)
Effect를 그룹화하여 표시

```swift
.withGroupEffects(true)
```

### withZeroPerformance(_ enabled: Bool = true)
0초 성능 로그도 표시

```swift
.withZeroPerformance(false)
```

### withMinimumLevel(_ level: LogLevel)
최소 로그 레벨 설정

```swift
.withMinimumLevel(.warning)
```

## build vs buildAsShared

### build()
로거 인스턴스만 반환 (전역 설정 안함)

```swift
let logger = await ViewModelLoggerBuilder()
    .addLogger(OSLogViewModelLogger())
    .build()

// 수동으로 설정
LoggerConfiguration.setLogger(logger)
```

### buildAsShared()
로거 인스턴스를 생성하고 전역으로 설정

```swift
await ViewModelLoggerBuilder()
    .addLogger(OSLogViewModelLogger())
    .buildAsShared()

// 자동으로 LoggerConfiguration에 설정됨
```

## AppDelegate 통합 예시

```swift
@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        setupLogging()
        return true
    }
    
    private func setupLogging() {
        #if DEBUG
        Task { @MainActor in
            await ViewModelLoggerBuilder.debug()
                .buildAsShared()
        }
        #else
        Task { @MainActor in
            await ViewModelLoggerBuilder.production()
                .buildAsShared()
        }
        #endif
    }
}
```

## TraceKit 통합 예시

```swift
private func setupLogging() {
    // 1. TraceKit 초기화
    Task { @TraceKitActor in
        await TraceKitBuilder.debug()
            .buildAsShared()
    }
    
    // 2. AsyncViewModel에 TraceKit 연결
    Task { @MainActor in
        await ViewModelLoggerBuilder()
            .addLogger(TraceKitViewModelLogger())
            .withFormat(.compact)
            .withMinimumLevel(.info)
            .buildAsShared()
        
        TraceKit.info("✅ AsyncViewModel logger configured")
    }
}
```

## 커스텀 로거 구현

```swift
struct MyCustomLogger: ViewModelLogger {
    var options: LoggingOptions = .init()
    
    func logAction(
        _ action: String,
        viewModel: String,
        level: LogLevel,
        file: String,
        function: String,
        line: Int
    ) {
        print("[MyLogger] Action: \(action)")
    }
    
    // ... 나머지 메서드 구현
}

// 사용
await ViewModelLoggerBuilder()
    .addLogger(MyCustomLogger())
    .buildAsShared()
```

## 마이그레이션 가이드

### Before (직접 설정)
```swift
var logger = OSLogViewModelLogger(subsystem: "com.app")
logger.options.format = .compact
logger.options.minimumLevel = .info
logger.options.showStateDiffOnly = true
LoggerConfiguration.setLogger(logger)
```

### After (빌더 패턴)
```swift
await ViewModelLoggerBuilder()
    .addLogger(OSLogViewModelLogger(subsystem: "com.app"))
    .withFormat(.compact)
    .withMinimumLevel(.info)
    .withStateDiffOnly(true)
    .buildAsShared()
```

## 주의사항

1. `@MainActor` 필수: 빌더 메서드는 메인 액터에서만 호출 가능
2. `await` 필요: `build()`, `buildAsShared()`는 async 메서드
3. 로거 없이 build 시: `NoOpLogger` 자동 반환 (로깅 비활성화)
