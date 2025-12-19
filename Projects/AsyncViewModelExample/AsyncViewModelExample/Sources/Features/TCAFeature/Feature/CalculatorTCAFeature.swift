//
//  CalculatorTCAFeature.swift
//  TCAFeature
//
//  Created by 정준영 on 2025/12/17
//

import ComposableArchitecture
import Foundation

@Reducer
public struct CalculatorTCAFeature {
    
    public init() {}
    
    // MARK: - State
    @ObservableState
    public struct State: Equatable {
        public var display: String = "0"
        public var activeAlert: AlertType?
        public var calculatorState: CalculatorState = .initial
        public var isAutoClearTimerActive: Bool = false
        
        public init() {}
        
        public enum AlertType: Identifiable, Equatable {
            case error(Error)
            
            public var id: String {
                switch self {
                case .error: return "error"
                }
            }
            
            public static func == (lhs: AlertType, rhs: AlertType) -> Bool {
                switch (lhs, rhs) {
                case (.error(let lhsError), .error(let rhsError)):
                    return lhsError.localizedDescription == rhsError.localizedDescription
                }
            }
        }
    }
    
    // MARK: - Action
    public enum Action: Equatable {
        case numberTapped(Int)
        case operationTapped(CalculatorOperation)
        case equalsTapped
        case clearTapped
        case dismissAlert
        
        case startAutoClearTimer
        case cancelAutoClearTimer
        case autoClearTriggered
        
        case displayUpdated(String)
        case errorOccurred(Error)
        case stateUpdated(CalculatorState)
        
        public static func == (lhs: Action, rhs: Action) -> Bool {
            switch (lhs, rhs) {
            case (.numberTapped(let lhsValue), .numberTapped(let rhsValue)):
                return lhsValue == rhsValue
            case (.operationTapped(let lhsOp), .operationTapped(let rhsOp)):
                return lhsOp == rhsOp
            case (.equalsTapped, .equalsTapped),
                 (.clearTapped, .clearTapped),
                 (.dismissAlert, .dismissAlert),
                 (.startAutoClearTimer, .startAutoClearTimer),
                 (.cancelAutoClearTimer, .cancelAutoClearTimer),
                 (.autoClearTriggered, .autoClearTriggered):
                return true
            case (.displayUpdated(let lhsDisplay), .displayUpdated(let rhsDisplay)):
                return lhsDisplay == rhsDisplay
            case (.errorOccurred(let lhsError), .errorOccurred(let rhsError)):
                return lhsError.localizedDescription == rhsError.localizedDescription
            case (.stateUpdated(let lhsState), .stateUpdated(let rhsState)):
                return lhsState == rhsState
            default:
                return false
            }
        }
    }
    
    // MARK: - Dependencies
    @Dependency(\.calculatorUseCase) var calculatorUseCase
    
    // MARK: - Cancellation IDs
    private enum CancelID: Hashable {
        case autoClearTimer
    }
    
    // MARK: - Reducer
    public var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .numberTapped(let digit):
                return handleNumberTapped(digit: digit, state: &state)
                
            case .operationTapped(let operation):
                return handleOperationTapped(operation: operation, state: &state)
                
            case .equalsTapped:
                return handleEqualsTapped(state: &state)
                
            case .clearTapped:
                return handleClearTapped(state: &state)
                
            case .dismissAlert:
                return handleDismissAlert(state: &state)
                
            case .displayUpdated(let newDisplay):
                return handleDisplayUpdated(newDisplay: newDisplay, state: &state)
                
            case .errorOccurred(let error):
                return handleErrorOccurred(error: error, state: &state)
                
            case .stateUpdated(let newState):
                return handleStateUpdated(newState: newState, state: &state)
                
            case .startAutoClearTimer:
                return handleStartAutoClearTimer(state: &state)
                
            case .cancelAutoClearTimer:
                return handleCancelAutoClearTimer(state: &state)
                
            case .autoClearTriggered:
                return handleAutoClearTriggered(state: &state)
            }
        }
    }
    
    // MARK: - Action Handlers
    
    private func handleNumberTapped(digit: Int, state: inout State) -> Effect<Action> {
        .run { [currentState = state.calculatorState] send in
            await send(.cancelAutoClearTimer)
            
            do {
                let newState = try calculatorUseCase.inputNumber(digit, currentState: currentState)
                await send(.stateUpdated(newState))
            } catch {
                await send(.errorOccurred(error))
            }
        }
    }
    
    private func handleOperationTapped(operation: CalculatorOperation, state: inout State) -> Effect<Action> {
        .run { [currentState = state.calculatorState] send in
            await send(.cancelAutoClearTimer)
            
            do {
                let newState = try calculatorUseCase.setOperation(operation, currentState: currentState)
                await send(.stateUpdated(newState))
            } catch {
                await send(.errorOccurred(error))
            }
        }
    }
    
    private func handleEqualsTapped(state: inout State) -> Effect<Action> {
        .run { [currentState = state.calculatorState] send in
            do {
                let newState = try await calculatorUseCase.calculate(currentState: currentState)
                await send(.stateUpdated(newState))
                await send(.startAutoClearTimer)
            } catch {
                await send(.errorOccurred(error))
            }
        }
    }
    
    private func handleClearTapped(state: inout State) -> Effect<Action> {
        .run { send in
            await send(.cancelAutoClearTimer)
            
            let newState = calculatorUseCase.clear()
            await send(.stateUpdated(newState))
        }
    }
    
    private func handleDismissAlert(state: inout State) -> Effect<Action> {
        state.activeAlert = nil
        return .none
    }
    
    private func handleDisplayUpdated(newDisplay: String, state: inout State) -> Effect<Action> {
        state.display = newDisplay
        return .none
    }
    
    private func handleErrorOccurred(error: Error, state: inout State) -> Effect<Action> {
        state.activeAlert = .error(error)
        let clearedState = calculatorUseCase.clear()
        state.calculatorState = clearedState
        state.display = clearedState.display
        return .none
    }
    
    private func handleStateUpdated(newState: CalculatorState, state: inout State) -> Effect<Action> {
        state.calculatorState = newState
        state.display = newState.display
        return .none
    }
    
    private func handleStartAutoClearTimer(state: inout State) -> Effect<Action> {
        state.isAutoClearTimerActive = true
        return .run { send in
            try await Task.sleep(nanoseconds: 5_000_000_000)
            await send(.autoClearTriggered)
        }
        .cancellable(id: CancelID.autoClearTimer)
    }
    
    private func handleCancelAutoClearTimer(state: inout State) -> Effect<Action> {
        state.isAutoClearTimerActive = false
        return .cancel(id: CancelID.autoClearTimer)
    }
    
    private func handleAutoClearTriggered(state: inout State) -> Effect<Action> {
        state.isAutoClearTimerActive = false
        let newState = calculatorUseCase.clear()
        state.calculatorState = newState
        state.display = newState.display
        return .none
    }
}

// MARK: - Dependencies

private enum CalculatorUseCaseKey: DependencyKey {
    static let liveValue: CalculatorUseCaseProtocol = CalculatorUseCase()
}

extension DependencyValues {
    var calculatorUseCase: CalculatorUseCaseProtocol {
        get { self[CalculatorUseCaseKey.self] }
        set { self[CalculatorUseCaseKey.self] = newValue }
    }
}

