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
        case numberButtonTapped(Int)
        case operationButtonTapped(CalculatorOperation)
        case equalsButtonTapped
        case clearButtonTapped
        case alertDismissed
    }

    enum Action: Equatable, Sendable {
        case inputNumber(Int)
        case setOperation(CalculatorOperation)
        case calculate
        case clearAll
        case dismissAlert
        case performAutoClear
        case setTimerActive(Bool)
        case handleError(SendableError)
        case updateState(CalculatorState)
        case updateDisplay(String)
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
        case let .numberButtonTapped(digit):
            return [.inputNumber(digit)]
        case let .operationButtonTapped(op):
            return [.setOperation(op)]
        case .equalsButtonTapped:
            return [.calculate]
        case .clearButtonTapped:
            return [.clearAll]
        case .alertDismissed:
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
                    return .updateState(newState)
                }),
            ]

        case let .setOperation(operation):
            return [
                .cancel(id: CancelID.autoClearTimer),
                .action(.setTimerActive(false)),
                .run(operation: { [calculatorUseCase, currentCalculatorState = state.calculatorState] in
                    let newState = try calculatorUseCase.setOperation(operation, currentState: currentCalculatorState)
                    return .updateState(newState)
                }),
            ]

        case .calculate:
            return [
                .action(.setTimerActive(true)),
                .run(operation: { [calculatorUseCase, currentCalculatorState = state.calculatorState] in
                    let newState = try await calculatorUseCase.calculate(currentState: currentCalculatorState)
                    return .updateState(newState)
                }),
                .run(id: CancelID.autoClearTimer, operation: {
                    try await Task.sleep(nanoseconds: 5_000_000_000)
                    return .performAutoClear
                }),
            ]

        case .clearAll:
            let newState = calculatorUseCase.clear()
            return [
                .cancel(id: CancelID.autoClearTimer),
                .action(.setTimerActive(false)),
                .action(.updateState(newState)),
            ]

        case .dismissAlert:
            state.activeAlert = nil
            return [.none]

        case .performAutoClear:
            let newState = calculatorUseCase.clear()
            return [
                .action(.setTimerActive(false)),
                .action(.updateState(newState)),
            ]

        case let .setTimerActive(isActive):
            state.isAutoClearTimerActive = isActive
            return [.none]

        case let .handleError(error):
            state.activeAlert = .error(error)
            let newState = calculatorUseCase.clear()
            state.calculatorState = newState
            state.display = newState.display
            state.isAutoClearTimerActive = false
            return [.none]

        case let .updateState(newState):
            state.calculatorState = newState
            state.display = newState.display
            return [.none]

        case let .updateDisplay(newDisplay):
            state.display = newDisplay
            return [.none]
        }
    }

    public func handleError(_ error: SendableError) {
        perform(.handleError(error))
    }
}
