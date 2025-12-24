# AsyncTimer 및 생명주기 관리 가이드

이 문서는 AsyncViewModel의 시간 기반 작업과 생명주기 관리에 대한 완전한 가이드입니다.

---

## 목차

1. [AsyncTimer 개요](#asynctimer-개요)
2. [AsyncTimer 사용 방법](#asynctimer-사용-방법)
3. [생명주기 관리](#생명주기-관리)
4. [타이머와 생명주기 통합](#타이머와-생명주기-통합)
5. [테스트 작성](#테스트-작성)
6. [베스트 프랙티스](#베스트-프랙티스)

---

# Part 1: AsyncTimer

## AsyncTimer 개요

AsyncTimer는 TCA의 Clock 패턴을 참고하여 설계된 테스트 가능한 시간 의존성 추상화입니다. 이를 통해 시간 기반 비동기 작업을 테스트 환경에서 즉시 제어할 수 있습니다.

### AsyncTimer 프로토콜

```swift
public protocol AsyncTimer: Sendable {
    func sleep(for duration: TimeInterval) async throws
    func stream(interval: TimeInterval) -> AsyncStream<Date>
}
```

- **sleep**: 지정된 시간만큼 대기
- **stream**: 지정된 간격으로 반복되는 타이머 스트림

### SystemTimer (운영 환경용)

실제 시스템 시간을 사용하는 타이머입니다.

```swift
let timer = SystemTimer()
try await timer.sleep(for: 1.0) // 실제로 1초 대기
```

### TestTimer (테스트 환경용)

가상 시간을 제어할 수 있는 타이머입니다.

```swift
let timer = TestTimer()

Task {
    try await timer.sleep(for: 1.0)
    print("1초 후 실행")
}

// 가상 시간 1초 진행 (즉시 완료)
await timer.tick(by: 1.0)
```

## AsyncTimer 사용 방법

### 1. ViewModel에서 타이머 사용

```swift
@AsyncViewModel
final class CountdownViewModel: ObservableObject {
    enum Input: Equatable, Sendable {
        case startCountdown
        case stopCountdown
    }
    
    enum Action: Equatable, Sendable {
        case countdownStarted
        case tick
        case countdownFinished
    }
    
    struct State: Equatable, Sendable {
        var remainingSeconds: Int = 10
        var isRunning: Bool = false
    }
    
    enum CancelID: Hashable, Sendable {
        case countdown
    }
    
    @Published var state: State = State()
    
    // timer는 @AsyncViewModel 매크로가 자동으로 생성
    // 기본값: SystemTimer()
    
    func transform(_ input: Input) -> [Action] {
        switch input {
        case .startCountdown:
            return [.countdownStarted]
        case .stopCountdown:
            return []
        }
    }
    
    func reduce(state: inout State, action: Action) -> [AsyncEffect<Action, CancelID>] {
        switch action {
        case .countdownStarted:
            state.isRunning = true
            // 1초마다 tick Action 실행
            return [.timer(id: .countdown, interval: 1.0, action: .tick)]
            
        case .tick:
            state.remainingSeconds -= 1
            if state.remainingSeconds <= 0 {
                state.isRunning = false
                return [
                    .cancel(id: .countdown),
                    .action(.countdownFinished)
                ]
            }
            return [.none]
            
        case .countdownFinished:
            // 카운트다운 완료 처리
            return [.none]
        }
    }
}
```

### 2. 지연된 작업 실행 (sleepThen)

```swift
func reduce(state: inout State, action: Action) -> [AsyncEffect<Action, CancelID>] {
    switch action {
    case .showMessage:
        state.message = "안녕하세요!"
        // 3초 후 메시지 숨기기
        return [.sleepThen(id: .hideMessage, for: 3.0, action: .hideMessage)]
        
    case .hideMessage:
        state.message = nil
        return [.none]
    }
}
```

### 3. 반복 타이머 (timer)

```swift
func reduce(state: inout State, action: Action) -> [AsyncEffect<Action, CancelID>] {
    switch action {
    case .startAutoRefresh:
        state.isAutoRefreshing = true
        // 5초마다 데이터 새로고침
        return [.timer(id: .autoRefresh, interval: 5.0, action: .refresh)]
        
    case .stopAutoRefresh:
        state.isAutoRefreshing = false
        return [.cancel(id: .autoRefresh)]
        
    case .refresh:
        // 데이터 새로고침 로직
        return [.run { try await repository.fetchLatestData() }]
    }
}
```

## AsyncEffect API

### .sleepThen

지정된 시간 후 Action을 실행합니다.

```swift
.sleepThen(id: .timer, for: 1.0, action: .timerFired)
```

- **id**: 취소 가능한 ID (옵셔널)
- **for**: 대기 시간 (초)
- **action**: 실행할 Action

### .timer

반복 타이머를 시작합니다.

```swift
.timer(id: .autoRefresh, interval: 5.0, action: .refresh)
```

- **id**: 취소 가능한 ID (옵셔널)
- **interval**: 반복 간격 (초)
- **action**: 매 interval마다 실행할 Action

### .cancel

타이머를 취소합니다.

```swift
.cancel(id: .autoRefresh)
```

---

# Part 2: 생명주기 관리

## 명시적 생명주기 관리

AsyncViewModel은 **명시적인 생명주기 관리**를 권장합니다. SwiftUI View의 `.onDisappear`에서 필요한 정리 작업을 수행하세요.

## 기본 패턴

### ✅ 권장: .onDisappear에서 명시적 정리

```swift
struct CountdownTimerView: View {
    @StateObject private var viewModel = CountdownViewModel()
    
    var body: some View {
        VStack {
            // ... UI 코드 ...
        }
        .onDisappear {
            // 화면을 벗어날 때 타이머 정리
            if viewModel.state.isRunning {
                viewModel.send(.resetCountdown)
            }
        }
    }
}
```

**장점:**
- ✅ 명확하고 예측 가능
- ✅ 즉시 실행됨
- ✅ 디버깅 용이
- ✅ 팀원 모두가 이해 가능

## 실전 예시

### 1. 타이머 정리

```swift
struct TimerView: View {
    @StateObject private var viewModel = TimerViewModel()
    
    var body: some View {
        // ... UI ...
        .onDisappear {
            // 모든 활성 타이머 중지
            viewModel.send(.stopAllTimers)
        }
    }
}
```

### 2. 자동 새로고침 중지

```swift
struct AutoRefreshView: View {
    @StateObject private var viewModel = AutoRefreshViewModel()
    
    var body: some View {
        // ... UI ...
        .onDisappear {
            // 자동 새로고침 중지
            if viewModel.state.isAutoRefreshing {
                viewModel.send(.stopAutoRefresh)
            }
        }
    }
}
```

### 3. 검색 취소

```swift
struct SearchView: View {
    @StateObject private var viewModel = SearchViewModel()
    
    var body: some View {
        // ... UI ...
        .onDisappear {
            // 진행 중인 검색 취소 및 상태 초기화
            if !viewModel.state.query.isEmpty || viewModel.state.isSearching {
                viewModel.send(.clearSearch)
            }
        }
    }
}
```

## 생명주기 흐름

```
사용자 액션               SwiftUI 생명주기            ViewModel
────────────────────────────────────────────────────────────────
화면 진입        ─────>   @StateObject 생성    ─────>  init()
                         .onAppear 호출
                         
타이머 시작      ─────>                         ─────>  Effect 시작
                                                        
                         타이머 진행 중...               Effect 실행 중
                         
뒤로 가기        ─────>   .onDisappear 호출    ─────>  send(.stop)
                                                        Effect 취소
                         @StateObject 해제      ─────>  deinit()
```

## 정리 체크리스트

### 타이머/주기적 작업
- [ ] `.timer()` Effect 취소
- [ ] 활성 타이머 중지
- [ ] 카운트 초기화 (필요시)

### 네트워크 요청
- [ ] 진행 중인 요청 취소
- [ ] 다운로드 중단
- [ ] 업로드 취소

### 위치/센서
- [ ] GPS 추적 중지
- [ ] 센서 모니터링 중단
- [ ] 알림 구독 해제

### 미디어
- [ ] 비디오 일시정지
- [ ] 오디오 중지
- [ ] 스트리밍 중단

## ViewModel 구현 패턴

### Input에 cleanup Action 추가

```swift
@AsyncViewModel
final class MyViewModel: ObservableObject {
    enum Input: Equatable, Sendable {
        case start
        case stop
        case cleanup  // ✅ 정리용 Input 추가
    }
    
    enum Action: Equatable, Sendable {
        case started
        case stopped
        case cleanedUp
    }
    
    func transform(_ input: Input) -> [Action] {
        switch input {
        case .cleanup:
            return [.stopped, .cleanedUp]
        // ...
        }
    }
    
    func reduce(state: inout State, action: Action) -> [AsyncEffect<Action, CancelID>] {
        switch action {
        case .stopped:
            state.isRunning = false
            return [.cancel(id: .timer)]
            
        case .cleanedUp:
            // 추가 정리 작업
            return [.none]
        // ...
        }
    }
}
```

### View에서 사용

```swift
struct MyView: View {
    @StateObject private var viewModel = MyViewModel()
    
    var body: some View {
        // ... UI ...
        .onDisappear {
            viewModel.send(.cleanup)  // ✅ 간단하게 정리
        }
    }
}
```

---

# Part 3: 타이머와 생명주기 통합

## 완전한 타이머 ViewModel 예제

```swift
@AsyncViewModel
final class AutoRefreshViewModel: ObservableObject {
    enum Input: Equatable, Sendable {
        case startAutoRefresh
        case stopAutoRefresh
        case cleanup
    }
    
    enum Action: Equatable, Sendable {
        case autoRefreshStarted
        case refresh
        case refreshCompleted
        case autoRefreshStopped
    }
    
    struct State: Equatable, Sendable {
        var isAutoRefreshing: Bool = false
        var lastRefreshDate: Date?
        var refreshCount: Int = 0
    }
    
    enum CancelID: Hashable, Sendable {
        case autoRefresh
    }
    
    @Published var state: State = State()
    
    func transform(_ input: Input) -> [Action] {
        switch input {
        case .startAutoRefresh:
            return [.autoRefreshStarted]
        case .stopAutoRefresh, .cleanup:
            return [.autoRefreshStopped]
        }
    }
    
    func reduce(state: inout State, action: Action) -> [AsyncEffect<Action, CancelID>] {
        switch action {
        case .autoRefreshStarted:
            state.isAutoRefreshing = true
            return [.timer(id: .autoRefresh, interval: 5.0, action: .refresh)]
            
        case .refresh:
            state.refreshCount += 1
            return [.run { 
                // 데이터 새로고침 로직
                try await Task.sleep(nanoseconds: 500_000_000)
                return .refreshCompleted
            }]
            
        case .refreshCompleted:
            state.lastRefreshDate = Date()
            return [.none]
            
        case .autoRefreshStopped:
            state.isAutoRefreshing = false
            return [.cancel(id: .autoRefresh)]
        }
    }
}
```

### 대응하는 View 구현

```swift
struct AutoRefreshView: View {
    @StateObject private var viewModel = AutoRefreshViewModel()
    
    var body: some View {
        VStack(spacing: 20) {
            if viewModel.state.isAutoRefreshing {
                Text("자동 새로고침 중...")
                    .foregroundColor(.green)
            }
            
            if let lastRefresh = viewModel.state.lastRefreshDate {
                Text("마지막 새로고침: \(lastRefresh, style: .time)")
            }
            
            Text("새로고침 횟수: \(viewModel.state.refreshCount)")
            
            Button(viewModel.state.isAutoRefreshing ? "중지" : "시작") {
                if viewModel.state.isAutoRefreshing {
                    viewModel.send(.stopAutoRefresh)
                } else {
                    viewModel.send(.startAutoRefresh)
                }
            }
        }
        .padding()
        .onDisappear {
            // ✅ 화면을 벗어날 때 자동으로 정리
            if viewModel.state.isAutoRefreshing {
                viewModel.send(.cleanup)
            }
        }
    }
}
```

---

# Part 4: 테스트 작성

## AsyncTestStore의 TestTimer 통합

`AsyncTestStore`는 자동으로 `TestTimer`를 주입합니다.

### 기본 타이머 테스트

```swift
@Test("카운트다운 테스트")
func testCountdown() async throws {
    // Given
    let viewModel = CountdownViewModel()
    let store = AsyncTestStore(viewModel: viewModel)
    
    // When - 카운트다운 시작
    store.send(.startCountdown)
    
    // Then - 초기 상태
    #expect(store.state.isRunning == true)
    #expect(store.state.remainingSeconds == 10)
    
    // When - 1초 진행 (가상 시간)
    await store.tick(by: 1.0)
    try await store.waitForEffects()
    
    // Then
    #expect(store.state.remainingSeconds == 9)
    
    // When - 9초 더 진행 (총 10초)
    await store.tick(by: 9.0)
    try await store.waitForEffects()
    
    // Then - 카운트다운 완료
    #expect(store.state.remainingSeconds == 0)
    #expect(store.state.isRunning == false)
    
    store.cleanup()
}
```

### 빠른 테스트 실행

```swift
@Test("긴 지연 시간도 즉시 테스트")
func testLongDelay() async throws {
    let viewModel = NotificationViewModel()
    let store = AsyncTestStore(viewModel: viewModel)
    
    let startTime = Date()
    
    // When - 1시간 후 알림 (실제로는 즉시)
    store.send(.scheduleNotification(after: 3600))
    await store.tick(by: 3600) // 1시간 진행
    try await store.waitForEffects()
    
    let duration = Date().timeIntervalSince(startTime)
    
    // Then - 실제 시간은 1초 미만
    #expect(duration < 1.0)
    #expect(store.state.notificationShown == true)
    
    store.cleanup()
}
```

### 타이머 취소 테스트

```swift
@Test("타이머 취소 테스트")
func testTimerCancellation() async throws {
    let viewModel = AutoRefreshViewModel()
    let store = AsyncTestStore(viewModel: viewModel)
    
    // When - 자동 새로고침 시작
    store.send(.startAutoRefresh)
    
    // When - 5초 진행 (1회 새로고침)
    await store.tick(by: 5.0)
    try await store.waitForEffects()
    #expect(store.state.refreshCount == 1)
    
    // When - 자동 새로고침 중지
    store.send(.stopAutoRefresh)
    try await store.waitForEffects()
    
    // When - 시간 진행해도 더 이상 새로고침되지 않음
    await store.tick(by: 100.0)
    try await Task.sleep(nanoseconds: 10_000_000)
    
    // Then - refreshCount 변화 없음
    #expect(store.state.refreshCount == 1)
    
    store.cleanup()
}
```

### 생명주기와 타이머 통합 테스트

```swift
@Test("화면 이탈 시 타이머 정리 테스트")
func testTimerCleanupOnDisappear() async throws {
    let viewModel = AutoRefreshViewModel()
    let store = AsyncTestStore(viewModel: viewModel)
    
    // Given - 자동 새로고침 시작
    store.send(.startAutoRefresh)
    #expect(store.state.isAutoRefreshing == true)
    
    // When - 일정 시간 동안 새로고침
    await store.tick(by: 10.0)
    try await store.waitForEffects()
    #expect(store.state.refreshCount == 2)
    
    // When - 화면 이탈 (cleanup 호출)
    store.send(.cleanup)
    try await store.waitForEffects()
    
    // Then - 타이머 중지됨
    #expect(store.state.isAutoRefreshing == false)
    
    // When - 추가 시간이 지나도 새로고침 안 됨
    let countBeforeWait = store.state.refreshCount
    await store.tick(by: 20.0)
    try await Task.sleep(nanoseconds: 10_000_000)
    
    #expect(store.state.refreshCount == countBeforeWait)
    
    store.cleanup()
}
```

## TestTimer 메서드

### tick(by:)

가상 시간을 진행시킵니다.

```swift
let timer = TestTimer()

Task {
    try await timer.sleep(for: 1.0)
    print("1초 후")
}

Task {
    try await timer.sleep(for: 2.0)
    print("2초 후")
}

await timer.tick(by: 1.0) // "1초 후" 출력
await timer.tick(by: 1.0) // "2초 후" 출력
```

### flush()

모든 대기 중인 sleep을 즉시 완료시킵니다.

```swift
let timer = TestTimer()

Task {
    try await timer.sleep(for: 100.0)
    print("100초 후")
}

await timer.flush() // 즉시 "100초 후" 출력
```

### currentTime

현재 가상 시간을 확인합니다.

```swift
let timer = TestTimer()
print(timer.currentTime) // 0.0

await timer.tick(by: 5.0)
print(timer.currentTime) // 5.0
```

---

# Part 5: 베스트 프랙티스

## 타이머 관리

### 1. CancelID 정의

타이머마다 고유한 CancelID를 정의하세요.

```swift
enum CancelID: Hashable, Sendable {
    case countdown
    case autoRefresh
    case debounceSearch
}
```

### 2. 타이머 정리

타이머를 시작할 때 이전 타이머를 취소하세요.

```swift
case .startTimer:
    return [
        .cancel(id: .timer), // 이전 타이머 취소
        .timer(id: .timer, interval: 1.0, action: .tick)
    ]
```

### 3. 테스트에서 waitForEffects 사용

타이머 진행 후 Effect 완료를 대기하세요.

```swift
await store.tick(by: 1.0)
try await store.waitForEffects() // Effect 처리 완료 대기
#expect(store.state.count == 1)
```

## 생명주기 관리

### 1. 항상 .onDisappear 사용

모든 타이머/네트워크 작업에 필수입니다.

```swift
.onDisappear {
    if viewModel.state.isRunning {
        viewModel.send(.cleanup)
    }
}
```

### 2. cleanup Input 패턴

ViewModel에 명시적인 cleanup Action을 추가하세요.

```swift
enum Input: Equatable, Sendable {
    case start
    case stop
    case cleanup  // ✅ 정리용 Input
}
```

### 3. 상태 확인

필요할 때만 정리 작업을 수행하세요.

```swift
.onDisappear {
    // ✅ 상태 확인 후 정리
    if viewModel.state.isAutoRefreshing {
        viewModel.send(.stopAutoRefresh)
    }
}
```

## 디버깅 팁

### 로그 추가

```swift
.onDisappear {
    print("🔴 [MyView] onDisappear")
    viewModel.send(.cleanup)
}
```

### ViewModel init/deinit 추적

```swift
@AsyncViewModel
final class MyViewModel: ObservableObject {
    init() {
        print("🟢 [MyViewModel] init")
    }
    
    deinit {
        print("🔴 [MyViewModel] deinit")
    }
}
```

### 예상 로그 순서

```
🟢 [MyViewModel] init
(화면 사용 중...)
🔴 [MyView] onDisappear
(Effect 취소...)
🔴 [MyViewModel] deinit
```

## 일반적인 실수

### ❌ .onDisappear를 까먹음

```swift
struct MyView: View {
    @StateObject private var viewModel = MyViewModel()
    
    var body: some View {
        // ... UI ...
        // ❌ .onDisappear 없음!
    }
}
```

**결과:** 타이머가 백그라운드에서 계속 실행됨

### ❌ 조건 없이 항상 정리

```swift
.onDisappear {
    // ❌ 상태 확인 없이 무조건 전송
    viewModel.send(.stop)
}
```

**개선:**

```swift
.onDisappear {
    // ✅ 필요할 때만 정리
    if viewModel.state.isRunning {
        viewModel.send(.stop)
    }
}
```

### ❌ 복잡한 로직

```swift
.onDisappear {
    // ❌ onDisappear에 비즈니스 로직
    if viewModel.state.isRunning {
        viewModel.state.count += 1  // 직접 수정
        viewModel.tasks.forEach { $0.cancel() }  // 직접 접근
    }
}
```

**개선:**

```swift
.onDisappear {
    // ✅ Input으로 위임
    viewModel.send(.cleanup)
}
```

---

# 마이그레이션 가이드

## 기존 Task.sleep 코드

```swift
// Before
.run(id: .delay) {
    try await Task.sleep(nanoseconds: 1_000_000_000)
    return .timerFired
}
```

```swift
// After (테스트 가능)
.sleepThen(id: .delay, for: 1.0, action: .timerFired)
```

## 기존 Timer 코드

```swift
// Before
.run(id: .timer) {
    for await _ in Timer.publish(every: 1.0, on: .main, in: .common).values {
        return .tick
    }
}
```

```swift
// After (테스트 가능)
.timer(id: .timer, interval: 1.0, action: .tick)
```

---

# TCA Clock과의 비교

| 기능 | TCA Clock | AsyncTimer |
|-----|-----------|------------|
| 프로토콜 기반 | ✅ | ✅ |
| 테스트용 구현 | TestClock | TestTimer |
| 운영용 구현 | ContinuousClock | SystemTimer |
| sleep 지원 | ✅ | ✅ |
| timer 지원 | ✅ | ✅ |
| advance 메서드 | ✅ | ✅ |
| AsyncViewModel 통합 | ❌ | ✅ |
| AsyncTestStore 자동 주입 | ❌ | ✅ |

---

# 요약

## AsyncTimer 핵심

1. **AsyncTimer**: 시간 의존성 추상화 프로토콜
2. **SystemTimer**: 실제 운영 환경용 구현
3. **TestTimer**: 테스트 환경용 구현 (시간 제어 가능)
4. **AsyncTestStore**: 자동으로 TestTimer 주입
5. **Effect API**: `.sleepThen`, `.timer`, `.cancel`
6. **테스트**: `store.tick(by:)`로 가상 시간 제어

## 생명주기 관리 핵심

| 항목 | 방식 | 장점 | 단점 |
|------|------|------|------|
| **명시적 .onDisappear** | 개발자가 직접 작성 | 명확, 즉시 실행, 디버깅 용이 | 반복 코드 |
| ~~자동 deinit~~ | ~~매크로 생성~~ | ~~편리함~~ | ~~불확실성, 지연 가능~~ |

## 권장사항

1. **항상 .onDisappear 사용**
   - 모든 타이머/네트워크 작업에 필수

2. **cleanup Input 패턴**
   - ViewModel에 명시적인 cleanup Action

3. **상태 확인**
   - 필요할 때만 정리 작업 수행

4. **로그 추가**
   - 디버깅을 위한 생명주기 로그

5. **팀 컨벤션**
   - 일관된 패턴 유지

6. **테스트 작성**
   - TestTimer로 시간 기반 로직 검증

## 결론

AsyncViewModel의 AsyncTimer와 생명주기 관리를 통해:

✅ **테스트 가능성** - 시간 기반 로직을 빠르게 테스트
✅ **예측 가능성** - 언제 정리되는지 명확
✅ **디버깅 용이성** - 로그로 쉽게 추적
✅ **팀 협업** - 모두가 이해 가능한 코드
✅ **안정성** - 메모리 누수 방지

**AsyncTimer와 `.onDisappear`를 습관화하세요!** 🎯

