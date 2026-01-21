# README.md 검토 결과

## ❌ 발견된 문제점

### 1. 매크로 파라미터 불일치 (심각)

**README의 잘못된 내용 (라인 214-228):**

```swift
// ❌ 존재하지 않는 파라미터
@AsyncViewModel(isLoggingEnabled: true, logLevel: .debug)
@AsyncViewModel(isLoggingEnabled: false)
```

**실제 구현:**

매크로는 다음 파라미터들을 지원합니다:
- `logging`: LoggingMode (.enabled, .disabled, .minimal, .only(...), .excluding(...))
- `logger`: LoggerMode (.shared, .custom(...), .disabled)
- `loggingOptions`: LoggingOptions (옵션)

**올바른 예제:**

```swift
// ✅ 로깅 모드 설정
@AsyncViewModel(logging: .enabled)
@AsyncViewModel(logging: .disabled)
@AsyncViewModel(logging: .minimal)
@AsyncViewModel(logging: .only(.action, .error))
@AsyncViewModel(logging: .excluding(.performance))

// ✅ 로거 모드 설정
@AsyncViewModel(logger: .shared)
@AsyncViewModel(logger: .custom(OSLogViewModelLogger()))
@AsyncViewModel(logger: .disabled)

// ✅ 로깅 옵션 설정
@AsyncViewModel(
    logging: .enabled,
    loggingOptions: LoggingOptions(
        categories: [.action, .stateChange],
        format: .detailed
    )
)
```

### 2. 로깅 카테고리 예제 불일치 (라인 244-277)

**README의 내용:**

```swift
public enum LogCategory: String {
    case action
    case stateChange
    case effect
    case performance
    case error
}
```

이 enum은 실제로 존재하지 않습니다. 대신 `LoggingCategory` (OptionSet)가 사용됩니다.

**실제 구현:**

```swift
// LoggingCategory는 OptionSet
LoggingOptions(
    categories: [.action, .stateChange, .effect, .performance]
)
```

### 3. 매크로가 생성하는 프로퍼티 표 (라인 231-242)

**README의 표:**

| 프로퍼티 | 타입 | 용도 |
|---------|------|------|
| `isLoggingEnabled` | `Bool` | 로깅 활성화 플래그 |
| `logLevel` | `LogLevel` | 로깅 레벨 |

**실제 매크로가 생성하는 프로퍼티:**

매크로는 `isLoggingEnabled`와 `logLevel`을 생성하지 않습니다. 대신:

| 프로퍼티 | 타입 | 용도 |
|---------|------|------|
| `tasks` | `[CancelID: Task<Void, Never>]` | 진행 중인 비동기 작업 관리 |
| `effectQueue` | `[AsyncEffect<Action, CancelID>]` | Effect 직렬 처리 큐 |
| `isProcessingEffects` | `Bool` | Effect 처리 상태 플래그 |
| `actionObserver` | `((Action) -> Void)?` | 액션 관찰 훅 |
| `stateChangeObserver` | `((State, State) -> Void)?` | 상태 변경 관찰 훅 |
| `effectObserver` | `((AsyncEffect) -> Void)?` | Effect 실행 관찰 훅 |
| `performanceObserver` | `((String, TimeInterval) -> Void)?` | 성능 메트릭 관찰 훅 |
| `timer` | `any AsyncTimer` | 타이머 (기본값: SystemTimer) |
| `loggingConfig` | `ViewModelLoggingConfig` | 로깅 설정 |

### 4. FAQ 로깅 커스터마이징 섹션 (라인 774-804)

**README의 잘못된 예제:**

```swift
// ❌ 존재하지 않는 프로퍼티
viewModel.isLoggingEnabled = false
viewModel.logLevel = .error
```

**올바른 방법:**

```swift
// ✅ ViewModelLoggingConfig 사용
viewModel.loggingConfig.isEnabled = false

// ✅ 전역 로깅 설정
AsyncViewModelConfiguration.shared.globalOptions = LoggingOptions(
    categories: [.performance],
    format: .compact
)
```

---

## ✅ 올바른 내용

### 1. transform 반환 타입

```swift
func transform(_ input: Input) -> [Action]  // ✅ 정확함
```

### 2. Effect API

다음 Effect들은 실제로 존재하며 정확합니다:
- `.run`
- `.cancel`
- `.concurrent`
- `.debounce` ✅
- `.throttle` ✅
- `.sleepThen` ✅
- `.timer` ✅

### 3. AsyncTestStore 사용법

테스트 섹션의 예제들은 정확합니다:
- `AsyncTestStore(viewModel:)`
- `store.send()`
- `store.wait(for:timeout:)`
- `store.cleanup()`

### 4. 프로토콜 정의

AsyncViewModelProtocol의 필수 타입과 메서드는 정확합니다:
- Input, Action, State, CancelID
- transform, reduce, handleError

---

## 📝 수정 권장 사항

### 우선순위 높음 (심각한 오류)

1. **라인 214-228**: 매크로 파라미터 예제 수정
2. **라인 231-242**: 매크로 생성 프로퍼티 표 수정
3. **라인 774-804**: FAQ 로깅 섹션 수정

### 우선순위 중간

4. **라인 244-277**: LogCategory → LoggingCategory로 수정 및 OptionSet 설명 추가
5. **라인 262-277**: 로깅 사용 예시를 실제 파라미터에 맞게 수정

### 추가 권장 사항

- v1.3.0의 로깅 시스템 전면 개편 내용을 반영하여 예제 업데이트
- 새로 추가된 문서(06, 07)로의 링크 추가 및 참조 권장

---

## 🔧 수정안

각 섹션별 수정안은 별도 커밋으로 제공하겠습니다.
