//
//  AsyncOperation.swift
//  AsyncViewModel
//
//  Created by jimmy on 2025/12/29.
//

import Foundation

/// 비동기 작업을 감싸는 구조체
public struct AsyncOperation<Action: Equatable & Sendable>: Equatable, Sendable {
    public let id = UUID()
    private let _operation: @Sendable () async -> AsyncOperationResult<Action>

    public init(operation: @escaping @Sendable () async -> AsyncOperationResult<Action>) {
        _operation = operation
    }

    public func callAsFunction() async -> AsyncOperationResult<Action> {
        await _operation()
    }

    public static func == (lhs: AsyncOperation<Action>, rhs: AsyncOperation<Action>) -> Bool {
        lhs.id == rhs.id
    }
}

/// 비동기 작업의 결과
public enum AsyncOperationResult<Action: Equatable & Sendable>: Equatable, Sendable {
    case action(Action)
    case none
    case error(SendableError)

    public static func == (lhs: AsyncOperationResult<Action>, rhs: AsyncOperationResult<Action>) -> Bool {
        switch (lhs, rhs) {
        case let (.action(lhsAction), .action(rhsAction)):
            return lhsAction == rhsAction
        case (.none, .none):
            return true
        case let (.error(lhsError), .error(rhsError)):
            return lhsError == rhsError
        default:
            return false
        }
    }
}
