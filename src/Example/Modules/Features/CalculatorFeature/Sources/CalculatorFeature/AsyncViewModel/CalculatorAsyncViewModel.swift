//
//  CalculatorAsyncViewModel.swift
//  CalculatorFeature
//
//  Created by 정준혁 on 2025/08/08
//

import Foundation
import AsyncViewModel

extension CalculatorAsyncViewModel {

    public enum Input: Equatable & Sendable {
        case number(Int)
        case operation(CalculatorOperation)
        case equals
        case clear
        case dismissAlert
    }

    public enum Action: Equatable & Sendable {
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
    
    public struct State: Equatable & Sendable {
        var display: String = "0"
        var activeAlert: AlertType?
        var calculatorState: CalculatorState = .initial
        var isAutoClearTimerActive: Bool = false
        
        public init() {}

        // 알림 타입을 정의하는 enum
        public enum AlertType: Identifiable, Equatable, Sendable {
            case error(Error)
            public var id: String { "error" }

            public static func == (lhs: AlertType, rhs: AlertType) -> Bool {
                switch (lhs, rhs) {
                case (.error(let lhsError), .error(let rhsError)):
                    return lhsError.localizedDescription == rhsError.localizedDescription
                }
            }
        }
    }

    public enum CancelID: Hashable, Sendable {
        case autoClearTimer
    }
}

// MARK: - Improved CalculatorAsyncViewModel
public final class CalculatorAsyncViewModel: AsyncViewModel {
    
    
    
    // MARK: - Properties
    @Published public var state: State
    public var tasks: [CancelID: Task<Void, Never>] = [:]
    public var effectQueue: [AsyncEffect<Action, CancelID>] = []
    public var actionObserver: ((Action) -> Void)? = nil
    public var isProcessingEffects: Bool = false
    
    // MARK: - Logging Properties
    public var isLoggingEnabled: Bool = true
    public var logLevel: LogLevel = .info
    public var stateChangeObserver: ((State, State) -> Void)? = nil
    public var effectObserver: ((AsyncEffect<Action, CancelID>) -> Void)? = nil
    public var performanceObserver: ((String, TimeInterval) -> Void)? = nil

    // MARK: - Dependencies
    private let calculatorUseCase: CalculatorUseCaseProtocol

    // MARK: - Computed Properties for SwiftUI Binding
    var display: String { state.display }
    var activeAlert: State.AlertType? { state.activeAlert }
    var isAutoClearTimerActive: Bool { state.isAutoClearTimerActive }

    // MARK: - Initialization
    public init(
        initialState: State = State(),
        calculatorUseCase: CalculatorUseCaseProtocol = CalculatorUseCase(),
        isLoggingEnabled: Bool = true,
        logLevel: LogLevel = .info
    ) {
        self.state = initialState
        self.calculatorUseCase = calculatorUseCase
        self.isLoggingEnabled = isLoggingEnabled
        self.logLevel = logLevel
        self.stateChangeObserver = nil
        self.effectObserver = nil
        self.performanceObserver = nil
    }

    // MARK: - AsyncViewModel Protocol Implementation
    public func transform(_ input: Input) -> [Action] {
        switch input {
        case .number(let digit):
            return [.inputNumber(digit)]
        case .operation(let op):
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
        case .inputNumber(let digit):
            let currentCalculatorState = state.calculatorState
            return [
                .cancel(id: CancelID.autoClearTimer),
                .action(.setTimerActive(false)),
                .run(operation: { [calculatorUseCase] in
                    do {
                        let newState = try calculatorUseCase.inputNumber(
                            digit,
                            currentState: currentCalculatorState
                        )
                        return .stateUpdated(newState)
                    } catch {
                        return .errorOccurred(SendableError(error))
                    }
                }),
            ]

        case .setOperation(let operation):
            return [
                .cancel(id: CancelID.autoClearTimer),
                .action(.setTimerActive(false)),
                .run(operation: { [calculatorUseCase, currentCalculatorState = state.calculatorState] in
                    do {
                        let newState = try calculatorUseCase.setOperation(
                            operation,
                            currentState: currentCalculatorState
                        )
                        return .stateUpdated(newState)
                    } catch {
                        return .errorOccurred(SendableError(error))
                    }
                }),
            ]

        case .calculate:
            return [
                .action(.setTimerActive(true)),
                .run(operation: { [calculatorUseCase, currentCalculatorState = state.calculatorState] in
                    do {
                        let newState = try calculatorUseCase.calculate(
                            currentState: currentCalculatorState
                        )
                        return .stateUpdated(newState)
                    } catch {
                        return .errorOccurred(SendableError(error))
                    }
                }),
                .run(
                    id: CancelID.autoClearTimer,
                    operation: {
                        try await Task.sleep(nanoseconds: 5_000_000_000) // 5초
                        return .autoClear
                    }
                ),
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

        case .setTimerActive(let isActive):
            state.isAutoClearTimerActive = isActive
            return [.none]

        case .errorOccurred(let error):
            state.activeAlert = .error(error)
            let newState = calculatorUseCase.clear()
            state.calculatorState = newState
            state.display = newState.display
            state.isAutoClearTimerActive = false
            return [.none]

        case .stateUpdated(let newState):
            state.calculatorState = newState
            state.display = newState.display
            return [.none]

        case .displayUpdated(let newDisplay):
            state.display = newDisplay
            return [.none]
        }
    }
    
    public func handleError(_ error: SendableError) {
        perform(.errorOccurred(error))
    }
}
