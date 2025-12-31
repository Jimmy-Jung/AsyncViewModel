//
//  AsyncTestStoreTests.swift
//  AsyncViewModelTests
//
//  Created by jimmy on 2025/12/29.
//

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
        await #expect(throws: AsyncTestStore<MockViewModel>.TestError.timeout) {
            try await testStore.wait(for: { $0.currentValue == 10 }, timeout: 0.1)
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
}

