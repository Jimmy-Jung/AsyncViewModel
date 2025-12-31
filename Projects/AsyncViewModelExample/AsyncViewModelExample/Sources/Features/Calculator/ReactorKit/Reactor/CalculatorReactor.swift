//
//  CalculatorReactor.swift
//  ReactorKitFeature
//
//  Created by jimmy on 2025/12/29.
//

import Foundation
import ReactorKit

public final class CalculatorReactor: Reactor {
    
    // MARK: - Action
    public enum Action {
        case inputNumber(Int)
        case setOperation(CalculatorOperation)
        case calculate
        case clear
        case dismissAlert
    }
    
    // MARK: - Mutation
    public enum Mutation {
        case setDisplay(String)
        case setAlert(AlertType?)
        case setCalculatorState(CalculatorState)
        case setError(Error)
    }
    
    // MARK: - State
    public struct State {
        var display: String
        var activeAlert: AlertType?
        var calculatorState: CalculatorState
        
        public init() {
            self.display = "0"
            self.activeAlert = nil
            self.calculatorState = .initial
        }
    }
    
    // MARK: - AlertType
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
    
    // MARK: - Properties
    public let initialState: State
    private let calculatorUseCase: CalculatorUseCaseProtocol
    
    // MARK: - Initialization
    public init(calculatorUseCase: CalculatorUseCaseProtocol = CalculatorUseCase()) {
        self.calculatorUseCase = calculatorUseCase
        self.initialState = State()
    }
    
    // MARK: - Reactor Protocol
    public func mutate(action: Action) -> Observable<Mutation> {
        switch action {
        case .inputNumber(let digit):
            return inputNumber(digit)
        case .setOperation(let operation):
            return setOperation(operation)
        case .calculate:
            return calculate()
        case .clear:
            return clearAll()
        case .dismissAlert:
            return .just(.setAlert(nil))
        }
    }
    
    public func reduce(state: State, mutation: Mutation) -> State {
        var newState = state
        
        switch mutation {
        case .setDisplay(let display):
            newState.display = display
        case .setAlert(let alert):
            newState.activeAlert = alert
        case .setCalculatorState(let calculatorState):
            newState.calculatorState = calculatorState
            newState.display = calculatorState.display
        case .setError(let error):
            newState.activeAlert = .error(error)
            newState.calculatorState = calculatorUseCase.clear()
            newState.display = newState.calculatorState.display
            print("계산기 오류: \(error.localizedDescription)")
        }
        
        return newState
    }
    
    // MARK: - Private Methods
    
    private func inputNumber(_ digit: Int) -> Observable<Mutation> {
        return Observable.create { [weak self] observer in
            guard let self = self else {
                observer.onCompleted()
                return Disposables.create()
            }
            
            do {
                let newState = try self.calculatorUseCase.inputNumber(digit, currentState: self.currentState.calculatorState)
                observer.onNext(.setCalculatorState(newState))
                observer.onCompleted()
            } catch {
                observer.onNext(.setError(error))
                observer.onCompleted()
            }
            
            return Disposables.create()
        }
    }
    
    private func setOperation(_ operation: CalculatorOperation) -> Observable<Mutation> {
        return Observable.create { [weak self] observer in
            guard let self = self else {
                observer.onCompleted()
                return Disposables.create()
            }
            
            do {
                let newState = try self.calculatorUseCase.setOperation(operation, currentState: self.currentState.calculatorState)
                observer.onNext(.setCalculatorState(newState))
                observer.onCompleted()
            } catch {
                observer.onNext(.setError(error))
                observer.onCompleted()
            }
            
            return Disposables.create()
        }
    }
    
    private func calculate() -> Observable<Mutation> {
        return Observable.create { [weak self] observer in
            guard let self = self else {
                observer.onCompleted()
                return Disposables.create()
            }
            
            Task {
                do {
                    let newState = try await self.calculatorUseCase.calculate(currentState: self.currentState.calculatorState)
                    observer.onNext(.setCalculatorState(newState))
                    observer.onCompleted()
                } catch {
                    observer.onNext(.setError(error))
                    observer.onCompleted()
                }
            }
            
            return Disposables.create()
        }
    }
    
    private func clearAll() -> Observable<Mutation> {
        return Observable.create { [weak self] observer in
            guard let self = self else {
                observer.onCompleted()
                return Disposables.create()
            }
            
            let newState = self.calculatorUseCase.clear()
            observer.onNext(.setCalculatorState(newState))
            observer.onCompleted()
            
            return Disposables.create()
        }
    }
}

