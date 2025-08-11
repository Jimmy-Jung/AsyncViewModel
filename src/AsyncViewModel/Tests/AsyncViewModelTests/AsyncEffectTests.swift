//
//  AsyncEffectTests.swift
//  AsyncViewModelTests
//
//  Created by 정준영 on 2025/8/15.
//

@testable import AsyncViewModel
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

    @Test("Equatable: .merge는 내부 배열이 동일할 때 동일하다")
    func equatable_mergeIsEqualWithSameEffects() {
        let effect1: AsyncEffect<MockAction, MockCancelID> = .action(.increment)
        let effect2: AsyncEffect<MockAction, MockCancelID> = .action(.decrement)

        #expect(AsyncEffect.merge([effect1, effect2]) == .merge([effect1, effect2]))
        #expect(AsyncEffect.merge([effect1, effect2]) != .merge([effect2, effect1]))
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

    @Test("Convenience: .merge 편의 API가 올바르게 동작한다")
    func convenience_mergeAPIsWorkCorrectly() {
        let effect1: AsyncEffect<MockAction, MockCancelID> = .action(.increment)
        let effect2: AsyncEffect<MockAction, MockCancelID> = .action(.decrement)
        let mergedManually = AsyncEffect.merge([effect1, effect2])
        let mergedWithConvenience = AsyncEffect.merge(effect1, effect2)
        #expect(mergedManually == mergedWithConvenience)
    }

    @Test("Convenience: .concurrent 편의 API가 올바르게 동작한다")
    func convenience_concurrentAPIsWorkCorrectly() {
        let effect1: AsyncEffect<MockAction, MockCancelID> = .action(.increment)
        let effect2: AsyncEffect<MockAction, MockCancelID> = .action(.decrement)
        let concurrentManually = AsyncEffect.concurrent([effect1, effect2])
        let concurrentWithConvenience = AsyncEffect.concurrent(effect1, effect2)
        #expect(concurrentManually == concurrentWithConvenience)
    }

    @Test("Convenience: .runAction이 성공 시 .action을 반환한다")
    func convenience_runActionReturnsActionOnSuccess() async {
        let effect: AsyncEffect<MockAction, MockCancelID> = .runAction { .increment }
        guard case let .run(_, operation) = effect else {
            Issue.record("runAction이 .run Effect를 생성하지 않음")
            return
        }
        
        let result = await operation()
        #expect(result == .action(.increment))
    }

    @Test("Convenience: .runAction이 실패 시 .error를 반환한다")
    func convenience_runActionReturnsErrorOnFailure() async {
        enum TestError: Error { case failure }
        let effect = AsyncEffect<MockAction, MockCancelID>.runAction { throw TestError.failure }
        
        guard case let .run(_, operation) = effect else {
            Issue.record("runAction이 .run Effect를 생성하지 않음")
            return
        }
        
        let result = await operation()
        #expect(result == .error(SendableError(TestError.failure)))
    }

    @Test("Convenience: .runActions가 성공 시 .actions를 반환한다")
    func convenience_runActionsReturnsActionsOnSuccess() async {
        let actions: [MockAction] = [.increment, .decrement]
        let effect: AsyncEffect<MockAction, MockCancelID> = .runActions { actions }
        
        guard case let .run(_, operation) = effect else {
            Issue.record("runActions가 .run Effect를 생성하지 않음")
            return
        }
        
        let result = await operation()
        #expect(result == .actions(actions))
    }
}

