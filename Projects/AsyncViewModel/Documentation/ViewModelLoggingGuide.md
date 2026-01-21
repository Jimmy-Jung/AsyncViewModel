# ViewModel 로깅 가이드

@AsyncViewModel 매크로를 사용하면 ViewModel별로 세밀한 로깅 설정을 컴파일 타임에 지정할 수 있습니다.

## 기본 사용법

### 기본 설정 (모든 로깅 활성화)

```swift
@AsyncViewModel
final class MyViewModel: ObservableObject {
    // 모든 로깅이 활성화됩니다
}
```

### 로깅 완전 비활성화

```swift
@AsyncViewModel(logging: .disabled)
final class NoisyAnimationViewModel: ObservableObject {
    // 모든 로깅이 비활성화됩니다
}
```

### State 변경 로그만 제외 (가장 시끄러운 로그)

```swift
@AsyncViewModel(logging: .noStateChanges)
final class FrequentUpdateViewModel: ObservableObject {
    // State 변경 로그는 출력되지 않지만, Action, Effect, Error는 로깅됩니다
}
```

### 에러만 로깅

```swift
@AsyncViewModel(logging: .minimal)
final class PerformanceCriticalViewModel: ObservableObject {
    // 에러만 로깅됩니다
}
```

## 고급 설정

### 특정 카테고리만 활성화

```swift
@AsyncViewModel(logging: .only(.error, .action))
final class SelectiveViewModel: ObservableObject {
    // 에러와 액션만 로깅됩니다
}
```

### 특정 카테고리 제외

```swift
@AsyncViewModel(logging: .excluding(.stateChange, .performance))
final class ExcludingViewModel: ObservableObject {
    // State 변경과 성능 로그는 제외됩니다
}
```

### 커스텀 설정

```swift
@AsyncViewModel(logging: .custom(
    categories: [.action, .error],
    minimumLevel: .info,
    maxDepth: 2,
    maxValueLength: 50,
    throttleInterval: 0.5
))
final class CustomViewModel: ObservableObject {
    // - action과 error만 로깅
    // - info 레벨 이상만 출력
    // - 중첩 깊이 2까지만 표시
    // - 값 길이 50자까지만 표시
    // - State 변경은 0.5초마다만 로깅
}
```

## 로깅 카테고리

- `.action`: Action 실행 로그
- `.stateChange`: State 변경 로그
- `.effect`: Effect 실행 로그
- `.performance`: 성능 메트릭 로그
- `.error`: 에러 로그

## 사전 정의된 모드

### `.enabled`
모든 로깅 활성화 (기본값)

### `.disabled`
모든 로깅 비활성화

### `.minimal`
에러만 로깅

### `.noStateChanges`
State 변경 로그 제외 (가장 시끄러운 로그 제거)

### `.performanceOnly`
성능과 에러만 로깅

## 글로벌 설정과의 관계

ViewModel별 설정은 글로벌 설정과 병합됩니다:

```swift
// 글로벌 설정
let logger = OSLogViewModelLogger()
logger.options.format = .compact
logger.options.minimumLevel = .debug
LoggerConfiguration.setLogger(logger)

// ViewModel별 설정이 더 엄격하면 ViewModel 설정이 우선
@AsyncViewModel(logging: .custom(minimumLevel: .info))
final class MyViewModel: ObservableObject {
    // minimumLevel은 .info로 적용됩니다 (글로벌 .debug보다 높음)
}
```

## 사용 시나리오

### 시나리오 1: 애니메이션 ViewModel

```swift
@AsyncViewModel(logging: .disabled)
final class AnimationViewModel: ObservableObject {
    // 0.1초마다 State가 변경되므로 로깅 비활성화
}
```

### 시나리오 2: 복잡한 State를 가진 ViewModel

```swift
@AsyncViewModel(logging: .custom(
    categories: [.action, .error],
    maxDepth: 1,
    maxValueLength: 30
))
final class ComplexStateViewModel: ObservableObject {
    struct State: Equatable, Sendable {
        var hugeArray: [ComplexItem] = []  // 로깅에서 간결하게 표시
        var nestedObject: Level1 = Level1(...)  // 깊이 1까지만 표시
    }
}
```

### 시나리오 3: 디버깅 중인 ViewModel

```swift
@AsyncViewModel(logging: .only(.action, .stateChange))
final class DebuggingViewModel: ObservableObject {
    // 디버깅 중에는 Action과 State 변경만 집중적으로 봅니다
}
```

## 성능 고려사항

- 컴파일 타임에 설정이 결정되므로 런타임 오버헤드가 없습니다
- 로깅이 비활성화된 경우 early return으로 성능 영향이 최소화됩니다
- State 변경 스로틀링을 사용하면 빈번한 업데이트 시 로그 폭주를 방지할 수 있습니다
