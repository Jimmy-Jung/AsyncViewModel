# AsyncViewModel 로깅 개선 종합 계획

## 현재 문제점 분석

### 1. 과도한 로그 출력량
단일 액션(`inputNumber(2)`)에 대해 10개 이상의 로그가 출력됨:
- Action 로그: 1개
- Effect 로그: 3-4개 (개별 출력)
- Performance 로그: 4-5개 (각 단계별)
- State 변경 로그: 1개 (40줄 이상)

```
20:23:03.600 ℹ️ INFO [CalculatorSwiftUIViewModel] Action: inputNumber(2)
  action: inputNumber(2)
  type: action
20:23:03.606 🔍 DEBUG [CalculatorSwiftUIViewModel] Effect: cancel(id: ...)
  effect: cancel(id: ...)
  type: effect
20:23:03.607 🔍 DEBUG [CalculatorSwiftUIViewModel] Effect: action(...)
  effect: action(...)
  type: effect
20:23:03.612 🔍 DEBUG [CalculatorSwiftUIViewModel] Effect: run(...)
  effect: run(...)
  type: effect
20:23:03.612 🔍 DEBUG [CalculatorSwiftUIViewModel] Performance - Action processing: 0.018s
  duration: 0.01792597770690918
  operation: Action processing
  type: performance
... (40줄 이상의 State 변경 로그)
```

### 2. 정보 중복
- 메시지와 메타데이터에 동일한 내용 반복
- `"Action: inputNumber(2)"` + `metadata: ["action": "inputNumber(2)"]`

### 3. State 출력 과다
- 전체 State를 변경 전/후로 두 번 출력 (각 20줄 이상)
- 실제 변경된 필드는 1-2개뿐

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

### 4. 의미 없는 성능 로그
- `0.000s` 같은 극히 작은 값들이 반복 출력
- Effect handling이 4번 연속 출력됨

```
20:23:03.615 🔍 DEBUG Performance - Effect handling: 0.000s
  duration: 3.790855407714844e-05
20:23:03.615 🔍 DEBUG Performance - Effect handling: 0.000s
  duration: 2.908706665039062e-05
20:23:03.615 🔍 DEBUG Performance - Effect handling: 0.000s
  duration: 3.099441528320312e-06
20:23:03.615 🔍 DEBUG Performance - Effect handling: 0.000s
  duration: 0
```

### 5. Effect 로그 분산
- 하나의 액션에서 생성된 3-4개의 Effect가 각각 별도 로그로 출력
- 전체 흐름을 파악하기 어려움

---

## 개선 방향

### A. 로그 레벨별 차별화 강화

```swift
// VERBOSE: 극도로 상세 (내부 디버깅용)
// - 개별 Effect 상세 정보
// - 모든 성능 메트릭
// - 전체 State 출력

// DEBUG: 개발 디버깅 (기본값)
// - Effect 그룹 요약
// - 유의미한 성능 메트릭 (임계값 이상)
// - State diff만 표시

// INFO: 비즈니스 로직 추적
// - Action → State 변경 요약
// - Effect 개수만 표시

// WARNING/ERROR: 문제 발생 시에만
```

### B. State Diff 계산

전체 State 대신 변경된 부분만 표시:

```swift
// 현재
State changed from:
State(display: 2, activeAlert: nil, calculatorState: ..., isAutoClearTimerActive: false)
to:
State(display: 23, activeAlert: nil, calculatorState: ..., isAutoClearTimerActive: false)

// 개선 (INFO 레벨)
ℹ️ [Calculator] inputNumber(3) → display: "2" → "23"

// 개선 (DEBUG 레벨)
🔍 [Calculator] State changed: display: "2" → "23"
  - calculatorState.display: "2" → "23"
  - calculatorState.currentValue: 2.0 → 23.0
```

### C. Effect 그룹화

```swift
// 현재
🔍 DEBUG Effect: cancel(id: autoClearTimer)
🔍 DEBUG Effect: action(setTimerActive(false))
🔍 DEBUG Effect: run(id: nil, operation: ...)

// 개선 (INFO 레벨)
ℹ️ [Calculator] inputNumber(2) → 3 effects

// 개선 (DEBUG 레벨)
🔍 [Calculator] Effects[3]: cancel(autoClearTimer), action(setTimerActive), run(async)

// 개선 (VERBOSE 레벨)
📝 [Calculator] Effect 1/3: cancel(id: autoClearTimer)
📝 [Calculator] Effect 2/3: action(setTimerActive(false))
📝 [Calculator] Effect 3/3: run(operation: ...)
```

### D. 성능 로그 필터링

```swift
// 임계값 설정 (기본값: 10ms)
public struct LoggingOptions {
    var performanceThreshold: TimeInterval = 0.010 // 10ms
    var showZeroPerformance: Bool = false
}

// 현재
🔍 DEBUG Performance - Effect handling: 0.000s
🔍 DEBUG Performance - Effect handling: 0.000s
🔍 DEBUG Performance - Effect handling: 0.000s

// 개선 (임계값 이하 생략)
🔍 DEBUG Performance - Action processing: 0.018s
// 0.001s 이하는 출력 안 함
```

### E. 간결한 포맷 옵션

```swift
public enum LogFormat {
    case compact    // 한 줄로 요약
    case standard   // 현재 방식
    case detailed   // 상세 (metadata 포함)
}

// compact 예시
ℹ️ 20:23:03.600 [Calculator] inputNumber(2) → display: "2" → 3 effects

// standard 예시 (현재보다 개선)
ℹ️ 20:23:03.600 [Calculator] Action: inputNumber(2)
🔍 20:23:03.606 [Calculator] Effects[3]: cancel, action, run
🔍 20:23:03.619 [Calculator] State: display: "2" → "23"
🔍 20:23:03.612 [Calculator] Performance: 0.018s

// detailed 예시 (현재 방식 유지, VERBOSE 레벨에서만)
📝 20:23:03.600 [Calculator] Action: inputNumber(2)
  action: inputNumber(2)
  type: action
  file: AsyncViewModelProtocol.swift:88
...
```

---

## 구현 계획

### 1단계: ViewModelLogger 프로토콜 확장

```swift
// ViewModelLogger.swift

/// 로깅 포맷 옵션
public struct LoggingOptions: Sendable {
    /// 로그 포맷
    public var format: LogFormat = .standard
    
    /// 성능 로그 임계값 (초 단위, 이 값 이하는 로그 안 함)
    public var performanceThreshold: TimeInterval = 0.001
    
    /// State 변경 시 diff만 표시
    public var showStateDiffOnly: Bool = true
    
    /// Effect 그룹화 (true: 요약, false: 개별)
    public var groupEffects: Bool = true
    
    /// 0초 성능 메트릭 표시 여부
    public var showZeroPerformance: Bool = false
    
    public init() {}
}

public enum LogFormat: Sendable {
    /// 한 줄로 요약
    case compact
    /// 기본 (개선된 형태)
    case standard
    /// 상세 (metadata 포함)
    case detailed
}

/// ViewModelLogger 프로토콜에 옵션 추가
@MainActor
public protocol ViewModelLogger: Sendable {
    /// 로깅 옵션
    var options: LoggingOptions { get set }
    
    // 기존 메서드들...
    
    /// Effect 배열을 그룹으로 로깅
    func logEffects(
        _ effects: [String],
        viewModel: String,
        file: String,
        function: String,
        line: Int
    )
    
    /// State diff 로깅
    func logStateDiff(
        changes: [String: (old: String, new: String)],
        viewModel: String,
        file: String,
        function: String,
        line: Int
    )
}
```

### 2단계: State Diff 계산 유틸리티

```swift
// AsyncViewModelProtocol.swift

/// State diff를 계산하는 헬퍼 메서드
private func calculateStateDiff(
    from oldState: State,
    to newState: State
) -> [String: (old: String, new: String)] {
    var changes: [String: (old: String, new: String)] = [:]
    
    let oldMirror = Mirror(reflecting: oldState)
    let newMirror = Mirror(reflecting: newState)
    
    for (oldChild, newChild) in zip(oldMirror.children, newMirror.children) {
        guard let label = oldChild.label else { continue }
        
        let oldValue = String(describing: oldChild.value)
        let newValue = String(describing: newChild.value)
        
        if oldValue != newValue {
            changes[label] = (old: oldValue, new: newValue)
        }
    }
    
    return changes
}
```

### 3단계: TraceKitViewModelLogger 개선

```swift
// TraceKitViewModelLogger.swift

@MainActor
public struct TraceKitViewModelLogger: ViewModelLogger {
    public var options: LoggingOptions = LoggingOptions()
    
    public func logEffects(
        _ effects: [String],
        viewModel: String,
        file: String,
        function: String,
        line: Int
    ) {
        switch options.format {
        case .compact:
            let summary = "\(effects.count) effects"
            TraceKit.log(
                level: .debug,
                summary,
                category: viewModel,
                file: file,
                function: function,
                line: line
            )
            
        case .standard:
            if options.groupEffects {
                let summary = effects.map { effect in
                    // "cancel(id: ...)" -> "cancel"
                    effect.split(separator: "(").first.map(String.init) ?? effect
                }.joined(separator: ", ")
                
                let message = "Effects[\(effects.count)]: \(summary)"
                TraceKit.log(
                    level: .debug,
                    message,
                    category: viewModel,
                    metadata: ["effect_count": .init(effects.count)],
                    file: file,
                    function: function,
                    line: line
                )
            } else {
                // 개별 로깅 (기존 방식)
                for (index, effect) in effects.enumerated() {
                    logEffect(
                        effect,
                        viewModel: viewModel,
                        file: file,
                        function: function,
                        line: line
                    )
                }
            }
            
        case .detailed:
            // 각각 상세하게
            for (index, effect) in effects.enumerated() {
                let message = "Effect \(index + 1)/\(effects.count): \(effect)"
                TraceKit.log(
                    level: .verbose,
                    message,
                    category: viewModel,
                    metadata: [
                        "type": .init("effect"),
                        "effect": .init(effect),
                        "index": .init(index),
                        "total": .init(effects.count)
                    ],
                    file: file,
                    function: function,
                    line: line
                )
            }
        }
    }
    
    public func logStateDiff(
        changes: [String: (old: String, new: String)],
        viewModel: String,
        file: String,
        function: String,
        line: Int
    ) {
        switch options.format {
        case .compact:
            let summary = changes.keys.joined(separator: ", ")
            TraceKit.log(
                level: .info,
                "State: \(summary)",
                category: viewModel,
                file: file,
                function: function,
                line: line
            )
            
        case .standard:
            let changeDescriptions = changes.map { key, values in
                "\(key): \(values.old) → \(values.new)"
            }.joined(separator: "\n  - ")
            
            let message = "State changed:\n  - \(changeDescriptions)"
            
            var metadata: [String: TraceKit.MetadataValue] = ["type": .init("state_change")]
            for (key, values) in changes {
                metadata["old_\(key)"] = .init(values.old)
                metadata["new_\(key)"] = .init(values.new)
            }
            
            TraceKit.log(
                level: .info,
                message,
                category: viewModel,
                metadata: metadata,
                file: file,
                function: function,
                line: line
            )
            
        case .detailed:
            // 전체 State 출력 (기존 방식)
            // logStateChange 호출
            break
        }
    }
    
    public func logPerformance(
        operation: String,
        duration: TimeInterval,
        viewModel: String,
        level: LogLevel,
        file: String,
        function: String,
        line: Int
    ) {
        // 임계값 체크
        if !options.showZeroPerformance && duration < options.performanceThreshold {
            return
        }
        
        let message = "Performance - \(operation): \(String(format: "%.3f", duration))s"
        TraceKit.log(
            level: level.traceLevel,
            message,
            category: viewModel,
            metadata: [
                "type": .init("performance"),
                "operation": .init(operation),
                "duration": .init(duration)
            ],
            file: file,
            function: function,
            line: line
        )
    }
}
```

### 4단계: AsyncViewModelProtocol 업데이트

```swift
// AsyncViewModelProtocol.swift

extension AsyncViewModelProtocol {
    public func perform(_ action: Action) {
        let startTime = CFAbsoluteTimeGetCurrent()
        
        logAction(action)
        actionObserver?(action)
        
        let oldState = state
        let effects = reduce(state: &state, action: action)
        
        // State 변경 로깅 개선
        if oldState != state {
            let logger = LoggerConfiguration.logger
            if logger.options.showStateDiffOnly {
                let diff = calculateStateDiff(from: oldState, to: state)
                if !diff.isEmpty {
                    logStateDiff(diff)
                }
            } else {
                // 전체 State 로깅 (기존 방식)
                logStateChange(from: oldState, to: state)
            }
        }
        
        effectQueue.append(contentsOf: effects)
        
        // Effect 로깅 개선
        let logger = ViewModelLoggerConfiguration.shared.logger
        if logger.options.groupEffects && !effects.isEmpty {
            logEffects(effects)
        } else {
            // 개별 로깅 (기존 방식)
            for effect in effects {
                logEffect(effect)
            }
        }
        
        let duration = CFAbsoluteTimeGetCurrent() - startTime
        logPerformance("Action processing", duration: duration, level: .debug)
        
        Task {
            await processNextEffect()
        }
    }
    
    /// Effect 배열을 그룹으로 로깅
    private func logEffects(_ effects: [AsyncEffect<Action, CancelID>]) {
        let effectDescriptions = effects.map { String(describing: $0) }
        let viewModelName = String(describing: Self.self)
        
        LoggerConfiguration.logger.logEffects(
            effectDescriptions,
            viewModel: viewModelName,
            file: #file,
            function: #function,
            line: #line
        )
    }
    
    /// State diff 로깅
    private func logStateDiff(_ changes: [String: (old: String, new: String)]) {
        let viewModelName = String(describing: Self.self)
        
        LoggerConfiguration.logger.logStateDiff(
            changes: changes,
            viewModel: viewModelName,
            file: #file,
            function: #function,
            line: #line
        )
    }
}
```

### 5단계: 설정 API

```swift
// 사용자가 앱 시작 시 설정
Task { @MainActor in
    let logger = TraceKitViewModelLogger()
    
    // 옵션 커스터마이징
    var options = LoggingOptions()
    options.format = .standard          // compact, standard, detailed
    options.performanceThreshold = 0.005 // 5ms 이하는 표시 안 함
    options.showStateDiffOnly = true    // diff만 표시
    options.groupEffects = true         // Effect 그룹화
    options.showZeroPerformance = false // 0초 성능 메트릭 숨김
    
    logger.options = options
    LoggerConfiguration.setLogger(logger)
}
```

---

## 개선 효과 비교

### 현재 (단일 액션당 60줄 이상)

```
20:23:03.600 ℹ️ INFO [CalculatorSwiftUIViewModel] Action: inputNumber(2)
  action: inputNumber(2)
  type: action
20:23:03.606 🔍 DEBUG [CalculatorSwiftUIViewModel] Effect: cancel(id: ...)
  effect: cancel(id: ...)
  type: effect
20:23:03.607 🔍 DEBUG [CalculatorSwiftUIViewModel] Effect: action(...)
  effect: action(...)
  type: effect
20:23:03.612 🔍 DEBUG [CalculatorSwiftUIViewModel] Effect: run(...)
  effect: run(...)
  type: effect
20:23:03.612 🔍 DEBUG [CalculatorSwiftUIViewModel] Performance - Action processing: 0.018s
  duration: 0.01792597770690918
  operation: Action processing
  type: performance
20:23:03.615 🔍 DEBUG Performance - Effect handling: 0.000s
... (생략)
20:23:03.619 ℹ️ INFO State changed from:
State(
  display: 0,
  activeAlert: nil,
  calculatorState: CalculatorState(
    display: 0,
    currentValue: 0.0,
    previousValue: 0.0,
    currentOperation: nil,
    shouldResetDisplay: false
  ),
  isAutoClearTimerActive: false
)

to:
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
  new_state: ...
  old_state: ...
  type: state_change
```

### 개선 후 - Compact 모드 (단일 액션당 1줄)

```
20:23:03.600 ℹ️ [Calculator] inputNumber(2) → display: "0" → "2" [3 effects] (0.018s)
20:23:04.251 ℹ️ [Calculator] inputNumber(3) → display: "2" → "23" [3 effects]
20:23:05.093 ℹ️ [Calculator] setOperation(add) → currentOperation: nil → add [3 effects]
20:23:05.367 ℹ️ [Calculator] inputNumber(2) → display: "23" → "2" [3 effects]
20:23:06.302 ℹ️ [Calculator] calculate → display: "23" → "46" [3 effects]
```

### 개선 후 - Standard 모드 (단일 액션당 4-5줄)

```
20:23:03.600 ℹ️ [Calculator] Action: inputNumber(2)
20:23:03.606 🔍 [Calculator] Effects[3]: cancel, action, run
20:23:03.619 ℹ️ [Calculator] State changed:
  - display: "0" → "2"
  - calculatorState.currentValue: 0.0 → 2.0
20:23:03.612 🔍 [Calculator] Performance: 0.018s
```

### 개선 후 - Detailed 모드 (VERBOSE 레벨, 필요 시에만)

```
20:23:03.600 📝 [Calculator] Action: inputNumber(2)
  action: inputNumber(2)
  type: action
20:23:03.606 📝 [Calculator] Effect 1/3: cancel(id: autoClearTimer)
  type: effect
  effect: cancel(id: autoClearTimer)
20:23:03.607 📝 [Calculator] Effect 2/3: action(setTimerActive(false))
  type: effect
  effect: action(setTimerActive(false))
... (전체 상세 로그)
```

---

## 마이그레이션 가이드

### 기존 코드 (변경 필요 없음)

```swift
@Observable
final class MyViewModel: AsyncViewModelProtocol {
    var isLoggingEnabled = true
    var logLevel: LogLevel = .debug
    
    // 기존 코드 그대로 동작
}
```

### 로깅 커스터마이징

```swift
// AppDelegate 또는 앱 진입점
Task { @MainActor in
    let logger = TraceKitViewModelLogger()
    
    // 간결한 로그 원하는 경우
    logger.options.format = .compact
    logger.options.performanceThreshold = 0.010 // 10ms
    
    LoggerConfiguration.setLogger(logger)
}
```

### 레벨별 권장 설정

```swift
// Production: 최소한의 로그
logger.options.format = .compact
logger.options.performanceThreshold = 0.050 // 50ms 이상만
viewModel.logLevel = .warning

// Development: 균형 잡힌 로그
logger.options.format = .standard
logger.options.performanceThreshold = 0.010 // 10ms 이상
viewModel.logLevel = .info

// Debugging: 상세한 로그
logger.options.format = .detailed
logger.options.performanceThreshold = 0.001 // 1ms 이상
logger.options.showZeroPerformance = true
viewModel.logLevel = .verbose
```

---

## 구현 우선순위

1. 높음 (즉시)
   - [x] 분석 문서 작성
   - [ ] LoggingOptions 구조체 추가
   - [ ] State Diff 계산 로직
   - [ ] 성능 로그 임계값 필터링

2. 중간 (1-2일 내)
   - [ ] Effect 그룹화 로직
   - [ ] TraceKitViewModelLogger 개선
   - [ ] Compact 포맷 구현

3. 낮음 (선택적)
   - [ ] Standard 포맷 세부 조정
   - [ ] Detailed 포맷 (VERBOSE용)
   - [ ] 문서화 및 예제 업데이트

---

## 예상 효과

1. 가독성 향상
   - Compact: 60줄 → 1줄 (98% 감소)
   - Standard: 60줄 → 4-5줄 (90% 감소)

2. 성능 개선
   - 불필요한 문자열 포맷팅 감소
   - 메타데이터 중복 제거
   - 로그 출력 I/O 감소

3. 개발 경험 개선
   - 핵심 정보에 집중 가능
   - 디버깅 시 흐름 파악 용이
   - 필요 시 상세 로그로 전환 가능

4. 하위 호환성 유지
   - 기존 코드 변경 불필요
   - 옵트인 방식으로 적용
   - 기본 동작은 현재와 유사 (standard 모드)
