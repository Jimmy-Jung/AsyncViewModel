# AsyncViewModel

![Swift](https://img.shields.io/badge/Swift-5.7-orange.svg)
![Platform](https://img.shields.io/badge/platform-iOS%20%7C%20macOS%20%7C%20watchOS%20%7C%20tvOS-lightgrey.svg)
![License](https://img.shields.io/badge/License-MIT-blue.svg)

`AsyncViewModel`은 Swift의 현대적인 동시성 모델(`async/await`)을 활용하여 예측 가능하고 테스트하기 쉬운 단방향 데이터 흐름 아키텍처를 구축하기 위한 마이크로 프레임워크입니다. The Composable Architecture (TCA)에서 영감을 받았지만, 더 가볍고 SwiftUI에 특화된 기능을 중심으로 설계되었습니다.

## 핵심 철학

-   **단방향 데이터 흐름**: 상태는 오직 `Action`에 대한 응답으로만 변경될 수 있습니다. (Input → Action → Reduce → State)
-   **예측 가능한 상태 변경**: `reduce` 함수는 순수 함수로, 현재 상태와 액션을 받아 새로운 상태를 반환합니다.
-   **명시적인 부수 효과(Side Effects)**: 네트워크 요청, 데이터베이스 접근과 같은 부수 효과는 `AsyncEffect` 타입으로 명시적으로 반환되어 관리됩니다.
-   **테스트 용이성**: 모든 로직은 테스트하기 쉽게 구성되어 있으며, `AsyncTestStore`를 통해 상태 변경을 쉽게 검증할 수 있습니다.

## 주요 개념

### `AsyncViewModel` 프로토콜

`AsyncViewModel`을 준수하는 모든 ViewModel은 다음 구성 요소를 가집니다.

-   `State`: 화면에 표시될 데이터를 담는 구조체. `Equatable`과 `Sendable`을 준수해야 합니다.
-   `Input`: 사용자 상호작용이나 외부 이벤트를 나타내는 열거형. `Sendable`을 준수합니다.
-   `Action`: 상태 변경을 유발하는 구체적인 행위. `Equatable`과 `Sendable`을 준수합니다.

### 데이터 흐름

1.  **`send(_ input: Input)`**: View에서 사용자 입력이 발생하면 이 메서드를 호출합니다.
2.  **`transform(_ input: Input) -> [Action]`**: `send` 내부에서 호출되며, 동기적으로 `Input`을 하나 이상의 `Action`으로 변환합니다.
3.  **`perform(_ action: Action)`**: `Action`을 받아 `reduce`를 호출하고 반환된 `Effect`를 처리합니다.
4.  **`reduce(state: &State, action: Action) -> [AsyncEffect<Action>]`**: 순수 함수로서, 현재 `state`와 `action`을 기반으로 `state`를 직접 변경하고, 실행할 `AsyncEffect` 배열을 반환합니다.
5.  **Effect 실행**: `reduce`에서 반환된 `Effect`는 ViewModel에 의해 비동기적으로 실행됩니다.

## Effect 처리

`AsyncEffect`는 비동기 작업을 관리하는 강력한 방법을 제공합니다.

-   `.run`: 비동기 작업을 실행합니다. `id`를 부여하여 작업을 식별하고 취소할 수 있습니다.
    ```swift
    // 1초 후에 랜덤 숫자를 생성하는 Action을 발생시키는 Effect
    .runAction(id: "fetch-number") {
        try await Task.sleep(nanoseconds: 1_000_000_000)
        return .setNumber(Int.random(in: 1...100))
    }
    ```
-   `.cancel(id:)`: 특정 `id`를 가진 진행 중인 작업을 취소합니다.
-   `.merge`: 여러 Effect를 **직렬**로 실행합니다. 순서가 중요한 작업에 사용됩니다.
-   `.concurrent`: 여러 Effect를 **병렬**로 실행합니다. 서로 독립적인 작업에 사용됩니다.

> **중요**: 화면 전환 시나 다른 이유로 작업을 중단해야 할 때를 대비하여, 오래 실행되는 비동기 작업에는 항상 고유한 `id`를 부여하고, 적절한 시점에 `.cancel(id:)`를 호출하는 것이 좋습니다.

## 에러 처리

-   `SendableError`: 비동기 작업 중 발생한 에러는 `SendableError`로 래핑되어 `handleError` 메서드로 전달됩니다. 이 구조체는 원본 에러의 `localizedDescription`, `code`, `domain` 등의 정보를 보존합니다.
-   `handleError(_ error: SendableError)`: ViewModel에서 이 메서드를 오버라이드하여 사용자에게 에러를 알리거나, 로깅하는 등의 커스텀 에러 처리를 구현할 수 있습니다.

## 테스트

`AsyncTestStore`는 ViewModel의 로직을 테스트하기 위한 헬퍼 클래스입니다.

-   `send(_ input: Input)`: ViewModel에 입력을 보내고, 상태 변경이 발생했음을 알리는 `Combine` `Publisher`를 반환합니다.
-   `XCTestExpectation`과 함께 사용하여 비동기적인 상태 변경을 안정적으로 테스트할 수 있습니다.

```swift
// AsyncViewModelExampleTests.swift

@MainActor
final class AsyncViewModelExampleTests: XCTestCase {
    var store: AsyncTestStore<ContentViewModel>!
    private var cancellables: Set<AnyCancellable> = []

    override func setUp() {
        super.setUp()
        let viewModel = ContentViewModel()
        store = AsyncTestStore(viewModel: viewModel)
    }

    func test_incrementAction_incrementsCount() {
        // Given
        let expectation = XCTestExpectation(description: "Increment count")
        let initialCount = store.state.count

        // When
        store.send(.incrementButtonTapped)
            .sink {
                // Then
                XCTAssertEqual(self.store.state.count, initialCount + 1)
                expectation.fulfill()
            }
            .store(in: &cancellables)
        
        wait(for: [expectation], timeout: 1.0)
    }
}
```

## 예제

다음은 간단한 카운터 앱의 `ContentViewModel` 예제입니다.

```swift
// ContentView.swift

import SwiftUI
import AsyncViewModel

@MainActor
final class ContentViewModel: AsyncViewModel {
    
    // MARK: - State & Properties
    struct State: Equatable, Sendable {
        var count = 0
        var isLoading = false
    }
    @Published private(set) var state: State
    var tasks: [AnyHashable: Task<Void, Never>] = [:]
    var effectQueue: [AsyncEffect<Action>] = []
    var isProcessingEffects: Bool = false
    
    // MARK: - Initialization & Input
    init(initialState: State = .init()) { self.state = initialState }
    enum Input: Sendable { /* ... */ }
    func send(_ input: Input) { /* ... */ }
    
    // MARK: - Action & transform
    enum Action: Equatable, Sendable { /* ... */ }
    func transform(_ input: Input) -> [Action] { /* ... */ }
    
    // MARK: - reduce
    func reduce(state: inout State, action: Action) -> [AsyncEffect<Action>] {
        switch action {
        case .increment:
            state.count += 1
            return []
        case .decrement:
            state.count -= 1
            return []
        case .setLoading(let isLoading):
            state.isLoading = isLoading
            if isLoading {
                return [.runAction(id: CancelID.fetch, operation: {
                    try await Task.sleep(nanoseconds: 1_000_000_000)
                    return .setNumber(Int.random(in: 1...100))
                })]
            }
            return []
        case .setNumber(let number):
            state.count = number
            state.isLoading = false
            return []
        }
    }
    
    // MARK: - CancelID
    enum CancelID: Hashable, Sendable {
        case fetch
    }
}
```

## 라이선스

`AsyncViewModel`은 MIT 라이선스에 따라 제공됩니다. 자세한 내용은 `LICENSE` 파일을 참고하세요.
