# AsyncTestStore 완전 가이드

## 목차
- [개요](#개요)
- [기본 사용법](#기본-사용법)
- [TestTimer 활용](#testtimer-활용)
- [StateHistoryTracker 활용](#statehistorytracker-활용)
- [고급 테스트 패턴](#고급-테스트-패턴)
- [실전 예제](#실전-예제)
- [베스트 프랙티스](#베스트-프랙티스)

---

## 개요

`AsyncTestStore`는 AsyncViewModel의 비동기 로직을 쉽게 테스트할 수 있도록 도와주는 테스팅 유틸리티입니다.

### 주요 기능

- ✅ **액션 자동 추적**: 모든 액션(Action)을 자동으로 기록
- ⏱️ **가상 시간 제어**: TestTimer로 시간 기반 로직 테스트
- 🔍 **상태 검증**: 비동기 상태 변경 대기 및 검증
- 📊 **히스토리 추적**: StateHistoryTracker로 상태 변경 이력 확인
- 🎯 **Task 관리**: 활성 Task 추적 및 취소 검증

---

## 기본 사용법

### 1. AsyncTestStore 생성

```swift
import Testing
@testable import AsyncViewModel

@Test("기본 카운터 테스트")
func testCounter() async throws {
    // Given
    let viewModel = CounterViewModel()
    let store = AsyncTestStore(viewModel: viewModel)
    defer { store.cleanup() }  // 테스트 종료 시 정리
    
    // When
    store.send(.increment)
    
    // Then
    #expect(store.state.count == 1)
    #expect(store.actions == [.increment])
}
```

### 2. 상태 변경 검증

```swift
@Test("상태 변경 검증")
func testStateChange() async throws {
    let store = AsyncTestStore(viewModel: viewModel)
    defer { store.cleanup() }
    
    // 즉시 상태 확인
    #expect(store.state.isLoading == false)
    
    // 액션 전송
    store.send(.loadData)
    
    // 비동기 상태 변경 대기
    try await store.wait(for: { $0.isLoading == true }, timeout: 1.0)
    try await store.wait(for: { $0.data != nil }, timeout: 3.0)
    
    // 최종 상태 검증
    #expect(store.state.isLoading == false)
    #expect(store.state.data?.isEmpty == false)
}
```

### 3. 액션 추적

```swift
@Test("액션 시퀀스 검증")
func testActionSequence() async throws {
    let store = AsyncTestStore(viewModel: viewModel)
    defer { store.cleanup() }
    
    store.send(.loadData)
    
    // 특정 액션 대기
    try await store.waitForAction(matching: { action in
        if case .dataLoaded = action { return true }
        return false
    }, timeout: 2.0)
    
    // 액션 순서 검증
    #expect(store.actions.count == 2)
    #expect(store.actions[0] == .loadData)
    #expect(store.actions[1] == .dataLoaded)
}
```

---

## TestTimer 활용

`TestTimer`는 시간 기반 로직을 테스트할 때 실제 시간 대기 없이 가상 시간을 제어할 수 있습니다.

### 1. 기본 시간 제어

```swift
@Test("디바운스 테스트")
func testDebounce() async throws {
    let viewModel = SearchViewModel()
    let store = AsyncTestStore(viewModel: viewModel)
    defer { store.cleanup() }
    
    // 검색어 입력 (디바운스 0.5초)
    store.send(.searchTextChanged("Swift"))
    
    // 0.3초만 진행 (디바운스 트리거 안됨)
    await store.testTimer.tick(by: 0.3)
    #expect(store.state.searchResults == nil)
    
    // 추가로 0.3초 진행 (총 0.6초, 디바운스 트리거됨)
    await store.testTimer.tick(by: 0.3)
    await store.testTimer.run()
    
    // 검색 실행 확인
    try await store.wait(for: { $0.isSearching == true }, timeout: 1.0)
}
```

### 2. 타이머 기반 로직 테스트

```swift
@Test("주기적 폴링 테스트")
func testPeriodicPolling() async throws {
    let viewModel = PollingViewModel()
    let store = AsyncTestStore(viewModel: viewModel)
    defer { store.cleanup() }
    
    // 폴링 시작 (5초마다 실행)
    store.send(.startPolling)
    
    // 초기 폴링 실행 확인
    try await store.wait(for: { $0.pollCount == 1 }, timeout: 1.0)
    
    // 5초 진행 → 2번째 폴링
    await store.testTimer.tick(by: 5.0)
    try await store.wait(for: { $0.pollCount == 2 }, timeout: 1.0)
    
    // 10초 진행 → 3, 4번째 폴링
    await store.testTimer.tick(by: 10.0)
    try await store.wait(for: { $0.pollCount == 4 }, timeout: 1.0)
}
```

### 3. 타임아웃 테스트

```swift
@Test("타임아웃 처리 테스트")
func testTimeout() async throws {
    let viewModel = RequestViewModel()
    let store = AsyncTestStore(viewModel: viewModel)
    defer { store.cleanup() }
    
    // 타임아웃 30초 설정된 요청 시작
    store.send(.startRequest)
    
    // 30초 진행
    await store.testTimer.tick(by: 30.0)
    
    // 타임아웃 액션 확인
    try await store.waitForAction(matching: { action in
        if case .requestTimedOut = action { return true }
        return false
    }, timeout: 1.0)
}
```

---

## StateHistoryTracker 활용

`StateHistoryTracker`는 상태 변경 이력을 추적하여 상태 전이를 검증할 수 있습니다.

### 1. 기본 히스토리 추적

```swift
@Test("상태 변경 히스토리 추적")
func testStateHistory() async throws {
    let viewModel = CounterViewModel()
    let store = AsyncTestStore(viewModel: viewModel)
    let tracker = StateHistoryTracker<CounterViewModel.State>()
    defer { store.cleanup() }
    
    // StateHistoryTracker 연결
    viewModel.stateChangeObserver = { old, new in
        tracker.record(old: old, new: new)
    }
    
    // 액션 실행
    store.send(.increment)  // 0 → 1
    store.send(.increment)  // 1 → 2
    store.send(.decrement)  // 2 → 1
    
    // 히스토리 검증
    #expect(tracker.count == 3)
    #expect(tracker.history[0].old.count == 0)
    #expect(tracker.history[0].new.count == 1)
    #expect(tracker.history[1].old.count == 1)
    #expect(tracker.history[1].new.count == 2)
    #expect(tracker.history[2].old.count == 2)
    #expect(tracker.history[2].new.count == 1)
}
```

### 2. 상태 전이 패턴 검증

```swift
@Test("로딩 상태 전이 검증")
func testLoadingStateTransition() async throws {
    let viewModel = DataViewModel()
    let store = AsyncTestStore(viewModel: viewModel)
    let tracker = StateHistoryTracker<DataViewModel.State>()
    defer { store.cleanup() }
    
    viewModel.stateChangeObserver = { old, new in
        tracker.record(old: old, new: new)
    }
    
    // 데이터 로드
    store.send(.loadData)
    
    // 로딩 완료 대기
    try await store.wait(for: { $0.isLoading == false && $0.data != nil }, timeout: 3.0)
    
    // 상태 전이 패턴 검증: idle → loading → loaded
    #expect(tracker.count >= 2)
    
    // 첫 번째 전이: idle → loading
    let firstTransition = tracker.history[0]
    #expect(firstTransition.old.isLoading == false)
    #expect(firstTransition.new.isLoading == true)
    
    // 마지막 전이: loading → loaded
    let lastTransition = tracker.last!
    #expect(lastTransition.old.isLoading == true)
    #expect(lastTransition.new.isLoading == false)
    #expect(lastTransition.new.data != nil)
}
```

### 3. 특정 상태 변경 횟수 검증

```swift
@Test("상태 변경 횟수 검증")
func testStateChangeCount() async throws {
    let viewModel = FormViewModel()
    let store = AsyncTestStore(viewModel: viewModel)
    let tracker = StateHistoryTracker<FormViewModel.State>()
    defer { store.cleanup() }
    
    viewModel.stateChangeObserver = { old, new in
        tracker.record(old: old, new: new)
    }
    
    // 여러 필드 입력
    store.send(.nameChanged("John"))
    store.send(.emailChanged("john@example.com"))
    store.send(.ageChanged(30))
    
    // 정확히 3번의 상태 변경 발생 확인
    #expect(tracker.count == 3)
    
    // 각 변경이 올바른 필드를 수정했는지 확인
    #expect(tracker.history[0].new.name == "John")
    #expect(tracker.history[1].new.email == "john@example.com")
    #expect(tracker.history[2].new.age == 30)
}
```

---

## 고급 테스트 패턴

### 1. Task 관리 테스트

```swift
@Test("Task 취소 테스트")
func testTaskCancellation() async throws {
    let viewModel = DownloadViewModel()
    let store = AsyncTestStore(viewModel: viewModel)
    defer { store.cleanup() }
    
    // 다운로드 시작
    store.send(.startDownload)
    
    // Task 활성화 확인
    #expect(store.hasActiveTask(id: .download) == true)
    #expect(store.activeTaskCount == 1)
    
    // 다운로드 취소
    store.send(.cancelDownload)
    
    // Task 취소 확인
    try await store.waitForTaskCancellation(id: .download, timeout: 1.0)
    #expect(store.hasActiveTask(id: .download) == false)
}
```

### 2. 병렬 Effect 테스트

```swift
@Test("병렬 Effect 실행 테스트")
func testConcurrentEffects() async throws {
    let viewModel = ParallelViewModel()
    let store = AsyncTestStore(viewModel: viewModel)
    defer { store.cleanup() }
    
    // 병렬 작업 시작
    store.send(.startParallelTasks)
    
    // 여러 Task가 동시에 실행되는지 확인
    try await store.waitForTaskStart(id: .taskA, timeout: 1.0)
    try await store.waitForTaskStart(id: .taskB, timeout: 1.0)
    try await store.waitForTaskStart(id: .taskC, timeout: 1.0)
    
    #expect(store.activeTaskCount == 3)
    
    // 모든 작업 완료 대기
    try await store.waitForAllTasksToComplete(timeout: 5.0)
    
    // 결과 검증
    #expect(store.state.results.count == 3)
}
```

### 3. 에러 처리 테스트

```swift
@Test("에러 처리 테스트")
func testErrorHandling() async throws {
    let viewModel = NetworkViewModel()
    let store = AsyncTestStore(viewModel: viewModel)
    let errorTracker = StateHistoryTracker<NetworkViewModel.State>()
    defer { store.cleanup() }
    
    viewModel.stateChangeObserver = { old, new in
        errorTracker.record(old: old, new: new)
    }
    
    // 에러 발생 시나리오
    store.send(.fetchDataWithError)
    
    // 에러 상태 확인
    try await store.wait(for: { $0.error != nil }, timeout: 2.0)
    
    // 에러가 올바르게 처리되었는지 확인
    #expect(store.state.isLoading == false)
    #expect(store.state.error != nil)
    
    // 에러 복구
    store.send(.clearError)
    #expect(store.state.error == nil)
}
```

---

## 실전 예제

### 예제 1: 검색 기능 테스트

```swift
@AsyncViewModel
final class SearchViewModel: ObservableObject {
    enum Input {
        case searchTextChanged(String)
        case clearSearch
    }
    
    enum Action: Equatable, Sendable {
        case searchTextChanged(String)
        case search(String)
        case searchCompleted([String])
        case clearSearch
    }
    
    struct State: Equatable, Sendable {
        var searchText: String = ""
        var results: [String] = []
        var isSearching: Bool = false
    }
    
    enum CancelID: Hashable, Sendable {
        case search
    }
    
    @Published var state: State
    
    init(state: State = State()) {
        self.state = state
    }
    
    func transform(_ input: Input) -> Action {
        switch input {
        case .searchTextChanged(let text): return .searchTextChanged(text)
        case .clearSearch: return .clearSearch
        }
    }
    
    func reduce(state: inout State, action: Action) -> [AsyncEffect<Action, CancelID>] {
        switch action {
        case .searchTextChanged(let text):
            state.searchText = text
            guard !text.isEmpty else { return [.cancel(id: .search)] }
            return [
                .debounce(id: .search, duration: 0.5) {
                    return .search(text)
                }
            ]
            
        case .search(let query):
            state.isSearching = true
            return [
                .run(id: .search) {
                    // API 호출 시뮬레이션
                    try await Task.sleep(nanoseconds: 500_000_000)
                    let results = ["Result 1", "Result 2", "Result 3"]
                    return .action(.searchCompleted(results))
                }
            ]
            
        case .searchCompleted(let results):
            state.results = results
            state.isSearching = false
            return []
            
        case .clearSearch:
            state.searchText = ""
            state.results = []
            state.isSearching = false
            return [.cancel(id: .search)]
        }
    }
}

// 테스트
@Suite("검색 기능 테스트")
struct SearchViewModelTests {
    
    @Test("검색어 입력 시 디바운스 적용")
    func testSearchDebounce() async throws {
        let viewModel = SearchViewModel()
        let store = AsyncTestStore(viewModel: viewModel)
        defer { store.cleanup() }
        
        // 검색어 입력
        store.send(.searchTextChanged("Swift"))
        #expect(store.state.searchText == "Swift")
        
        // 디바운스 시간 전 (검색 시작 안됨)
        await store.testTimer.tick(by: 0.3)
        #expect(store.state.isSearching == false)
        
        // 디바운스 시간 후 (검색 시작됨)
        await store.testTimer.tick(by: 0.3)
        await store.testTimer.run()
        
        try await store.wait(for: { $0.isSearching == true }, timeout: 1.0)
    }
    
    @Test("빠른 연속 입력 시 마지막 검색만 실행")
    func testRapidInput() async throws {
        let viewModel = SearchViewModel()
        let store = AsyncTestStore(viewModel: viewModel)
        defer { store.cleanup() }
        
        // 빠른 연속 입력
        store.send(.searchTextChanged("S"))
        await store.testTimer.tick(by: 0.1)
        
        store.send(.searchTextChanged("Sw"))
        await store.testTimer.tick(by: 0.1)
        
        store.send(.searchTextChanged("Swi"))
        await store.testTimer.tick(by: 0.1)
        
        store.send(.searchTextChanged("Swift"))
        
        // 디바운스 완료
        await store.testTimer.tick(by: 0.6)
        await store.testTimer.run()
        
        // "Swift"에 대한 검색만 실행되었는지 확인
        try await store.wait(for: { $0.isSearching == true }, timeout: 1.0)
        #expect(store.state.searchText == "Swift")
        
        // 검색 결과 대기
        try await store.wait(for: { !$0.results.isEmpty }, timeout: 2.0)
        #expect(store.state.results.count == 3)
    }
    
    @Test("검색 취소")
    func testClearSearch() async throws {
        let viewModel = SearchViewModel()
        let store = AsyncTestStore(viewModel: viewModel)
        defer { store.cleanup() }
        
        // 검색 시작
        store.send(.searchTextChanged("Swift"))
        await store.testTimer.tick(by: 0.6)
        await store.testTimer.run()
        
        try await store.wait(for: { $0.isSearching == true }, timeout: 1.0)
        
        // 검색 취소
        store.send(.clearSearch)
        
        // 상태 초기화 확인
        #expect(store.state.searchText == "")
        #expect(store.state.results.isEmpty)
        #expect(store.state.isSearching == false)
        
        // Task 취소 확인
        #expect(store.hasActiveTask(id: .search) == false)
    }
}
```

### 예제 2: 폼 검증 테스트

```swift
@AsyncViewModel
final class FormViewModel: ObservableObject {
    enum Input {
        case nameChanged(String)
        case emailChanged(String)
        case submit
    }
    
    enum Action: Equatable, Sendable {
        case nameChanged(String)
        case emailChanged(String)
        case validate
        case submit
        case submitSuccess
        case submitFailure(String)
    }
    
    struct State: Equatable, Sendable {
        var name: String = ""
        var email: String = ""
        var nameError: String?
        var emailError: String?
        var isValid: Bool = false
        var isSubmitting: Bool = false
    }
    
    enum CancelID: Hashable, Sendable {
        case validation
        case submit
    }
    
    @Published var state: State
    
    init(state: State = State()) {
        self.state = state
    }
    
    func transform(_ input: Input) -> Action {
        switch input {
        case .nameChanged(let name): return .nameChanged(name)
        case .emailChanged(let email): return .emailChanged(email)
        case .submit: return .submit
        }
    }
    
    func reduce(state: inout State, action: Action) -> [AsyncEffect<Action, CancelID>] {
        switch action {
        case .nameChanged(let name):
            state.name = name
            return [
                .debounce(id: .validation, duration: 0.3) {
                    return .validate
                }
            ]
            
        case .emailChanged(let email):
            state.email = email
            return [
                .debounce(id: .validation, duration: 0.3) {
                    return .validate
                }
            ]
            
        case .validate:
            // 검증 로직
            state.nameError = state.name.isEmpty ? "이름을 입력하세요" : nil
            state.emailError = state.email.contains("@") ? nil : "유효한 이메일을 입력하세요"
            state.isValid = state.nameError == nil && state.emailError == nil
            return []
            
        case .submit:
            guard state.isValid else { return [] }
            state.isSubmitting = true
            return [
                .run(id: .submit) {
                    try await Task.sleep(nanoseconds: 1_000_000_000)
                    return .action(.submitSuccess)
                }
            ]
            
        case .submitSuccess:
            state.isSubmitting = false
            return []
            
        case .submitFailure(let error):
            state.isSubmitting = false
            return []
        }
    }
}

// 테스트
@Suite("폼 검증 테스트")
struct FormViewModelTests {
    
    @Test("이름 검증")
    func testNameValidation() async throws {
        let viewModel = FormViewModel()
        let store = AsyncTestStore(viewModel: viewModel)
        let tracker = StateHistoryTracker<FormViewModel.State>()
        defer { store.cleanup() }
        
        viewModel.stateChangeObserver = { old, new in
            tracker.record(old: old, new: new)
        }
        
        // 빈 이름
        store.send(.nameChanged(""))
        await store.testTimer.tick(by: 0.4)
        await store.testTimer.run()
        
        #expect(store.state.nameError == "이름을 입력하세요")
        #expect(store.state.isValid == false)
        
        // 유효한 이름
        store.send(.nameChanged("John"))
        await store.testTimer.tick(by: 0.4)
        await store.testTimer.run()
        
        #expect(store.state.nameError == nil)
        #expect(store.state.name == "John")
    }
    
    @Test("이메일 검증")
    func testEmailValidation() async throws {
        let viewModel = FormViewModel()
        let store = AsyncTestStore(viewModel: viewModel)
        defer { store.cleanup() }
        
        // 유효하지 않은 이메일
        store.send(.emailChanged("invalid"))
        await store.testTimer.tick(by: 0.4)
        await store.testTimer.run()
        
        #expect(store.state.emailError == "유효한 이메일을 입력하세요")
        
        // 유효한 이메일
        store.send(.emailChanged("john@example.com"))
        await store.testTimer.tick(by: 0.4)
        await store.testTimer.run()
        
        #expect(store.state.emailError == nil)
    }
    
    @Test("폼 제출")
    func testFormSubmit() async throws {
        let viewModel = FormViewModel()
        let store = AsyncTestStore(viewModel: viewModel)
        defer { store.cleanup() }
        
        // 유효한 데이터 입력
        store.send(.nameChanged("John"))
        store.send(.emailChanged("john@example.com"))
        
        await store.testTimer.tick(by: 0.4)
        await store.testTimer.run()
        
        #expect(store.state.isValid == true)
        
        // 제출
        store.send(.submit)
        #expect(store.state.isSubmitting == true)
        
        // 제출 완료 대기
        try await store.wait(for: { $0.isSubmitting == false }, timeout: 2.0)
        
        // 제출 성공 액션 확인
        let hasSubmitSuccess = store.actions.contains { action in
            if case .submitSuccess = action { return true }
            return false
        }
        #expect(hasSubmitSuccess == true)
    }
}
```

---

## 베스트 프랙티스

### 1. 항상 cleanup() 호출

```swift
@Test
func testExample() async throws {
    let store = AsyncTestStore(viewModel: viewModel)
    defer { store.cleanup() }  // ✅ 필수!
    
    // 테스트 로직...
}
```

### 2. 적절한 타임아웃 설정

```swift
// ❌ 너무 짧은 타임아웃
try await store.wait(for: { $0.isLoaded }, timeout: 0.1)

// ✅ 적절한 타임아웃
try await store.wait(for: { $0.isLoaded }, timeout: 3.0)
```

### 3. StateHistoryTracker로 상태 전이 검증

```swift
@Test
func testStateTransitions() async throws {
    let tracker = StateHistoryTracker<MyState>()
    viewModel.stateChangeObserver = { old, new in
        tracker.record(old: old, new: new)
    }
    
    // 테스트 로직...
    
    // 상태 전이 패턴 검증
    #expect(tracker.count >= 2)
    // 각 전이 검증...
}
```

### 4. TestTimer로 시간 기반 로직 테스트

```swift
@Test
func testDebounce() async throws {
    let store = AsyncTestStore(viewModel: viewModel)
    
    store.send(.input("text"))
    
    // ✅ 가상 시간 사용
    await store.testTimer.tick(by: 0.5)
    await store.testTimer.run()
    
    // ❌ 실제 시간 대기 (느림)
    // try await Task.sleep(nanoseconds: 500_000_000)
}
```

### 5. Task 관리 검증

```swift
@Test
func testTaskLifecycle() async throws {
    let store = AsyncTestStore(viewModel: viewModel)
    
    // Task 시작
    store.send(.startTask)
    #expect(store.hasActiveTask(id: .myTask) == true)
    
    // Task 완료 대기
    try await store.waitForTaskCompletion(id: .myTask, timeout: 5.0)
    #expect(store.hasActiveTask(id: .myTask) == false)
}
```

### 6. 액션 시퀀스 검증

```swift
@Test
func testActionSequence() async throws {
    let store = AsyncTestStore(viewModel: viewModel)
    
    store.send(.complexOperation)
    
    // 특정 액션 순서 대기
    try await store.waitForActions(
        [.step1, .step2, .step3],
        timeout: 3.0
    )
    
    // 액션 순서 검증
    #expect(store.actions == [.complexOperation, .step1, .step2, .step3])
}
```

---

## 문제 해결

### 1. "Timeout waiting for state" 에러

**원인**: 상태가 예상한 값으로 변경되지 않음

**해결**:
```swift
// 디버깅: 현재 상태 출력
print("Current state: \(store.state)")

// 조건 완화
try await store.wait(for: { state in
    print("Checking state: \(state)")  // 상태 변경 추적
    return state.isLoaded == true
}, timeout: 5.0)
```

### 2. Task가 취소되지 않음

**원인**: Task ID가 일치하지 않거나 cancel Effect가 실행되지 않음

**해결**:
```swift
// Task ID 확인
print("Active tasks: \(store.activeTaskIDs)")

// 취소 액션이 실행되었는지 확인
#expect(store.actions.contains { action in
    if case .cancel = action { return true }
    return false
})
```

### 3. StateHistoryTracker가 변경사항을 기록하지 않음

**원인**: `stateChangeObserver` 연결 누락

**해결**:
```swift
// ✅ Observer 연결
viewModel.stateChangeObserver = { old, new in
    tracker.record(old: old, new: new)
}

// ❌ 연결 누락
// let tracker = StateHistoryTracker<MyState>()
```

---

## 추가 리소스

- [AsyncViewModel 기본 가이드](../README.md)
- [Effect 가이드](../README.md#effect-가이드)
- [로깅 설정 가이드](./02-Logger-Configuration.md)
- [AsyncTimer 가이드](./05-AsyncTimer-And-Lifecycle-Guide.md)
