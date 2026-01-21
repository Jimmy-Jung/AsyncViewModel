# AsyncViewModel 로깅 시스템 완전 가이드

## 목차
- [개요](#개요)
- [로깅 시스템 아키텍처](#로깅-시스템-아키텍처)
- [LoggerMode 설정](#loggermode-설정)
- [LoggingCategory 제어](#loggingcategory-제어)
- [LoggingOptions 커스터마이징](#loggingoptions-커스터마이징)
- [내장 로거](#내장-로거)
- [커스텀 로거 구현](#커스텀-로거-구현)
- [로그 포맷팅](#로그-포맷팅)
- [성능 로깅](#성능-로깅)
- [실전 예제](#실전-예제)
- [베스트 프랙티스](#베스트-프랙티스)

---

## 개요

AsyncViewModel은 강력하고 유연한 로깅 시스템을 제공하여 ViewModel의 상태 변화, 액션, Effect 실행을 추적할 수 있습니다.

### 주요 특징

- 🎯 **유연한 로거 모드**: 전역, 개별, 비활성화 모드 지원
- 📊 **카테고리별 제어**: Action, State, Effect, Performance 독립 제어
- 🎨 **다양한 포맷**: Compact, Standard, Detailed 포맷 지원
- ⚡ **성능 추적**: 자동 성능 측정 및 임계값 알림
- 🔌 **확장 가능**: 커스텀 로거 구현 가능
- 🎭 **타입 안전**: ValueSnapshot으로 타입 안전한 로깅

---

## 로깅 시스템 아키텍처

### 계층 구조

```
AsyncViewModelConfiguration (전역)
    ↓
LoggerMode (로거 선택)
    ├── .shared (전역 로거)
    ├── .custom(logger) (ViewModel별 로거)
    └── .disabled (로깅 비활성화)
    ↓
ViewModelLogger (로거 구현체)
    ├── OSLogViewModelLogger
    ├── ConsoleViewModelLogger
    └── CustomLogger
    ↓
LoggingOptions (로깅 설정)
    ├── categories (로깅 카테고리)
    ├── format (출력 포맷)
    ├── performanceThreshold (성능 임계값)
    └── 기타 옵션
    ↓
LogEvent (로그 이벤트)
    ├── action
    ├── stateChange
    ├── effect/effects
    └── performance
```

### 핵심 컴포넌트

#### 1. AsyncViewModelConfiguration

전역 로깅 설정을 관리하는 싱글톤

```swift
// 전역 로거 설정
AsyncViewModelConfiguration.shared.setLogger(.shared)

// 전역 옵션 설정
AsyncViewModelConfiguration.shared.globalOptions = LoggingOptions(
    categories: [.action, .stateChange],
    format: .standard
)
```

#### 2. LoggerMode

로거 선택 모드

```swift
public enum LoggerMode: Sendable {
    case shared                              // 전역 로거 사용
    case custom(any ViewModelLogger)        // ViewModel 전용 로거
    case disabled                           // 로깅 비활성화
}
```

#### 3. LoggingCategory

로깅 카테고리

```swift
public struct LoggingCategory: OptionSet, Sendable {
    public static let action = LoggingCategory(rawValue: 1 << 0)
    public static let stateChange = LoggingCategory(rawValue: 1 << 1)
    public static let effect = LoggingCategory(rawValue: 1 << 2)
    public static let performance = LoggingCategory(rawValue: 1 << 3)
    
    public static let all: LoggingCategory = [.action, .stateChange, .effect, .performance]
}
```

---

## LoggerMode 설정

### 1. 전역 로거 모드 (.shared)

모든 ViewModel이 하나의 공유 로거를 사용합니다.

```swift
// AppDelegate 또는 App 초기화
@main
struct MyApp: App {
    init() {
        setupLogging()
    }
    
    func setupLogging() {
        #if DEBUG
        Task { @MainActor in
            // 전역 로거 설정
            var logger = OSLogViewModelLogger(subsystem: "com.myapp")
            logger.options = LoggingOptions(
                categories: .all,
                format: .detailed
            )
            AsyncViewModelConfiguration.shared.setLogger(logger)
            
            // 모든 ViewModel에서 .shared 사용
            AsyncViewModelConfiguration.shared.defaultLoggerMode = .shared
        }
        #endif
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}

// ViewModel에서 사용
@AsyncViewModel(loggerMode: .shared)
final class MyViewModel: ObservableObject {
    // ... 전역 로거 사용
}
```

### 2. 커스텀 로거 모드 (.custom)

각 ViewModel이 독립적인 로거를 사용합니다.

```swift
// ViewModel별 로거 설정
@AsyncViewModel(loggerMode: .custom(MyCustomLogger()))
final class ProfileViewModel: ObservableObject {
    // ... 전용 로거 사용
}

@AsyncViewModel(loggerMode: .custom(OSLogViewModelLogger(subsystem: "com.myapp.auth")))
final class AuthViewModel: ObservableObject {
    // ... Auth 전용 로거 사용
}
```

### 3. 비활성화 모드 (.disabled)

특정 ViewModel의 로깅을 완전히 비활성화합니다.

```swift
@AsyncViewModel(loggerMode: .disabled)
final class BackgroundViewModel: ObservableObject {
    // ... 로깅 없음 (성능 최적화)
}
```

---

## LoggingCategory 제어

### 전역 카테고리 설정

```swift
// 전역 옵션으로 카테고리 설정
AsyncViewModelConfiguration.shared.globalOptions = LoggingOptions(
    categories: [.action, .stateChange]  // Effect, Performance는 로깅 안함
)
```

### ViewModel별 카테고리 설정

```swift
@AsyncViewModel(
    loggerMode: .custom(OSLogViewModelLogger()),
    loggingOptions: LoggingOptions(
        categories: [.action, .effect]  // Action과 Effect만 로깅
    )
)
final class NetworkViewModel: ObservableObject {
    // ...
}
```

### 런타임 카테고리 변경

```swift
// 특정 ViewModel의 로깅 카테고리 변경
viewModel.loggingConfig.options = LoggingOptions(
    categories: [.stateChange]
)

// 일시적으로 로깅 비활성화
viewModel.loggingConfig.isEnabled = false

// 다시 활성화
viewModel.loggingConfig.isEnabled = true
```

### 카테고리별 사용 사례

```swift
// 개발 중: 모든 로그
LoggingOptions(categories: .all)

// 상태 디버깅: State 변경만
LoggingOptions(categories: [.stateChange])

// 비동기 작업 추적: Effect만
LoggingOptions(categories: [.effect])

// 성능 모니터링: Performance만
LoggingOptions(categories: [.performance])

// Action 플로우 추적: Action만
LoggingOptions(categories: [.action])

// 운영 환경: 성능 이슈만
LoggingOptions(categories: [.performance])
```

---

## LoggingOptions 커스터마이징

### 전체 옵션 구조

```swift
public struct LoggingOptions: Sendable {
    public var categories: LoggingCategory = .all
    public var format: LogFormat = .standard
    public var performanceThreshold: PerformanceThreshold? = nil
    public var stateDiffOnly: Bool = false
    public var groupEffects: Bool = false
    public var zeroPerformance: Bool = false
}
```

### 1. 로그 포맷 (format)

```swift
public enum LogFormat: Sendable {
    case compact    // 한 줄 요약
    case standard   // 기본 포맷
    case detailed   // 상세 정보 포함
}
```

**사용 예시:**

```swift
// Compact: 프로덕션 환경
LoggingOptions(format: .compact)
// 출력: [ProfileViewModel] Action: .loadProfile

// Standard: 개발 환경
LoggingOptions(format: .standard)
// 출력:
// [ProfileViewModel] Action: .loadProfile
// State: isLoading: true

// Detailed: 디버깅
LoggingOptions(format: .detailed)
// 출력:
// ━━━ [ProfileViewModel] ━━━
// 📥 Action: .loadProfile
// 🔄 State Change:
//   Old: State(isLoading: false, profile: nil)
//   New: State(isLoading: true, profile: nil)
// ⚡ Effects: [.run(id: .loadProfile)]
```

### 2. State Diff Only (stateDiffOnly)

전체 State 대신 변경된 필드만 표시합니다.

```swift
// 전체 State 표시
LoggingOptions(stateDiffOnly: false)
// 출력:
// Old: State(count: 0, isLoading: false, items: [])
// New: State(count: 1, isLoading: false, items: [])

// 변경된 필드만 표시
LoggingOptions(stateDiffOnly: true)
// 출력:
// count: 0 → 1
```

### 3. Effect 그룹화 (groupEffects)

여러 Effect를 그룹화하여 표시합니다.

```swift
// 개별 표시
LoggingOptions(groupEffects: false)
// 출력:
// Effect 1: .run(id: .taskA)
// Effect 2: .run(id: .taskB)
// Effect 3: .cancel(id: .taskC)

// 그룹화 표시
LoggingOptions(groupEffects: true)
// 출력:
// Effects (3):
//   - .run(id: .taskA)
//   - .run(id: .taskB)
//   - .cancel(id: .taskC)
```

### 4. 성능 임계값 (performanceThreshold)

특정 임계값을 초과하는 작업만 로깅합니다.

```swift
// 0.1초 이상 걸리는 작업만 로깅
LoggingOptions(
    performanceThreshold: PerformanceThreshold(
        type: .actionProcessing,
        customThreshold: 0.1
    )
)

// 모든 성능 로그 표시 (0초 포함)
LoggingOptions(zeroPerformance: true)

// 0초 제외
LoggingOptions(zeroPerformance: false)
```

### 실전 시나리오별 설정

#### 개발 환경 (Development)

```swift
LoggingOptions(
    categories: .all,
    format: .detailed,
    stateDiffOnly: false,
    groupEffects: false,
    zeroPerformance: true
)
```

#### 스테이징 환경 (Staging)

```swift
LoggingOptions(
    categories: [.action, .stateChange, .performance],
    format: .standard,
    stateDiffOnly: true,
    groupEffects: true,
    zeroPerformance: false,
    performanceThreshold: PerformanceThreshold(
        type: .actionProcessing,
        customThreshold: 0.05
    )
)
```

#### 프로덕션 환경 (Production)

```swift
LoggingOptions(
    categories: [.performance],
    format: .compact,
    stateDiffOnly: true,
    groupEffects: true,
    zeroPerformance: false,
    performanceThreshold: PerformanceThreshold(
        type: .actionProcessing,
        customThreshold: 0.1
    )
)
```

---

## 내장 로거

### 1. OSLogViewModelLogger

Apple의 통합 로깅 시스템을 사용합니다.

```swift
var logger = OSLogViewModelLogger(
    subsystem: "com.myapp",
    category: "ViewModel"
)
logger.options = LoggingOptions(
    categories: .all,
    format: .standard
)

AsyncViewModelConfiguration.shared.setLogger(logger)
```

**특징:**
- ✅ Console.app에서 확인 가능
- ✅ 로그 레벨 지원 (debug, info, error)
- ✅ 시스템 로그와 통합
- ✅ 필터링 및 검색 용이

**Console.app에서 확인:**

```bash
# 특정 subsystem 필터링
log stream --predicate 'subsystem == "com.myapp"'

# 특정 category 필터링
log stream --predicate 'category == "ViewModel"'
```

### 2. ConsoleViewModelLogger

표준 출력(print)을 사용하는 간단한 로거입니다.

```swift
var logger = ConsoleViewModelLogger()
logger.options = LoggingOptions(
    format: .standard
)

AsyncViewModelConfiguration.shared.setLogger(logger)
```

**특징:**
- ✅ 간단한 설정
- ✅ Xcode 콘솔에서 즉시 확인
- ✅ 빠른 프로토타이핑
- ⚠️ 프로덕션에는 부적합

---

## 커스텀 로거 구현

### ViewModelLogger 프로토콜

```swift
public protocol ViewModelLogger: Sendable {
    var options: LoggingOptions { get set }
    
    func logAction(
        _ action: String,
        viewModel: String,
        level: LogLevel,
        file: String,
        function: String,
        line: Int
    )
    
    func logStateChange(
        old: String,
        new: String,
        viewModel: String,
        level: LogLevel,
        file: String,
        function: String,
        line: Int
    )
    
    func logEffect(
        _ effect: String,
        viewModel: String,
        level: LogLevel,
        file: String,
        function: String,
        line: Int
    )
    
    func logEffects(
        _ effects: [String],
        viewModel: String,
        level: LogLevel,
        file: String,
        function: String,
        line: Int
    )
    
    func logPerformance(
        operation: String,
        duration: TimeInterval,
        viewModel: String,
        level: LogLevel,
        file: String,
        function: String,
        line: Int
    )
}
```

### 예제 1: 파일 로거

```swift
actor FileViewModelLogger: ViewModelLogger {
    var options: LoggingOptions = .init()
    private let fileURL: URL
    private var fileHandle: FileHandle?
    
    init(logFilePath: String) {
        self.fileURL = URL(fileURLWithPath: logFilePath)
        setupFile()
    }
    
    private func setupFile() {
        if !FileManager.default.fileExists(atPath: fileURL.path) {
            FileManager.default.createFile(
                atPath: fileURL.path,
                contents: nil
            )
        }
        fileHandle = try? FileHandle(forWritingTo: fileURL)
        fileHandle?.seekToEndOfFile()
    }
    
    func logAction(
        _ action: String,
        viewModel: String,
        level: LogLevel,
        file: String,
        function: String,
        line: Int
    ) {
        let timestamp = ISO8601DateFormatter().string(from: Date())
        let message = "[\(timestamp)] [\(viewModel)] Action: \(action)\n"
        
        if let data = message.data(using: .utf8) {
            fileHandle?.write(data)
        }
    }
    
    // ... 나머지 메서드 구현
    
    deinit {
        try? fileHandle?.close()
    }
}

// 사용
let logger = FileViewModelLogger(logFilePath: "/tmp/viewmodel.log")
AsyncViewModelConfiguration.shared.setLogger(logger)
```

### 예제 2: 분석 로거

앱 분석 플랫폼으로 이벤트를 전송하는 로거입니다.

```swift
struct AnalyticsViewModelLogger: ViewModelLogger {
    var options: LoggingOptions = .init()
    
    func logAction(
        _ action: String,
        viewModel: String,
        level: LogLevel,
        file: String,
        function: String,
        line: Int
    ) {
        // Firebase, Mixpanel 등으로 이벤트 전송
        Analytics.logEvent("\(viewModel)_\(action)", parameters: [
            "level": level.rawValue,
            "function": function
        ])
    }
    
    func logPerformance(
        operation: String,
        duration: TimeInterval,
        viewModel: String,
        level: LogLevel,
        file: String,
        function: String,
        line: Int
    ) {
        // 성능 이벤트 전송
        if duration > 0.1 {
            Analytics.logEvent("slow_operation", parameters: [
                "viewModel": viewModel,
                "operation": operation,
                "duration": duration
            ])
        }
    }
    
    // ... 나머지 메서드 구현
}
```

### 예제 3: 멀티 로거

여러 로거를 동시에 사용합니다.

```swift
struct MultiViewModelLogger: ViewModelLogger {
    var options: LoggingOptions = .init()
    private let loggers: [any ViewModelLogger]
    
    init(loggers: [any ViewModelLogger]) {
        self.loggers = loggers
    }
    
    func logAction(
        _ action: String,
        viewModel: String,
        level: LogLevel,
        file: String,
        function: String,
        line: Int
    ) {
        for var logger in loggers {
            logger.options = options
            logger.logAction(
                action,
                viewModel: viewModel,
                level: level,
                file: file,
                function: function,
                line: line
            )
        }
    }
    
    // ... 나머지 메서드 구현
}

// 사용: OSLog + File + Analytics
let multiLogger = MultiViewModelLogger(loggers: [
    OSLogViewModelLogger(),
    FileViewModelLogger(logFilePath: "/tmp/app.log"),
    AnalyticsViewModelLogger()
])
AsyncViewModelConfiguration.shared.setLogger(multiLogger)
```

---

## 로그 포맷팅

### FormatterConfiguration

로그 포맷터의 동작을 커스터마이징할 수 있는 설정입니다.

```swift
public struct FormatterConfiguration: Sendable {
    public var maxProperties: Int = 3
    public var maxValueLength: Int = 50
    public var standardMaxLines: Int = 10
    public var standardMaxDepth: Int = 3
    public var performanceDecimalPlaces: Int = 3
    public var stateChangeArrow: String = "→"
    public var indentString: String = "  "
    public var unwrapOptional: Bool = true
    
    // Git diff 스타일 아이콘 (v1.3.0+)
    public var changedPropertyIcon: String = "🟡"  // 변경점
    public var oldValueIcon: String = "🔴"          // 이전 값
    public var newValueIcon: String = "🟢"          // 새로운 값
}
```

**커스터마이징 예시:**

```swift
// 커스텀 포맷터 설정
let config = FormatterConfiguration(
    maxValueLength: 100,
    stateChangeArrow: "->",
    indentString: "    ",
    changedPropertyIcon: "•",
    oldValueIcon: "-",
    newValueIcon: "+"
)

let formatter = DefaultLogFormatter(configuration: config)

// 커스텀 포맷터로 로거 생성
var logger = OSLogViewModelLogger(subsystem: "com.myapp")
logger.formatter = formatter
AsyncViewModelConfiguration.shared.setLogger(logger)
```

**아이콘 커스터마이징 (v1.3.0+):**

```swift
// Git diff 스타일 (기본값)
FormatterConfiguration(
    changedPropertyIcon: "🟡",  // 노란색: 변경점
    oldValueIcon: "🔴",          // 빨간색: 제거/이전
    newValueIcon: "🟢"           // 초록색: 추가/새로운
)

// 텍스트 스타일
FormatterConfiguration(
    changedPropertyIcon: "◦",
    oldValueIcon: "−",
    newValueIcon: "+"
)

// 화살표 스타일
FormatterConfiguration(
    changedPropertyIcon: "▸",
    oldValueIcon: "◁",
    newValueIcon: "▷"
)
```

**출력 예시:**

```
State changed (2 properties):
  🟡 username:
    🔴 OLD: "john"
    🟢 NEW: "jimmy"
  🟡 age:
    🔴 OLD: 20
    🟢 NEW: 25
```

### ValueSnapshot

타입 안전한 값 스냅샷을 위한 모델입니다.

```swift
public enum ValueSnapshot: Sendable {
    case string(String)
    case int(Int)
    case double(Double)
    case bool(Bool)
    case array([ValueSnapshot])
    case dictionary([String: ValueSnapshot])
    case `enum`(String, associated: [ValueSnapshot]?)
    case object(type: String, properties: [String: ValueSnapshot])
    case optional(ValueSnapshot?)
    case date(Date)
    case url(URL)
    case color(red: Double, green: Double, blue: Double, alpha: Double)
    case custom(String)
}
```

### PrettyPrinter

ValueSnapshot을 보기 좋게 포맷팅합니다.

```swift
public struct PrettyPrinter {
    public static func format(_ value: Any, depth: Int = 0) -> String
    public static func formatDiff(old: Any, new: Any) -> String
}
```

**사용 예시:**

```swift
struct User {
    var name: String
    var age: Int
    var isPremium: Bool
}

let oldUser = User(name: "John", age: 30, isPremium: false)
let newUser = User(name: "John", age: 31, isPremium: true)

// 전체 포맷
print(PrettyPrinter.format(newUser))
// 출력:
// User(
//   name: "John",
//   age: 31,
//   isPremium: true
// )

// Diff 포맷
print(PrettyPrinter.formatDiff(old: oldUser, new: newUser))
// 출력:
// age: 30 → 31
// isPremium: false → true
```

---

## 성능 로깅

### PerformanceThreshold

성능 측정 임계값을 설정합니다.

```swift
public struct PerformanceThreshold: Sendable {
    public enum OperationType {
        case actionProcessing   // Action 처리 시간
        case effectExecution   // Effect 실행 시간
        case stateUpdate       // State 업데이트 시간
    }
    
    public let type: OperationType
    public let customThreshold: TimeInterval?
    
    public static let smart = PerformanceThreshold(
        type: .actionProcessing,
        customThreshold: nil  // 자동 추론
    )
}
```

### 자동 성능 측정

AsyncViewModel은 자동으로 주요 작업의 성능을 측정합니다:

```swift
// Action 처리 시간
logPerformance("Action processing", duration: 0.15)

// Effect 실행 시간
logPerformance("Effect operation", duration: 0.25)

// Effect 핸들링 시간
logPerformance("Effect handling", duration: 0.05)
```

### 성능 로깅 설정

```swift
// 모든 성능 로그 표시
LoggingOptions(
    categories: [.performance],
    zeroPerformance: true
)

// 0.1초 이상만 표시
LoggingOptions(
    categories: [.performance],
    zeroPerformance: false,
    performanceThreshold: PerformanceThreshold(
        type: .actionProcessing,
        customThreshold: 0.1
    )
)

// 스마트 임계값 (자동 조정)
LoggingOptions(
    categories: [.performance],
    performanceThreshold: .smart
)
```

---

## 실전 예제

### 예제 1: 환경별 로깅 설정

```swift
@main
struct MyApp: App {
    init() {
        setupLogging()
    }
    
    func setupLogging() {
        Task { @MainActor in
            #if DEBUG
            setupDevelopmentLogging()
            #elseif STAGING
            setupStagingLogging()
            #else
            setupProductionLogging()
            #endif
        }
    }
    
    func setupDevelopmentLogging() {
        var logger = OSLogViewModelLogger(subsystem: "com.myapp")
        logger.options = LoggingOptions(
            categories: .all,
            format: .detailed,
            stateDiffOnly: false,
            groupEffects: false,
            zeroPerformance: true
        )
        AsyncViewModelConfiguration.shared.setLogger(logger)
    }
    
    func setupStagingLogging() {
        var logger = OSLogViewModelLogger(subsystem: "com.myapp")
        logger.options = LoggingOptions(
            categories: [.action, .stateChange, .performance],
            format: .standard,
            stateDiffOnly: true,
            groupEffects: true,
            zeroPerformance: false,
            performanceThreshold: PerformanceThreshold(
                type: .actionProcessing,
                customThreshold: 0.05
            )
        )
        AsyncViewModelConfiguration.shared.setLogger(logger)
    }
    
    func setupProductionLogging() {
        let multiLogger = MultiViewModelLogger(loggers: [
            OSLogViewModelLogger(subsystem: "com.myapp"),
            AnalyticsViewModelLogger()
        ])
        
        var options = LoggingOptions(
            categories: [.performance],
            format: .compact,
            zeroPerformance: false,
            performanceThreshold: PerformanceThreshold(
                type: .actionProcessing,
                customThreshold: 0.1
            )
        )
        
        AsyncViewModelConfiguration.shared.setLogger(multiLogger)
        AsyncViewModelConfiguration.shared.globalOptions = options
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
```

### 예제 2: ViewModel별 커스텀 로깅

```swift
// 네트워크 ViewModel: Effect 중심 로깅
@AsyncViewModel(
    loggerMode: .custom(OSLogViewModelLogger(subsystem: "com.myapp.network")),
    loggingOptions: LoggingOptions(
        categories: [.effect, .performance],
        format: .detailed
    )
)
final class NetworkViewModel: ObservableObject {
    // ...
}

// UI ViewModel: State 변경 중심 로깅
@AsyncViewModel(
    loggerMode: .custom(OSLogViewModelLogger(subsystem: "com.myapp.ui")),
    loggingOptions: LoggingOptions(
        categories: [.stateChange],
        format: .standard,
        stateDiffOnly: true
    )
)
final class ProfileViewModel: ObservableObject {
    // ...
}

// 백그라운드 ViewModel: 로깅 비활성화
@AsyncViewModel(loggerMode: .disabled)
final class BackgroundSyncViewModel: ObservableObject {
    // ...
}
```

### 예제 3: 동적 로깅 제어

```swift
@AsyncViewModel
final class DebugViewModel: ObservableObject {
    enum Input {
        case toggleLogging
        case changeLogLevel(LoggingCategory)
    }
    
    enum Action: Equatable, Sendable {
        case toggleLogging
        case changeLogLevel(LoggingCategory)
    }
    
    struct State: Equatable, Sendable {
        var isLoggingEnabled: Bool = true
        var currentCategories: LoggingCategory = .all
    }
    
    enum CancelID: Hashable, Sendable {}
    
    @Published var state: State
    
    init(state: State = State()) {
        self.state = state
    }
    
    func transform(_ input: Input) -> Action {
        switch input {
        case .toggleLogging: return .toggleLogging
        case .changeLogLevel(let category): return .changeLogLevel(category)
        }
    }
    
    func reduce(state: inout State, action: Action) -> [AsyncEffect<Action, CancelID>] {
        switch action {
        case .toggleLogging:
            state.isLoggingEnabled.toggle()
            loggingConfig.isEnabled = state.isLoggingEnabled
            return []
            
        case .changeLogLevel(let category):
            state.currentCategories = category
            loggingConfig.options.categories = category
            return []
        }
    }
}
```

---

## 베스트 프랙티스

### 1. 환경별 로깅 전략

```swift
// ✅ 환경별로 다른 로깅 설정
#if DEBUG
    LoggingOptions(categories: .all, format: .detailed)
#else
    LoggingOptions(categories: [.performance], format: .compact)
#endif

// ❌ 모든 환경에서 동일한 로깅
LoggingOptions(categories: .all, format: .detailed)
```

### 2. 성능 고려

```swift
// ✅ 프로덕션: 필요한 카테고리만 로깅
LoggingOptions(
    categories: [.performance],
    zeroPerformance: false,
    performanceThreshold: PerformanceThreshold(
        type: .actionProcessing,
        customThreshold: 0.1
    )
)

// ❌ 프로덕션: 모든 로그 활성화 (성능 저하)
LoggingOptions(categories: .all, zeroPerformance: true)
```

### 3. State Diff 활용

```swift
// ✅ 큰 State 구조체는 Diff만 표시
LoggingOptions(stateDiffOnly: true)

// ❌ 큰 State 전체 로깅 (가독성 저하)
LoggingOptions(stateDiffOnly: false)
```

### 4. Effect 그룹화

```swift
// ✅ 여러 Effect 발생 시 그룹화
LoggingOptions(groupEffects: true)

// ❌ 개별 Effect 로깅 (로그 혼잡)
LoggingOptions(groupEffects: false)
```

### 5. LoggerMode 선택

```swift
// ✅ 대부분의 경우: 전역 로거
@AsyncViewModel(loggerMode: .shared)

// ✅ 특수한 로깅 필요: 커스텀 로거
@AsyncViewModel(loggerMode: .custom(SpecialLogger()))

// ✅ 성능 민감한 ViewModel: 비활성화
@AsyncViewModel(loggerMode: .disabled)
```

---

## 문제 해결

### 1. 로그가 표시되지 않음

**원인**: 로깅이 비활성화되었거나 카테고리가 일치하지 않음

**해결**:
```swift
// 로깅 활성화 확인
viewModel.loggingConfig.isEnabled = true

// 카테고리 확인
viewModel.loggingConfig.options.categories = .all

// 전역 로거 설정 확인
AsyncViewModelConfiguration.shared.setLogger(OSLogViewModelLogger())
```

### 2. 너무 많은 로그

**원인**: 모든 카테고리 활성화 또는 zeroPerformance: true

**해결**:
```swift
// 필요한 카테고리만 활성화
LoggingOptions(
    categories: [.action, .stateChange],
    zeroPerformance: false,
    performanceThreshold: PerformanceThreshold(
        type: .actionProcessing,
        customThreshold: 0.05
    )
)
```

### 3. OSLog가 Console.app에 표시되지 않음

**원인**: subsystem 또는 category 필터링 필요

**해결**:
```bash
# Console.app에서 필터 설정
log stream --predicate 'subsystem == "com.myapp"'

# 또는 Xcode 콘솔에서
# 필터: subsystem:com.myapp
```

---

## 추가 리소스

- [AsyncViewModel 기본 가이드](../README.md)
- [AsyncTestStore 가이드](./06-AsyncTestStore-Guide.md)
- [ViewModelLoggerBuilder 가이드](./02-Logger-Configuration.md)
- [내부 아키텍처 가이드](./01-Internal-Architecture.md)
