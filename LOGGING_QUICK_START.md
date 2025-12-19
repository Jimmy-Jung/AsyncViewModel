# AsyncViewModel 로깅 빠른 시작 가이드

## 개선된 로깅 시스템

AsyncViewModel의 로깅이 크게 개선되어 가독성이 향상되고 성능이 최적화되었습니다.

### 주요 개선 사항

1. 로그 출력량 90-98% 감소
2. State 변경 시 diff만 표시
3. Effect 그룹화
4. 성능 로그 임계값 필터링
5. 3가지 포맷 모드 (compact, standard, detailed)

---

## 빠른 설정

### 1. 기본 사용 (간결한 로그)

```swift
// AppDelegate.swift 또는 App.swift
import AsyncViewModel
import TraceKit

@main
struct MyApp: App {
    init() {
        // TraceKit 초기화
        Task { @TraceKitActor in
            await TraceKitBuilder.debug().buildAsShared()
        }
        
        // AsyncViewModel 로거 설정
        Task { @MainActor in
            var logger = TraceKitViewModelLogger()
            logger.options.format = .compact
            LoggerConfiguration.setLogger(logger)
        }
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
```

### 출력 예시 (Compact)

```
20:23:03.600 ℹ️ [Calculator] inputNumber(2) → display: "0" → "2" (0.018s)
20:23:04.251 ℹ️ [Calculator] inputNumber(3) → display: "2" → "23"
20:23:05.093 ℹ️ [Calculator] setOperation(add) → currentOperation: nil → add
20:23:06.302 ℹ️ [Calculator] calculate → display: "23" → "46"
```

단일 액션당 1줄! (기존 60줄 이상 → 1줄)

---

## 포맷 모드 비교

### Compact 모드 (프로덕션 권장)

가장 간결하고 핵심 정보만 표시합니다.

```swift
logger.options.format = .compact
```

**출력 예시:**
```
ℹ️ [Calculator] inputNumber(2) → display: "0" → "2"
```

### Standard 모드 (개발 환경 기본)

균형잡힌 가독성과 정보량을 제공합니다.

```swift
logger.options.format = .standard
```

**출력 예시:**
```
ℹ️ [Calculator] Action: inputNumber(2)
🔍 [Calculator] Effects[3]: cancel, action, run
ℹ️ [Calculator] State changed:
  - display: "0" → "2"
  - calculatorState.currentValue: 0.0 → 2.0
🔍 [Calculator] Performance: 0.018s
```

### Detailed 모드 (디버깅용)

모든 상세 정보를 표시합니다.

```swift
logger.options.format = .detailed
```

---

## 로깅 옵션 상세 설명

### LoggingOptions

```swift
public struct LoggingOptions {
    /// 로그 포맷
    var format: LogFormat = .standard
    
    /// 성능 로그 임계값 (초 단위)
    var performanceThreshold: TimeInterval = 0.001
    
    /// State 변경 시 diff만 표시
    var showStateDiffOnly: Bool = true
    
    /// Effect 그룹화
    var groupEffects: Bool = true
    
    /// 0초 성능 메트릭 표시 여부
    var showZeroPerformance: Bool = false
}
```

### 옵션별 효과

#### 1. format (로그 포맷)

```swift
// 간결 (프로덕션)
logger.options.format = .compact

// 균형 (개발)
logger.options.format = .standard

// 상세 (디버깅)
logger.options.format = .detailed
```

#### 2. performanceThreshold (성능 로그 임계값)

```swift
// 10ms 이상만 로깅 (권장)
logger.options.performanceThreshold = 0.010

// 1ms 이상만 로깅
logger.options.performanceThreshold = 0.001

// 모든 성능 로그 표시
logger.options.performanceThreshold = 0.0
```

**효과:** 의미 없는 0.000s 로그를 제거합니다.

#### 3. showStateDiffOnly (State Diff 표시)

```swift
// diff만 표시 (권장)
logger.options.showStateDiffOnly = true

// 전체 State 표시
logger.options.showStateDiffOnly = false
```

**Before (전체 State):**
```
State changed from:
State(
  display: 2,
  activeAlert: nil,
  calculatorState: CalculatorState(
    display: 2,
    currentValue: 2.0,
    previousValue: 0.0,
    currentOperation: nil,
    shouldResetDisplay: false
  ),
  isAutoClearTimerActive: false
)
to:
State(
  display: 23,
  ...
)
```

**After (Diff만):**
```
State changed:
  - display: "2" → "23"
  - calculatorState.currentValue: 2.0 → 23.0
```

#### 4. groupEffects (Effect 그룹화)

```swift
// 그룹으로 표시 (권장)
logger.options.groupEffects = true

// 개별 표시
logger.options.groupEffects = false
```

**Before (개별):**
```
🔍 Effect: cancel(id: autoClearTimer)
🔍 Effect: action(setTimerActive(false))
🔍 Effect: run(id: nil, operation: ...)
```

**After (그룹):**
```
🔍 Effects[3]: cancel, action, run
```

---

## 환경별 권장 설정

### 프로덕션 (Production)

최소한의 로그만 출력합니다.

```swift
Task { @MainActor in
    var logger = TraceKitViewModelLogger()
    logger.options.format = .compact
    logger.options.performanceThreshold = 0.050 // 50ms 이상만
    LoggerConfiguration.setLogger(logger)
}

// ViewModel 레벨 설정
viewModel.logLevel = .warning // warning 이상만 로깅
```

### 개발 (Development)

균형잡힌 로그를 출력합니다.

```swift
Task { @MainActor in
    var logger = TraceKitViewModelLogger()
    logger.options.format = .standard
    logger.options.performanceThreshold = 0.010 // 10ms 이상
    logger.options.showStateDiffOnly = true
    logger.options.groupEffects = true
    LoggerConfiguration.setLogger(logger)
}

// ViewModel 레벨 설정
viewModel.logLevel = .info
```

### 디버깅 (Debugging)

상세한 로그를 출력합니다.

```swift
Task { @MainActor in
    var logger = TraceKitViewModelLogger()
    logger.options.format = .detailed
    logger.options.performanceThreshold = 0.001 // 1ms 이상
    logger.options.showStateDiffOnly = false // 전체 State
    logger.options.groupEffects = false      // 개별 Effect
    logger.options.showZeroPerformance = true
    LoggerConfiguration.setLogger(logger)
}

// ViewModel 레벨 설정
viewModel.logLevel = .verbose
```

---

## 실제 사용 예시

### 예시 1: SwiftUI App

```swift
import SwiftUI
import AsyncViewModel
import TraceKit

@main
struct MyApp: App {
    init() {
        setupLogging()
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
    
    private func setupLogging() {
        // TraceKit 초기화
        Task { @TraceKitActor in
            await TraceKitBuilder
                .debug()
                .buildAsShared()
        }
        
        // AsyncViewModel 로거 설정
        Task { @MainActor in
            var logger = TraceKitViewModelLogger()
            
            #if DEBUG
            // 개발 환경
            logger.options.format = .standard
            logger.options.performanceThreshold = 0.010
            #else
            // 프로덕션 환경
            logger.options.format = .compact
            logger.options.performanceThreshold = 0.050
            #endif
            
            LoggerConfiguration.setLogger(logger)
            print("✅ AsyncViewModel logger configured")
        }
    }
}
```

### 예시 2: UIKit App

```swift
import UIKit
import AsyncViewModel
import TraceKit

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
        // TraceKit 초기화
        Task { @TraceKitActor in
            await TraceKitBuilder
                .debug()
                .addDestination(ConsoleTraceDestination())
                .buildAsShared()
        }
        
        // AsyncViewModel 로거 설정
        Task { @MainActor in
            var logger = TraceKitViewModelLogger()
            logger.options.format = .standard
            logger.options.performanceThreshold = 0.010
            LoggerConfiguration.setLogger(logger)
            print("✅ AsyncViewModel logger configured")
        }
    }
}
```

---

## 로깅 비활성화

### 전역 비활성화

```swift
Task { @MainActor in
    LoggerConfiguration.disableLogging()
}
```

### ViewModel별 비활성화

```swift
@Observable
final class MyViewModel: AsyncViewModelProtocol {
    var isLoggingEnabled = false // 이 ViewModel만 로깅 비활성화
    // ...
}
```

---

## 성능 비교

### Before (기존 로깅)

```
단일 액션당 출력: 60줄 이상
- Action: 2줄
- Effect × 3: 6줄
- Performance × 5: 10줄
- State Change: 40줄 이상
```

### After (개선된 로깅)

**Compact 모드:**
```
단일 액션당 출력: 1줄 (98% 감소)
```

**Standard 모드:**
```
단일 액션당 출력: 4-5줄 (90% 감소)
```

**Detailed 모드:**
```
단일 액션당 출력: 필요한 만큼 (디버깅용)
```

---

## 마이그레이션 가이드

### 기존 코드 (변경 불필요)

기존 코드는 그대로 동작합니다. 옵션을 설정하지 않으면 기본값이 적용됩니다.

```swift
@Observable
final class MyViewModel: AsyncViewModelProtocol {
    var isLoggingEnabled = true
    var logLevel: LogLevel = .debug
    
    // 기존 코드 그대로 동작
}
```

### 옵션 추가 (선택)

더 나은 로깅 경험을 원하면 옵션을 추가하세요.

```swift
// AppDelegate나 App.swift에 한 번만 설정
Task { @MainActor in
    var logger = TraceKitViewModelLogger()
    logger.options.format = .standard
    logger.options.performanceThreshold = 0.010
    LoggerConfiguration.setLogger(logger)
}
```

---

## 문제 해결

### Q: 로그가 출력되지 않아요

**A1:** ViewModel의 `isLoggingEnabled`를 확인하세요.
```swift
viewModel.isLoggingEnabled = true
```

**A2:** 로그 레벨을 확인하세요.
```swift
viewModel.logLevel = .debug // 또는 .verbose
```

**A3:** 전역 로거가 설정되어 있는지 확인하세요.
```swift
// 로거가 설정되지 않은 경우 기본 OSLogViewModelLogger 사용
```

### Q: 너무 많은 로그가 출력돼요

**A:** Compact 모드로 전환하세요.
```swift
logger.options.format = .compact
logger.options.performanceThreshold = 0.050 // 50ms 이상만
```

### Q: State 전체를 보고 싶어요

**A:** `showStateDiffOnly`를 false로 설정하세요.
```swift
logger.options.showStateDiffOnly = false
```

### Q: 모든 Effect를 개별적으로 보고 싶어요

**A:** `groupEffects`를 false로 설정하세요.
```swift
logger.options.groupEffects = false
```

---

## 추가 리소스

- [전체 아키텍처 가이드](LOGGING_ARCHITECTURE.md)
- [상세 개선 계획](LOGGING_IMPROVEMENT_PLAN.md)
- [네이밍 컨벤션](NAMING_CONVENTION.md)
- [AsyncViewModel 가이드](README.md)

---

## 요약

1. **설정 한 줄로 시작**
   ```swift
   var logger = TraceKitViewModelLogger()
   logger.options.format = .compact
   LoggerConfiguration.setLogger(logger)
   ```

2. **로그 출력량 98% 감소** (60줄 → 1줄)

3. **3가지 포맷 모드**
   - Compact: 프로덕션용
   - Standard: 개발용
   - Detailed: 디버깅용

4. **기존 코드 변경 불필요** - 하위 호환성 유지

5. **환경별 최적화**
   - Production: Compact + 50ms 임계값
   - Development: Standard + 10ms 임계값
   - Debugging: Detailed + 모든 로그

시작하세요! 🚀
