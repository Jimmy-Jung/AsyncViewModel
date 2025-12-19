//
//  AsyncOperationTests.swift
//  AsyncViewModelTests
//
//  Created by 정준영 on 2025/8/15.
//

@testable import AsyncViewModelCore
import Foundation
import Testing

@MainActor
struct AsyncOperationTests {

    enum MockAction: Equatable, Sendable {
        case success
    }

    // MARK: - Equatable Conformance Tests

    @Test("Equatable: UUID 기반이므로 다른 인스턴스는 항상 동일하지 않다")
    func equatable_differentInstancesAreNotEqual() {
        let op1 = AsyncOperation<MockAction> { .none }
        let op2 = AsyncOperation<MockAction> { .none }
        #expect(op1 != op2)
    }

    @Test("Equatable: 동일 인스턴스는 항상 동일하다")
    func equatable_sameInstanceIsEqual() {
        let op1 = AsyncOperation<MockAction> { .none }
        let op2 = op1
        #expect(op1 == op2)
    }

    // MARK: - Call As Function Tests

    @Test("callAsFunction이 .action을 올바르게 반환한다")
    func callAsFunction_returnsActionCorrectly() async {
        let operation = AsyncOperation<MockAction> { .action(.success) }
        let result = await operation()
        #expect(result == .action(.success))
    }

    @Test("callAsFunction이 .error를 올바르게 반환한다")
    func callAsFunction_returnsErrorCorrectly() async {
        enum TestError: Error { case failure }
        let operation = AsyncOperation<MockAction> { .error(SendableError(TestError.failure)) }
        let result = await operation()
        #expect(result == .error(SendableError(TestError.failure)))
    }

    @Test("callAsFunction이 .none을 올바르게 반환한다")
    func callAsFunction_returnsNoneCorrectly() async {
        let operation = AsyncOperation<MockAction> { .none }
        let result = await operation()
        #expect(result == .none)
    }
}

