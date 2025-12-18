//
//  AsyncEffectTests.swift
//  AsyncViewModelTests
//
//  Created by 정준영 on 2025/8/15.
//

@testable import AsyncViewModelCore
import Foundation
import Testing

@MainActor
struct AsyncEffectTests {

    enum MockAction: Equatable, Sendable {
        case increment
        case decrement
    }

    enum MockCancelID: Hashable, Sendable {
        case taskA
        case taskB
    }

    // MARK: - Equatable Conformance Tests

    @Test("Equatable: .none은 항상 동일하다")
    func equatable_noneIsAlwaysEqual() {
        #expect(AsyncEffect<MockAction, MockCancelID>.none == .none)
    }

    @Test("Equatable: .action은 연관값이 동일할 때만 동일하다")
    func equatable_actionIsEqualWithSameAssociatedValue() {
        #expect(AsyncEffect<MockAction, MockCancelID>.action(.increment) == .action(.increment))
        #expect(AsyncEffect<MockAction, MockCancelID>.action(.increment) != .action(.decrement))
    }

    @Test("Equatable: .run은 ID가 동일할 때 동일하다")
    func equatable_runIsEqualWithSameID() {
        let op1 = AsyncOperation<MockAction> { .none }
        let op2 = AsyncOperation<MockAction> { .none }

        #expect(AsyncEffect<MockAction, MockCancelID>.run(id: MockCancelID.taskA, operation: op1) == .run(id: MockCancelID.taskA, operation: op2))
        #expect(AsyncEffect<MockAction, MockCancelID>.run(id: MockCancelID.taskA, operation: op1) != .run(id: MockCancelID.taskB, operation: op1))
    }
    
    @Test("Equatable: .run은 ID가 nil일 때 동일하다")
    func equatable_runIsEqualWithNilID() {
        let op1 = AsyncOperation<MockAction> { .none }
        let op2 = AsyncOperation<MockAction> { .none }

        #expect(AsyncEffect<MockAction, MockCancelID>.run(operation: op1) == .run(operation: op2))
    }

    @Test("Equatable: .cancel은 ID가 동일할 때 동일하다")
    func equatable_cancelIsEqualWithSameID() {
        #expect(AsyncEffect<MockAction, MockCancelID>.cancel(id: MockCancelID.taskA) == .cancel(id: MockCancelID.taskA))
        #expect(AsyncEffect<MockAction, MockCancelID>.cancel(id: MockCancelID.taskA) != .cancel(id: MockCancelID.taskB))
    }



    @Test("Equatable: .concurrent는 내부 배열이 동일할 때 동일하다")
    func equatable_concurrentIsEqualWithSameEffects() {
        let effect1: AsyncEffect<MockAction, MockCancelID> = .action(.increment)
        let effect2: AsyncEffect<MockAction, MockCancelID> = .action(.decrement)

        #expect(AsyncEffect.concurrent([effect1, effect2]) == .concurrent([effect1, effect2]))
        #expect(AsyncEffect.concurrent([effect1, effect2]) != .concurrent([effect2, effect1]))
    }
    
    @Test("Equatable: 다른 타입의 Effect는 동일하지 않다")
    func equatable_differentEffectTypesAreNotEqual() {
        #expect(AsyncEffect<MockAction, MockCancelID>.none != .action(.increment))
        #expect(AsyncEffect<MockAction, MockCancelID>.action(.increment) != .cancel(id: MockCancelID.taskA))
    }

    // MARK: - Convenience API Tests



    @Test("Convenience: .concurrent 편의 API가 올바르게 동작한다")
    func convenience_concurrentAPIsWorkCorrectly() {
        let effect1: AsyncEffect<MockAction, MockCancelID> = .action(.increment)
        let effect2: AsyncEffect<MockAction, MockCancelID> = .action(.decrement)
        let concurrentManually = AsyncEffect.concurrent([effect1, effect2])
        let concurrentWithConvenience = AsyncEffect.concurrent(effect1, effect2)
        #expect(concurrentManually == concurrentWithConvenience)
    }

    @Test("Convenience: .run이 성공 시 .action을 반환한다")
    func convenience_runReturnsActionOnSuccess() async {
        let effect: AsyncEffect<MockAction, MockCancelID> = .run { .increment }
        guard case let .run(_, operation) = effect else {
            Issue.record("run이 .run Effect를 생성하지 않음")
            return
        }
        
        let result = await operation()
        #expect(result == .action(.increment))
    }

    @Test("Convenience: .run이 실패 시 .error를 반환한다")
    func convenience_runReturnsErrorOnFailure() async {
        enum TestError: Error { case failure }
        let effect = AsyncEffect<MockAction, MockCancelID>.run { throw TestError.failure }
        
        guard case let .run(_, operation) = effect else {
            Issue.record("run이 .run Effect를 생성하지 않음")
            return
        }
        
        let result = await operation()
        #expect(result == .error(SendableError(TestError.failure)))
    }

    @Test("Convenience: .sleepThen이 지정된 시간 후 액션을 반환한다")
    func convenience_sleepThenReturnsActionAfterDelay() async {
        let effect: AsyncEffect<MockAction, MockCancelID> = .sleepThen(for: 0.1, action: .increment)
        
        guard case let .run(_, operation) = effect else {
            Issue.record("sleepThen이 .run Effect를 생성하지 않음")
            return
        }
        
        let result = await operation()
        #expect(result == .action(.increment))
    }

    // MARK: - Error Handling Tests

    @Test("Error Handling: .runCatchingError이 성공 시 액션을 반환한다")
    func errorHandling_runCatchingErrorReturnsActionOnSuccess() async {
        let effect: AsyncEffect<MockAction, MockCancelID> = .runCatchingError(
            errorAction: { _ in .decrement }
        ) {
            .increment
        }
        
        guard case let .run(_, operation) = effect else {
            Issue.record("runCatchingError이 .run Effect를 생성하지 않음")
            return
        }
        
        let result = await operation()
        #expect(result == .action(.increment))
    }

    @Test("Error Handling: .runCatchingError이 실패 시 errorAction을 실행한다")
    func errorHandling_runCatchingErrorExecutesErrorActionOnFailure() async {
        enum TestError: Error { case failure }
        
        let effect: AsyncEffect<MockAction, MockCancelID> = .runCatchingError(
            errorAction: { _ in .decrement }
        ) {
            throw TestError.failure
        }
        
        guard case let .run(_, operation) = effect else {
            Issue.record("runCatchingError이 .run Effect를 생성하지 않음")
            return
        }
        
        let result = await operation()
        #expect(result == .action(.decrement))
    }

    @Test("Error Handling: .runCatchingError이 ID를 올바르게 전달한다")
    func errorHandling_runCatchingErrorPassesIDCorrectly() {
        let effect: AsyncEffect<MockAction, MockCancelID> = .runCatchingError(
            id: .taskA,
            errorAction: { _ in .decrement }
        ) {
            .increment
        }
        
        guard case let .run(id, _) = effect else {
            Issue.record("runCatchingError이 .run Effect를 생성하지 않음")
            return
        }
        
        #expect(id == .taskA)
    }

    // MARK: - Time-based Effect Tests

    @Test("Time-based: .sleep이 지정된 시간만큼 대기한다")
    func timeBased_sleepWaitsForSpecifiedDuration() async {
        let startTime = Date()
        let effect: AsyncEffect<MockAction, MockCancelID> = .sleep(for: 0.1)
        
        guard case let .run(_, operation) = effect else {
            Issue.record("sleep이 .run Effect를 생성하지 않음")
            return
        }
        
        let result = await operation()
        let elapsedTime = Date().timeIntervalSince(startTime)
        
        #expect(result == .none)
        #expect(elapsedTime >= 0.1)
    }

    @Test("Time-based: .sleep이 ID를 올바르게 전달한다")
    func timeBased_sleepPassesIDCorrectly() {
        let effect: AsyncEffect<MockAction, MockCancelID> = .sleep(id: .taskA, for: 0.1)
        
        guard case let .run(id, _) = effect else {
            Issue.record("sleep이 .run Effect를 생성하지 않음")
            return
        }
        
        #expect(id == .taskA)
    }

    @Test("Time-based: .sleepThen이 ID를 올바르게 전달한다")
    func timeBased_sleepThenPassesIDCorrectly() {
        let effect: AsyncEffect<MockAction, MockCancelID> = .sleepThen(id: .taskA, for: 0.1, action: .increment)
        
        guard case let .run(id, _) = effect else {
            Issue.record("sleepThen이 .run Effect를 생성하지 않음")
            return
        }
        
        #expect(id == .taskA)
    }

    // MARK: - Debounce Tests

    @Test("Debounce: .debounce이 지정된 시간 후 작업을 실행한다")
    func debounce_debounceExecutesAfterDelay() async {
        let startTime = Date()
        let effect: AsyncEffect<MockAction, MockCancelID> = .debounce(id: .taskA, for: 0.1) {
            .increment
        }
        
        guard case let .run(_, operation) = effect else {
            Issue.record("debounce가 .run Effect를 생성하지 않음")
            return
        }
        
        let result = await operation()
        let elapsedTime = Date().timeIntervalSince(startTime)
        
        #expect(result == .action(.increment))
        #expect(elapsedTime >= 0.1)
    }

    @Test("Debounce: .debounce이 ID를 올바르게 전달한다")
    func debounce_debouncePassesIDCorrectly() {
        let effect: AsyncEffect<MockAction, MockCancelID> = .debounce(id: .taskA, for: 0.1) {
            .increment
        }
        
        guard case let .run(id, _) = effect else {
            Issue.record("debounce가 .run Effect를 생성하지 않음")
            return
        }
        
        #expect(id == .taskA)
    }

    @Test("Debounce: .debounce이 실패 시 에러를 반환한다")
    func debounce_debounceReturnsErrorOnFailure() async {
        enum TestError: Error { case failure }
        
        let effect: AsyncEffect<MockAction, MockCancelID> = .debounce(id: .taskA, for: 0.1) {
            throw TestError.failure
        }
        
        guard case let .run(_, operation) = effect else {
            Issue.record("debounce가 .run Effect를 생성하지 않음")
            return
        }
        
        let result = await operation()
        #expect(result == .error(SendableError(TestError.failure)))
    }

    // MARK: - Throttle Tests

    @Test("Throttle: .throttle이 지정된 간격 후 작업을 실행한다")
    func throttle_throttleExecutesAfterInterval() async {
        let startTime = Date()
        let effect: AsyncEffect<MockAction, MockCancelID> = .throttle(id: .taskA, interval: 0.1) {
            .increment
        }
        
        guard case let .run(_, operation) = effect else {
            Issue.record("throttle이 .run Effect를 생성하지 않음")
            return
        }
        
        let result = await operation()
        let elapsedTime = Date().timeIntervalSince(startTime)
        
        #expect(result == .action(.increment))
        #expect(elapsedTime >= 0.1)
    }

    @Test("Throttle: .throttle이 ID를 올바르게 전달한다")
    func throttle_throttlePassesIDCorrectly() {
        let effect: AsyncEffect<MockAction, MockCancelID> = .throttle(id: .taskA, interval: 0.1) {
            .increment
        }
        
        guard case let .run(id, _) = effect else {
            Issue.record("throttle이 .run Effect를 생성하지 않음")
            return
        }
        
        #expect(id == .taskA)
    }

    @Test("Throttle: .throttle이 실패 시 에러를 반환한다")
    func throttle_throttleReturnsErrorOnFailure() async {
        enum TestError: Error { case failure }
        
        let effect: AsyncEffect<MockAction, MockCancelID> = .throttle(id: .taskA, interval: 0.1) {
            throw TestError.failure
        }
        
        guard case let .run(_, operation) = effect else {
            Issue.record("throttle이 .run Effect를 생성하지 않음")
            return
        }
        
        let result = await operation()
        #expect(result == .error(SendableError(TestError.failure)))
    }

    // MARK: - Edge Cases and Error Scenarios


    @Test("Edge Cases: 빈 배열로 .concurrent가 동작한다")
    func edgeCases_concurrentWithEmptyArray() {
        let effect = AsyncEffect<MockAction, MockCancelID>.concurrent([])
        #expect(effect == .concurrent([]))
    }

    @Test("Edge Cases: .run의 ID가 nil일 때 동작한다")
    func edgeCases_runWithNilID() {
        let effect: AsyncEffect<MockAction, MockCancelID> = .run { .increment }
        
        guard case let .run(id, _) = effect else {
            Issue.record("run이 .run Effect를 생성하지 않음")
            return
        }
        
        #expect(id == nil)
    }

    @Test("Edge Cases: .runCatchingError의 ID가 nil일 때 동작한다")
    func edgeCases_runCatchingErrorWithNilID() {
        let effect: AsyncEffect<MockAction, MockCancelID> = .runCatchingError(
            errorAction: { _ in .decrement }
        ) {
            .increment
        }
        
        guard case let .run(id, _) = effect else {
            Issue.record("runCatchingError이 .run Effect를 생성하지 않음")
            return
        }
        
        #expect(id == nil)
    }

    @Test("Edge Cases: .sleep의 ID가 nil일 때 동작한다")
    func edgeCases_sleepWithNilID() {
        let effect: AsyncEffect<MockAction, MockCancelID> = .sleep(for: 0.1)
        
        guard case let .run(id, _) = effect else {
            Issue.record("sleep이 .run Effect를 생성하지 않음")
            return
        }
        
        #expect(id == nil)
    }

    @Test("Edge Cases: .sleepThen의 ID가 nil일 때 동작한다")
    func edgeCases_sleepThenWithNilID() {
        let effect: AsyncEffect<MockAction, MockCancelID> = .sleepThen(for: 0.1, action: .increment)
        
        guard case let .run(id, _) = effect else {
            Issue.record("sleepThen이 .run Effect를 생성하지 않음")
            return
        }
        
        #expect(id == nil)
    }

    // MARK: - Performance and Timeout Tests

    @Test("Performance: .sleep이 정확한 시간을 대기한다")
    func performance_sleepWaitsAccurateTime() async {
        let effect: AsyncEffect<MockAction, MockCancelID> = .sleep(for: 0.5)
        
        guard case let .run(_, operation) = effect else {
            Issue.record("sleep이 .run Effect를 생성하지 않음")
            return
        }
        
        let startTime = Date()
        let result = await operation()
        let elapsedTime = Date().timeIntervalSince(startTime)
        
        #expect(result == .none)
        #expect(elapsedTime >= 0.5)
        #expect(elapsedTime < 1.0) // 0.5초 + 여유시간
    }

    @Test("Performance: .debounce이 정확한 시간을 대기한다")
    func performance_debounceWaitsAccurateTime() async {
        let effect: AsyncEffect<MockAction, MockCancelID> = .debounce(id: .taskA, for: 0.5) {
            .increment
        }
        
        guard case let .run(_, operation) = effect else {
            Issue.record("debounce가 .run Effect를 생성하지 않음")
            return
        }
        
        let startTime = Date()
        let result = await operation()
        let elapsedTime = Date().timeIntervalSince(startTime)
        
        #expect(result == .action(.increment))
        #expect(elapsedTime >= 0.5)
        #expect(elapsedTime < 1.0) // 0.5초 + 여유시간
    }

    @Test("Performance: .throttle이 정확한 시간을 대기한다")
    func performance_throttleWaitsAccurateTime() async {
        let effect: AsyncEffect<MockAction, MockCancelID> = .throttle(id: .taskA, interval: 0.5) {
            .increment
        }
        
        guard case let .run(_, operation) = effect else {
            Issue.record("throttle이 .run Effect를 생성하지 않음")
            return
        }
        
        let startTime = Date()
        let result = await operation()
        let elapsedTime = Date().timeIntervalSince(startTime)
        
        #expect(result == .action(.increment))
        #expect(elapsedTime >= 0.5)
        #expect(elapsedTime < 1.0) // 0.5초 + 여유시간
    }

    // MARK: - Complex Scenarios

    @Test("Complex: 여러 Effect를 .concurrent로 조합한다")
    func complex_concurrentMultipleEffects() {
        let effect1: AsyncEffect<MockAction, MockCancelID> = .action(.increment)
        let effect2: AsyncEffect<MockAction, MockCancelID> = .action(.decrement)
        let effect3: AsyncEffect<MockAction, MockCancelID> = .cancel(id: .taskA)
        
        let concurrent = AsyncEffect.concurrent([effect1, effect2, effect3])
        let expected = AsyncEffect.concurrent([effect1, effect2, effect3])
        
        #expect(concurrent == expected)
    }

    @Test("Complex: .run과 .sleepThen을 조합한다")
    func complex_combineRunAndSleepThen() {
        let runEffect: AsyncEffect<MockAction, MockCancelID> = .run { .increment }
        let sleepEffect: AsyncEffect<MockAction, MockCancelID> = .sleepThen(for: 0.1, action: .decrement)
        
        // merge 제거됨 - 순차 실행은 배열로 처리
        let sequentialEffects = [runEffect, sleepEffect]
        let expected = [runEffect, sleepEffect]
        
        #expect(sequentialEffects == expected)
    }
}

