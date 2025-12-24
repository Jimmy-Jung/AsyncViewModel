//
//  AsyncViewModelTests.swift
//  AsyncViewModel
//
//  Created by 정준영 on 2025/8/3.
//

@testable import AsyncViewModelCore
import Foundation
import Testing

@MainActor
struct AsyncViewModelTests {
    // MARK: - Mock ViewModel Definition

    /// 테스트를 위한 `AsyncViewModelProtocol`의 구체적인 구현체
    final class MockViewModel: AsyncViewModelProtocol, ObservableObject {
        // MARK: - Associated Types

        enum Input: Sendable {
            case setValue(Int)
            case triggerActionEffect
            case triggerAsyncEffect(shouldSucceed: Bool)
            case triggerLongRunningTask(duration: UInt64)
            case cancelLongRunningTask
            case triggerMergedEffects
            case triggerRestartableTask(value: String)
            case triggerConcurrentEffects
            case triggerMultipleActions
            case triggerActionChainingEffect
            case triggerNestedActionChainingEffect
        }

        enum Action: Equatable, Sendable {
            case setValue(Int)
            case subsequentAction
            case asyncTaskCompleted(String)
            case asyncTaskFailed(SendableError)
            case longRunningTaskStarted(duration: UInt64)
            case longRunningTaskFinished
            case cancelLongRunningTask
            case restartableTaskCompleted(String)
            case concurrentTaskCompleted(String)
            case triggerRestartableTask(value: String)
            case actionChainingTrigger
            case actionChainingFirstAction
            case actionChainingSecondAction
            case nestedActionChainingTrigger
            case nestedFirstAction
            case nestedSecondAction
            case nestedThirdAction
        }

        struct State: Equatable, Sendable {
            var currentValue: Int = 0
            var asyncResult: String?
            var lastError: String?
            var isLongTaskRunning: Bool = false
            var restartableTaskResult: String?
            var concurrentResults: [String] = []
            var actionChainingResult: String?
            var nestedActionChainingResults: [String] = []
        }

        enum CancelID: Hashable, Sendable {
            case longRunningTask
            case restartableTask
        }

        // MARK: - Properties

        @Published var state: State
        var tasks: [CancelID: Task<Void, Never>] = [:]
        var effectQueue: [AsyncEffect<Action, CancelID>] = []
        var isProcessingEffects: Bool = false
        var timer: any AsyncTimer = SystemTimer()
        var actionObserver: ((Action) -> Void)?

        var stateChangeObserver: ((State, State) -> Void)?
        var effectObserver: ((AsyncEffect<Action, CancelID>) -> Void)?
        var performanceObserver: ((String, TimeInterval) -> Void)?

        var handleErrorCallCount = 0
        var receivedError: SendableError?

        init(initialState: State = .init()) {
            state = initialState
        }

        // MARK: - Transform

        func transform(_ input: Input) -> [Action] {
            switch input {
            case let .setValue(value):
                return [.setValue(value)]
            case .triggerActionEffect:
                return [.setValue(100)]
            case let .triggerAsyncEffect(shouldSucceed):
                if shouldSucceed {
                    return [.setValue(200)]
                } else {
                    return [.setValue(300)]
                }
            case let .triggerLongRunningTask(duration):
                return [.longRunningTaskStarted(duration: duration)]
            case .cancelLongRunningTask:
                return [.cancelLongRunningTask]
            case .triggerMergedEffects:
                return [.setValue(400)]
            case let .triggerRestartableTask(value):
                return [.triggerRestartableTask(value: value)]
            case .triggerConcurrentEffects:
                return [.setValue(500)]
            case .triggerMultipleActions:
                return [.setValue(1), .subsequentAction]
            case .triggerActionChainingEffect:
                return [.actionChainingTrigger]
            case .triggerNestedActionChainingEffect:
                return [.nestedActionChainingTrigger]
            }
        }

        // MARK: - Reduce

        func reduce(state: inout State, action: Action) -> [AsyncEffect<Action, CancelID>] {
            switch action {
            case let .setValue(value):
                state.currentValue = value
                if value == 100 { return [.action(.subsequentAction)] }
                if value == 200 { return [.run { .asyncTaskCompleted("Success") }] }
                if value == 300 { return [.run(id: CancelID.longRunningTask) { throw MockError.simulatedFailure }] }
                if value == 400 { return [.action(.subsequentAction), .run { .asyncTaskCompleted("Sequential Success") }] }
                if value == 500 {
                    return [.concurrent(
                        .run {
                            try await Task.sleep(nanoseconds: 200_000_000) // 0.2초
                            return .concurrentTaskCompleted("A")
                        },
                        .run {
                            try await Task.sleep(nanoseconds: 100_000_000) // 0.1초
                            return .concurrentTaskCompleted("B")
                        }
                    )]
                }
                return [.none]

            case .subsequentAction:
                state.currentValue = 999
                return [.none]

            case let .asyncTaskCompleted(result):
                state.asyncResult = result
                return [.none]

            case let .asyncTaskFailed(error):
                state.lastError = error.localizedDescription
                return [.none]

            case let .longRunningTaskStarted(duration):
                state.isLongTaskRunning = true
                return [.sleepThen(
                    id: CancelID.longRunningTask,
                    for: TimeInterval(duration) / 1_000_000_000, // nanoseconds를 초 단위로 변환
                    action: .longRunningTaskFinished
                )]

            case .longRunningTaskFinished:
                state.isLongTaskRunning = false
                return [.none]

            case .cancelLongRunningTask:
                return [.cancel(id: CancelID.longRunningTask)]

            case let .restartableTaskCompleted(value):
                state.restartableTaskResult = value
                return [.none]

            case let .concurrentTaskCompleted(value):
                state.concurrentResults.append(value)
                return [.none]

            case let .triggerRestartableTask(value):
                return [.sleepThen(
                    id: CancelID.restartableTask,
                    for: 1.0, // 1초
                    action: .restartableTaskCompleted(value)
                )]

            case .actionChainingTrigger:
                // .run 효과에서 두 개의 액션을 반환하여 액션 체이닝 테스트
                return [.run {
                    try await Task.sleep(nanoseconds: 100_000_000) // 0.1초
                    return .actionChainingFirstAction
                }]

            case .actionChainingFirstAction:
                state.actionChainingResult = "First"
                return [.action(.actionChainingSecondAction)]

            case .actionChainingSecondAction:
                state.actionChainingResult = "Second"
                return [.none]

            case .nestedActionChainingTrigger:
                // 중첩된 액션 체이닝 테스트
                return [.run {
                    try await Task.sleep(nanoseconds: 100_000_000) // 0.1초
                    return .nestedFirstAction
                }]

            case .nestedFirstAction:
                state.nestedActionChainingResults.append("First")
                return [.action(.nestedSecondAction)]

            case .nestedSecondAction:
                state.nestedActionChainingResults.append("Second")
                return [.action(.nestedThirdAction)]

            case .nestedThirdAction:
                state.nestedActionChainingResults.append("Third")
                return [.none]
            }
        }

        func handleError(_ error: SendableError) {
            handleErrorCallCount += 1
            receivedError = error
            perform(.asyncTaskFailed(error))
        }
    }

    enum MockError: Error, LocalizedError, Sendable {
        case simulatedFailure
        var errorDescription: String? { "Simulated Failure" }
    }

    // MARK: - Test Cases

    @Test("send 호출 시 state가 동기적으로 변경되어야 한다")
    func send_updatesStateSynchronously() {
        // Given
        let viewModel = MockViewModel()
        let testStore = AsyncTestStore(viewModel: viewModel)

        // When
        testStore.send(MockViewModel.Input.setValue(10))

        // Then
        #expect(testStore.state.currentValue == 10)
    }

    @Test("Action Effect가 올바르게 처리되어야 한다")
    func actionEffect_triggersSubsequentAction() async throws {
        // Given
        let viewModel = MockViewModel()
        let testStore = AsyncTestStore(viewModel: viewModel)

        // When
        testStore.send(MockViewModel.Input.triggerActionEffect)

        // Then
        try await testStore.wait(for: { $0.currentValue == 999 })
        #expect(testStore.state.currentValue == 999)
    }

    @Test("성공적인 비동기 작업 후 state가 변경되어야 한다")
    func runEffect_succeedsAndUpdatesState() async throws {
        // Given
        let viewModel = MockViewModel()
        let testStore = AsyncTestStore(viewModel: viewModel)

        // When
        testStore.send(MockViewModel.Input.triggerAsyncEffect(shouldSucceed: true))

        // Then
        try await testStore.wait(for: { $0.asyncResult == "Success" })
        #expect(testStore.state.currentValue == 200)
        #expect(testStore.state.asyncResult == "Success")
    }

    @Test("실패하는 비동기 작업 시 handleError가 호출되어야 한다")
    func runEffect_failsAndCallsHandleError() async throws {
        // Given
        let viewModel = MockViewModel()
        let testStore = AsyncTestStore(viewModel: viewModel)

        // 초기 상태 확인
        #expect(viewModel.handleErrorCallCount == 0)
        #expect(viewModel.receivedError == nil)
        #expect(testStore.state.lastError == nil)

        // When
        testStore.send(MockViewModel.Input.triggerAsyncEffect(shouldSucceed: false))

        // Then
        // 동기적으로 state.currentValue가 300으로 변경됨
        #expect(testStore.state.currentValue == 300)

        // 비동기 작업이 실패하고 handleError가 호출될 때까지 기다림
        try await testStore.wait(for: { $0.lastError == "Simulated Failure" })

        // handleError가 호출되었는지 확인
        #expect(viewModel.handleErrorCallCount == 1)

        // 올바른 에러가 전달되었는지 확인
        #expect(viewModel.receivedError?.localizedDescription == "Simulated Failure")

        // state.lastError가 올바르게 설정되었는지 확인
        #expect(testStore.state.lastError == "Simulated Failure")
    }

    @Test("실행 중인 작업을 취소할 수 있어야 한다")
    func cancelEffect_cancelsRunningTask() async throws {
        // Given
        let viewModel = MockViewModel()
        let testStore = AsyncTestStore(viewModel: viewModel)

        // When
        testStore.send(MockViewModel.Input.triggerLongRunningTask(duration: 2_000_000_000))

        // Then
        // 상태가 변경되고 작업이 시작될 때까지 기다림
        try await testStore.wait(for: { $0.isLongTaskRunning == true })
        #expect(testStore.state.isLongTaskRunning == true)

        // 작업이 tasks 딕셔너리에 저장될 때까지 기다림
        try await testStore.wait(for: { _ in
            viewModel.tasks[MockViewModel.CancelID.longRunningTask] != nil
        }, timeout: 1.0)
        #expect(viewModel.tasks[MockViewModel.CancelID.longRunningTask] != nil)

        // When
        testStore.send(MockViewModel.Input.cancelLongRunningTask)

        // Then
        try await testStore.wait(for: { _ in viewModel.tasks[MockViewModel.CancelID.longRunningTask] == nil })
        #expect(viewModel.tasks[MockViewModel.CancelID.longRunningTask] == nil)
    }

    @Test("Merge Effect가 모든 내부 Effect를 실행해야 한다")
    func mergeEffect_executesAllEffects() async throws {
        // Given
        let viewModel = MockViewModel()
        let testStore = AsyncTestStore(viewModel: viewModel)

        // When
        testStore.send(MockViewModel.Input.triggerMergedEffects)

        // Then
        // setValue(400) → [.action(.subsequentAction), .run { .asyncTaskCompleted("Sequential Success") }]
        // .subsequentAction → currentValue = 999
        // .asyncTaskCompleted("Sequential Success") → asyncResult = "Sequential Success"
        try await testStore.wait(for: { $0.asyncResult == "Sequential Success" })
        #expect(testStore.state.currentValue == 999)
        #expect(testStore.state.asyncResult == "Sequential Success")
    }

    @Test("동일 ID로 재시작 시 이전 작업이 취소되어야 한다")
    func restartableTask_cancelsPreviousTask() async throws {
        // Given
        let viewModel = MockViewModel()
        let testStore = AsyncTestStore(viewModel: viewModel)

        // When
        // 첫 번째 작업을 시작 (1초 소요)
        testStore.send(.triggerRestartableTask(value: "first"))

        // 짧은 지연 후 두 번째 작업을 시작하여 이전 작업을 취소
        try await Task.sleep(nanoseconds: 100_000_000) // 0.1초
        testStore.send(.triggerRestartableTask(value: "second"))

        // Then
        // 두 번째 작업이 완료될 때까지 기다림 (최종 결과가 "second"가 될 때까지)
        try await testStore.wait(for: { $0.restartableTaskResult == "second" }, timeout: 2.0)

        // 최종 상태는 두 번째 작업의 결과여야 함
        #expect(testStore.state.restartableTaskResult == "second")

        // 작업 완료 후 tasks 딕셔너리는 비어있어야 함
        try await testStore.wait(for: { _ in viewModel.tasks[MockViewModel.CancelID.restartableTask] == nil })
        #expect(viewModel.tasks[MockViewModel.CancelID.restartableTask] == nil)
    }

    @Test("완료된 작업은 tasks 딕셔너리에서 자동 정리되어야 한다")
    func task_isRemovedFromDictionaryOnCompletion() async throws {
        // Given
        let viewModel = MockViewModel()
        let testStore = AsyncTestStore(viewModel: viewModel)
        let taskID = MockViewModel.CancelID.longRunningTask

        // When
        // 짧은 작업을 시작
        testStore.send(.triggerLongRunningTask(duration: 100_000_000)) // 0.1초

        // Then
        // 작업이 시작되고 tasks 딕셔너리에 등록될 때까지 기다림
        try await testStore.wait(for: { _ in viewModel.tasks[taskID] != nil })
        #expect(viewModel.tasks[taskID] != nil)

        // 작업이 완료되고 isLongTaskRunning이 false로 바뀔 때까지 기다림
        try await testStore.wait(for: { !$0.isLongTaskRunning }, timeout: 1.0)
        #expect(testStore.state.isLongTaskRunning == false)

        // 작업 완료 후 tasks 딕셔너리에서 해당 ID가 제거되었는지 확인
        try await testStore.wait(for: { _ in viewModel.tasks[taskID] == nil })
        #expect(viewModel.tasks[taskID] == nil)
    }

    @Test("작업 취소 시 후속 액션이 발행되지 않아야 한다")
    func cancel_shouldPreventSubsequentActions() async throws {
        // Given
        let viewModel = MockViewModel()
        let testStore = AsyncTestStore(viewModel: viewModel)

        // When
        // 긴 작업을 시작
        testStore.send(.triggerLongRunningTask(duration: 2_000_000_000)) // 2초

        // 작업이 시작되었는지 확인
        try await testStore.wait(for: { $0.isLongTaskRunning == true })
        #expect(testStore.state.isLongTaskRunning == true)

        // 즉시 작업을 취소
        testStore.send(.cancelLongRunningTask)

        // Then
        // tasks 딕셔너리에서 즉시 제거되는지 확인
        try await testStore.wait(for: { _ in viewModel.tasks[MockViewModel.CancelID.longRunningTask] == nil })
        #expect(viewModel.tasks[MockViewModel.CancelID.longRunningTask] == nil)

        // 작업의 원래 소요 시간(2초)보다 더 오래 기다림
        try await Task.sleep(nanoseconds: 2_500_000_000)

        // longRunningTaskFinished 액션이 호출되지 않았으므로, isLongTaskRunning 상태는 true로 유지되어야 함
        #expect(testStore.state.isLongTaskRunning == true)
    }

    @Test("Concurrent Effect가 모든 내부 Effect를 병렬로 실행해야 한다")
    func concurrentEffect_executesAllEffectsInParallel() async throws {
        // Given
        let viewModel = MockViewModel()
        let testStore = AsyncTestStore(viewModel: viewModel)

        // When
        testStore.send(.triggerConcurrentEffects)

        // Then
        // 두 작업이 모두 완료될 때까지 기다림 (결과가 2개가 될 때까지)
        try await testStore.wait(for: { $0.concurrentResults.count == 2 }, timeout: 1.0)

        // 순서에 관계없이 두 결과가 모두 포함되었는지 확인
        let expectedResults = Set(["A", "B"])
        let actualResults = Set(testStore.state.concurrentResults)
        #expect(actualResults == expectedResults)
    }

    @Test("transform이 여러 Action을 반환할 때 순차적으로 처리되어야 한다")
    func transform_shouldProcessMultipleActionsSequentially() async throws {
        // Given
        let viewModel = MockViewModel()
        let testStore = AsyncTestStore(viewModel: viewModel)

        // When
        testStore.send(.triggerMultipleActions)

        // Then
        // .setValue(1) -> .subsequentAction 순서로 실행되어 최종 값은 999가 되어야 함
        try await testStore.wait(for: { $0.currentValue == 999 }, timeout: 1.0)
        #expect(testStore.state.currentValue == 999)
    }

    // MARK: - Action Chaining Tests

    @Test(".run 효과에서 반환된 액션들이 즉시 처리되어야 한다")
    func runEffect_shouldProcessReturnedActionsImmediately() async throws {
        // Given
        let viewModel = MockViewModel()
        let testStore = AsyncTestStore(viewModel: viewModel)

        // When
        testStore.send(.triggerActionChainingEffect)

        // Then
        // .run 효과가 완료된 후 반환된 액션들이 순차적으로 처리되어야 함
        // actionChainingTrigger -> (0.1초 대기) -> actionChainingFirstAction -> actionChainingSecondAction
        try await testStore.wait(for: { $0.actionChainingResult == "Second" }, timeout: 1.0)
        #expect(testStore.state.actionChainingResult == "Second")
    }

    @Test("중첩된 액션 체이닝이 올바르게 처리되어야 한다")
    func nestedActionChaining_shouldProcessAllActionsInSequence() async throws {
        // Given
        let viewModel = MockViewModel()
        let testStore = AsyncTestStore(viewModel: viewModel)

        // When
        testStore.send(.triggerNestedActionChainingEffect)

        // Then
        // nestedActionChainingTrigger -> (0.1초 대기) -> nestedFirstAction -> nestedSecondAction -> nestedThirdAction
        try await testStore.wait(for: { $0.nestedActionChainingResults.count == 3 }, timeout: 1.0)

        let expectedResults = ["First", "Second", "Third"]
        #expect(testStore.state.nestedActionChainingResults == expectedResults)
    }

    @Test(".run 효과에서 반환된 액션이 다른 .run 효과를 생성할 때도 즉시 처리되어야 한다")
    func runEffect_returningActionWithRunEffect_shouldProcessImmediately() async throws {
        // Given
        let viewModel = MockViewModel()
        let testStore = AsyncTestStore(viewModel: viewModel)

        // When
        testStore.send(.triggerActionEffect) // setValue(100) -> subsequentAction(999)

        // Then
        // setValue(100)이 실행되면 .action(.subsequentAction)이 반환되고
        // subsequentAction이 실행되어 currentValue가 999가 되어야 함
        try await testStore.wait(for: { $0.currentValue == 999 }, timeout: 1.0)
        #expect(testStore.state.currentValue == 999)
    }

    @Test(".run 효과에서 실패한 후 반환된 액션들이 처리되어야 한다")
    func runEffect_failureThenReturnedActions_shouldProcessImmediately() async throws {
        // Given
        let viewModel = MockViewModel()
        let testStore = AsyncTestStore(viewModel: viewModel)

        // When
        testStore.send(.triggerAsyncEffect(shouldSucceed: false)) // setValue(300) -> 실패하는 .run 효과

        // Then
        // setValue(300)이 실행되어 currentValue가 300이 되고
        // .run 효과가 실패하여 handleError가 호출되어야 함
        #expect(testStore.state.currentValue == 300)

        // 비동기 작업이 실패하고 handleError가 호출될 때까지 기다림
        try await testStore.wait(for: { $0.lastError == "Simulated Failure" }, timeout: 1.0)
        #expect(viewModel.handleErrorCallCount == 1)
        #expect(testStore.state.lastError == "Simulated Failure")
    }

    @Test("효과 큐에 추가된 액션들이 현재 처리 루프가 아닐 때 즉시 처리되어야 한다")
    func effectQueue_addedActionsWhenNotProcessing_shouldProcessImmediately() async throws {
        // Given
        let viewModel = MockViewModel()
        let testStore = AsyncTestStore(viewModel: viewModel)

        // When
        testStore.send(.triggerActionChainingEffect)

        // Then
        // .run 효과가 비동기로 실행되면서 새로 추가된 효과들이
        // 현재 처리 루프가 끝난 후에도 즉시 처리되어야 함
        try await testStore.wait(for: { $0.actionChainingResult == "Second" }, timeout: 1.0)
        #expect(testStore.state.actionChainingResult == "Second")
    }

    @Test("여러 .run 효과가 동시에 완료될 때 각각의 반환된 액션들이 처리되어야 한다")
    func multipleRunEffects_completingSimultaneously_shouldProcessAllReturnedActions() async throws {
        // Given
        let viewModel = MockViewModel()
        let testStore = AsyncTestStore(viewModel: viewModel)

        // When
        testStore.send(.triggerConcurrentEffects) // setValue(500) -> 두 개의 동시 .run 효과

        // Then
        // 두 개의 .run 효과가 병렬로 실행되고 각각 concurrentTaskCompleted 액션을 반환
        // 두 액션이 모두 처리되어 concurrentResults에 "A", "B"가 추가되어야 함
        try await testStore.wait(for: { $0.concurrentResults.count == 2 }, timeout: 1.0)

        let expectedResults = Set(["A", "B"])
        let actualResults = Set(testStore.state.concurrentResults)
        #expect(actualResults == expectedResults)
    }
}
