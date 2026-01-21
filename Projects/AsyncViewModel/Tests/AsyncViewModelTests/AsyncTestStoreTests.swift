//
//  AsyncTestStoreTests.swift
//  AsyncViewModelTests
//
//  Created by 정준영 on 2025/8/15.
//

// swiftlint:disable main_actor_usage

@testable import AsyncViewModelCore
import Foundation
import Testing

@MainActor
struct AsyncTestStoreTests {
    // AsyncViewModelTests에 정의된 MockViewModel을 재사용
    typealias MockViewModel = AsyncViewModelTests.MockViewModel

    @Test("send는 입력을 전달하고 상태를 변경한다")
    func send_deliversInputAndChangesState() {
        // Given
        let viewModel = MockViewModel()
        let testStore = AsyncTestStore(viewModel: viewModel)

        // When
        testStore.send(.setValue(10))

        // Then
        #expect(testStore.state.currentValue == 10)
        // send를 통한 액션도 자동으로 기록됨 (개선된 기능)
        #expect(testStore.actions == [.setValue(10)])
    }

    @Test("perform은 액션을 전달하고 상태를 변경하며, actions 배열에 기록된다")
    func perform_deliversActionAndRecordsIt() {
        // Given
        let viewModel = MockViewModel()
        let testStore = AsyncTestStore(viewModel: viewModel)

        // When
        testStore.perform(.setValue(20))

        // Then
        #expect(testStore.state.currentValue == 20)
        #expect(testStore.actions == [.setValue(20)])
    }

    @Test("state 프로퍼티는 viewModel의 현재 상태를 올바르게 반환한다")
    func state_reflectsCurrentViewModelState() {
        // Given
        let viewModel = MockViewModel()
        let testStore = AsyncTestStore(viewModel: viewModel)

        // When
        viewModel.state.currentValue = 55

        // Then
        #expect(testStore.state.currentValue == 55)
    }

    @Test("wait(for:)는 조건이 충족되면 즉시 반환된다")
    func waitFor_returnsWhenPredicateIsMet() async throws {
        // Given
        let viewModel = MockViewModel()
        let testStore = AsyncTestStore(viewModel: viewModel)

        // When
        testStore.send(.setValue(10))

        // Then
        try await testStore.wait(for: { $0.currentValue == 10 }, timeout: 0.1)
        #expect(testStore.state.currentValue == 10)
    }

    @Test("wait(for:)는 타임아웃 시 에러를 던진다")
    func waitFor_throwsTimeoutError() async {
        // Given
        let viewModel = MockViewModel()
        let testStore = AsyncTestStore(viewModel: viewModel)

        // Then
        do {
            try await testStore.wait(for: { $0.currentValue == 10 }, timeout: 0.1)
            Issue.record("Expected timeout error to be thrown")
        } catch let error as AsyncTestStore<MockViewModel>.TestError {
            if case .timeout = error {
                // Expected
            } else {
                Issue.record("Expected timeout error, got: \(error)")
            }
        } catch {
            Issue.record("Unexpected error: \(error)")
        }
    }

    @Test("비동기 작업 후 wait(for:)가 상태 변경을 감지한다")
    func waitFor_detectsStateChangeAfterAsyncEffect() async throws {
        // Given
        let viewModel = MockViewModel()
        let testStore = AsyncTestStore(viewModel: viewModel)

        // When
        // "Success" 문자열이 설정될 때까지 1초가 걸리는 비동기 작업
        testStore.send(.triggerAsyncEffect(shouldSucceed: true))

        // Then
        // 비동기 작업이 완료되고 상태가 변경될 때까지 기다림
        try await testStore.wait(for: { $0.asyncResult == "Success" }, timeout: 2.0)
        #expect(testStore.state.asyncResult == "Success")
    }

    // MARK: - Task Management Tests

    @Test("hasActiveTask는 활성 작업이 있을 때 true를 반환한다")
    func hasActiveTask_returnsTrueWhenTaskIsActive() async throws {
        // Given
        let viewModel = MockViewModel()
        let testStore = AsyncTestStore(viewModel: viewModel)

        // When
        testStore.send(.triggerLongRunningTask(duration: 1_000_000_000))

        // Effect가 등록될 때까지 짧게 대기
        try await Task.sleep(nanoseconds: 10_000_000)

        // Then
        #expect(testStore.hasActiveTask(id: .longRunningTask) == true)
        #expect(testStore.activeTaskIDs.contains(.longRunningTask))
        #expect(testStore.activeTaskCount == 1)

        // Cleanup
        testStore.send(.cancelLongRunningTask)
    }

    @Test("hasActiveTask는 작업이 취소되면 false를 반환한다")
    func hasActiveTask_returnsFalseAfterCancellation() async throws {
        // Given
        let viewModel = MockViewModel()
        let testStore = AsyncTestStore(viewModel: viewModel)

        testStore.send(.triggerLongRunningTask(duration: 1_000_000_000))
        try await Task.sleep(nanoseconds: 10_000_000)
        #expect(testStore.hasActiveTask(id: .longRunningTask) == true)

        // When
        testStore.send(.cancelLongRunningTask)
        try await Task.sleep(nanoseconds: 10_000_000)

        // Then
        #expect(testStore.hasActiveTask(id: .longRunningTask) == false)
        #expect(testStore.activeTaskCount == 0)
    }

    // MARK: - waitForAction Tests

    @Test("waitForAction은 특정 Action이 발생할 때까지 대기한다")
    func waitForAction_waitsUntilActionIsReceived() async throws {
        // Given
        let viewModel = MockViewModel()
        let testStore = AsyncTestStore(viewModel: viewModel)

        // When
        testStore.send(.triggerAsyncEffect(shouldSucceed: true))

        // Then
        try await testStore.waitForAction(.asyncTaskCompleted("Success"), timeout: 2.0)
        #expect(testStore.state.asyncResult == "Success")
    }

    @Test("waitForAction은 타임아웃 시 actionNotReceived 에러를 던진다")
    func waitForAction_throwsActionNotReceivedOnTimeout() async {
        // Given
        let viewModel = MockViewModel()
        let testStore = AsyncTestStore(viewModel: viewModel)

        // Then
        do {
            try await testStore.waitForAction(.asyncTaskCompleted("Never"), timeout: 0.1)
            Issue.record("Expected actionNotReceived error")
        } catch let error as AsyncTestStore<MockViewModel>.TestError {
            if case .actionNotReceived = error {
                // Expected
            } else {
                Issue.record("Expected actionNotReceived error, got: \(error)")
            }
        } catch {
            Issue.record("Unexpected error: \(error)")
        }
    }

    @Test("waitForAction에서 상태 검증 클로저가 호출된다")
    func waitForAction_callsAssertClosure() async throws {
        // Given
        let viewModel = MockViewModel()
        let testStore = AsyncTestStore(viewModel: viewModel)
        var assertCalled = false

        // When
        testStore.send(.triggerAsyncEffect(shouldSucceed: true))

        try await testStore.waitForAction(.asyncTaskCompleted("Success"), timeout: 2.0) { state in
            assertCalled = true
            #expect(state.asyncResult == "Success")
        }

        // Then
        #expect(assertCalled == true)
    }

    // MARK: - receive Tests

    @Test("receive는 TCA 스타일로 Action을 검증한다")
    func receive_verifiesActionTCAStyle() async throws {
        // Given
        let viewModel = MockViewModel()
        let testStore = AsyncTestStore(viewModel: viewModel)

        // When
        testStore.send(.triggerAsyncEffect(shouldSucceed: true))

        // Then - TCA 스타일 체이닝
        try await testStore.receive(.asyncTaskCompleted("Success")) { state in
            #expect(state.asyncResult == "Success")
        }
    }

    // MARK: - tickAndWait Tests

    @Test("tickAndWait는 가상 시간을 진행하고 조건을 검증한다")
    func tickAndWait_advancesTimeAndWaitsForCondition() async throws {
        // Given
        let viewModel = MockViewModel()
        let testStore = AsyncTestStore(viewModel: viewModel)

        // When
        testStore.send(.triggerLongRunningTask(duration: 100_000_000)) // 0.1초

        // Effect가 등록될 때까지 대기
        try await testStore.waitUntilTaskStarts(id: MockViewModel.CancelID.longRunningTask)

        // Then
        try await testStore.tickAndWait(by: 0.1, for: { !$0.isLongTaskRunning })
        #expect(testStore.state.isLongTaskRunning == false)
    }

    @Test("tickAndWaitForAction은 가상 시간을 진행하고 Action을 검증한다")
    func tickAndWaitForAction_advancesTimeAndWaitsForAction() async throws {
        // Given
        let viewModel = MockViewModel()
        let testStore = AsyncTestStore(viewModel: viewModel)

        // When
        testStore.send(.triggerRestartableTask(value: "test"))

        // Effect가 등록될 때까지 대기
        try await testStore.waitUntilTaskStarts(id: MockViewModel.CancelID.restartableTask)

        // Then
        try await testStore.tickAndWaitForAction(by: 1.0, action: .restartableTaskCompleted("test"))
        #expect(testStore.state.restartableTaskResult == "test")
    }

    // MARK: - assert Tests

    @Test("assert는 현재 상태를 검증한다")
    func assert_verifiesCurrentState() {
        // Given
        let viewModel = MockViewModel()
        let testStore = AsyncTestStore(viewModel: viewModel)

        // When
        testStore.send(.setValue(42))

        // Then - 체이닝 가능
        testStore.assert { state in
            #expect(state.currentValue == 42)
        }
    }

    @Test("assertActions는 발생한 Action들을 검증한다")
    func assertActions_verifiesReceivedActions() async throws {
        // Given
        let viewModel = MockViewModel()
        let testStore = AsyncTestStore(viewModel: viewModel)

        // When
        testStore.send(.triggerActionEffect)
        try await testStore.wait(for: { $0.currentValue == 999 })

        // Then
        testStore.assertActions { actions in
            #expect(actions.contains(.setValue(100)))
            #expect(actions.contains(.subsequentAction))
        }
    }

    // MARK: - skipReceivedActions Tests

    @Test("skipReceivedActions는 지정된 개수만큼 Action을 제거한다")
    func skipReceivedActions_removesSpecifiedCount() {
        // Given
        let viewModel = MockViewModel()
        let testStore = AsyncTestStore(viewModel: viewModel)

        testStore.send(.setValue(1))
        testStore.send(.setValue(2))
        testStore.send(.setValue(3))

        #expect(testStore.actions.count == 3)

        // When
        testStore.skipReceivedActions(count: 2)

        // Then
        #expect(testStore.actions.count == 1)
        #expect(testStore.actions.first == .setValue(3))
    }

    @Test("skipUntilAction은 특정 Action까지 스킵한다")
    func skipUntilAction_skipsUntilSpecifiedAction() async throws {
        // Given
        let viewModel = MockViewModel()
        let testStore = AsyncTestStore(viewModel: viewModel)

        testStore.send(.triggerActionEffect) // setValue(100) -> subsequentAction
        try await testStore.wait(for: { $0.currentValue == 999 })

        // Actions: [.setValue(100), .subsequentAction]
        #expect(testStore.actions.count == 2)

        // When
        try await testStore.skipUntilAction(.subsequentAction)

        // Then - subsequentAction까지 포함해서 스킵됨
        #expect(testStore.actions.isEmpty)
    }

    // MARK: - withStore Tests

    @Test("withStore는 자동으로 cleanup을 호출한다")
    func withStore_automaticallyCallsCleanup() async throws {
        // Given
        let viewModel = MockViewModel()
        var cleanupCalled = false

        // 원래 observer 저장
        let originalObserver = viewModel.actionObserver

        // When
        await AsyncTestStore.withStore(viewModel: viewModel) { store in
            store.send(.setValue(10))
            #expect(store.state.currentValue == 10)
        }

        // Then - cleanup 후 observer가 원래대로 복원됨
        // observer가 nil이었으면 nil로, 있었으면 원래 값으로
        if originalObserver == nil {
            cleanupCalled = viewModel.actionObserver == nil
        } else {
            cleanupCalled = true // observer가 설정되었다면 복원된 것
        }
        #expect(cleanupCalled == true)
    }

    // MARK: - TestError Description Tests

    @Test("TestError.timeout은 상세한 설명을 제공한다")
    func error_timeout_providesDetailedDescription() {
        // Given
        let error = AsyncTestStore<MockViewModel>.TestError.timeout(
            description: "Test timeout",
            lastState: "State(value: 10)"
        )

        // Then
        #expect(error.description.contains("Test timeout"))
        #expect(error.description.contains("State(value: 10)"))
    }

    @Test("TestError.actionNotReceived는 상세한 설명을 제공한다")
    func error_actionNotReceived_providesDetailedDescription() {
        // Given
        let error = AsyncTestStore<MockViewModel>.TestError.actionNotReceived(
            expected: ".dataLoaded",
            receivedActions: [".loading", ".error"]
        )

        // Then
        #expect(error.description.contains(".dataLoaded"))
        #expect(error.description.contains(".loading"))
    }
}

// swiftlint:enable main_actor_usage
