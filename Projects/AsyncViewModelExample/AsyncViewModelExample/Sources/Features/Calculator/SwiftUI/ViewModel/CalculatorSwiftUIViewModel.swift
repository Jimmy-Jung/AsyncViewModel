//
//  CalculatorSwiftUIViewModel.swift
//  SwiftUIFeature
//
//  Created by jimmy on 2025/12/29.
//

import AsyncViewModel // Kit + Macros 한 번에!
import Foundation

public extension CalculatorSwiftUIViewModel {
    enum Input: Equatable, Sendable {
        case number(Int)
        case operation(CalculatorOperation)
        case equals
        case clear
        case dismissAlert
    }

    enum Action: Equatable, Sendable {
        case inputNumber(Int)
        case setOperation(CalculatorOperation)
        case calculate
        case clearAll
        case dismissAlert
        case autoClear
        case setTimerActive(Bool)
        case errorOccurred(SendableError)
        case stateUpdated(CalculatorState)
        case displayUpdated(String)
    }

    struct State: Equatable, Sendable {
        var display: String = "0"
        var activeAlert: AlertType?
        var calculatorState: CalculatorState = .initial
        var isAutoClearTimerActive: Bool = false

        public init() {}

        public enum AlertType: Identifiable, Equatable, Sendable {
            case error(Error)
            public var id: String { "error" }

            public static func == (lhs: AlertType, rhs: AlertType) -> Bool {
                switch (lhs, rhs) {
                case let (.error(lhsError), .error(rhsError)):
                    return lhsError.localizedDescription == rhsError.localizedDescription
                }
            }
        }
    }

    enum CancelID: Hashable, Sendable {
        case autoClearTimer
    }
}

@AsyncViewModel
public final class CalculatorSwiftUIViewModel: ObservableObject {
    // MARK: - Properties

    @Published public var state: State

    // MARK: - Dependencies

    private let calculatorUseCase: CalculatorUseCaseProtocol

    // MARK: - Computed Properties

    var display: String { state.display }
    var activeAlert: State.AlertType? { state.activeAlert }
    var isAutoClearTimerActive: Bool { state.isAutoClearTimerActive }

    // MARK: - Initialization

    public init(
        initialState: State = State(),
        calculatorUseCase: CalculatorUseCaseProtocol = CalculatorUseCase()
    ) {
        state = initialState
        self.calculatorUseCase = calculatorUseCase
    }

    // MARK: - AsyncViewModel Protocol Implementation

    public func transform(_ input: Input) -> [Action] {
        switch input {
        case let .number(digit):
            return [.inputNumber(digit)]
        case let .operation(op):
            return [.setOperation(op)]
        case .equals:
            return [.calculate]
        case .clear:
            return [.clearAll]
        case .dismissAlert:
            return [.dismissAlert]
        }
    }

    // MARK: - Reducer Implementation

    public func reduce(state: inout State, action: Action) -> [AsyncEffect<Action, CancelID>] {
        switch action {
        case let .inputNumber(digit):
            let currentCalculatorState = state.calculatorState
            return [
                .cancel(id: CancelID.autoClearTimer),
                .action(.setTimerActive(false)),
                .run(operation: { [calculatorUseCase] in
                    let newState = try calculatorUseCase.inputNumber(digit, currentState: currentCalculatorState)
                    return .stateUpdated(newState)
                }),
            ]

        case let .setOperation(operation):
            return [
                .cancel(id: CancelID.autoClearTimer),
                .action(.setTimerActive(false)),
                .run(operation: { [calculatorUseCase, currentCalculatorState = state.calculatorState] in
                    let newState = try calculatorUseCase.setOperation(operation, currentState: currentCalculatorState)
                    return .stateUpdated(newState)
                }),
            ]

        case .calculate:
            return [
                .action(.setTimerActive(true)),
                .run(operation: { [calculatorUseCase, currentCalculatorState = state.calculatorState] in
                    let newState = try await calculatorUseCase.calculate(currentState: currentCalculatorState)
                    return .stateUpdated(newState)
                }),
                .run(id: CancelID.autoClearTimer, operation: {
                    try await Task.sleep(nanoseconds: 5_000_000_000)
                    return .autoClear
                }),
            ]

        case .clearAll:
            let newState = calculatorUseCase.clear()
            return [
                .cancel(id: CancelID.autoClearTimer),
                .action(.setTimerActive(false)),
                .action(.stateUpdated(newState)),
            ]

        case .dismissAlert:
            state.activeAlert = nil
            return [.none]

        case .autoClear:
            let newState = calculatorUseCase.clear()
            return [
                .action(.setTimerActive(false)),
                .action(.stateUpdated(newState)),
            ]

        case let .setTimerActive(isActive):
            state.isAutoClearTimerActive = isActive
            return [.none]

        case let .errorOccurred(error):
            state.activeAlert = .error(error)
            let newState = calculatorUseCase.clear()
            state.calculatorState = newState
            state.display = newState.display
            state.isAutoClearTimerActive = false
            return [.none]

        case let .stateUpdated(newState):
            state.calculatorState = newState
            state.display = newState.display
            return [.none]

        case let .displayUpdated(newDisplay):
            state.display = newDisplay
            return [.none]
        }
    }

    public func handleError(_ error: SendableError) {
        perform(.errorOccurred(error))
    }
}
