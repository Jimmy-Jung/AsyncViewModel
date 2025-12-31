//
//  MultiTimerViewModel.swift
//  AsyncViewModelExample
//
//  Created by jimmy on 2025/12/29.
//

import AsyncViewModel
import Foundation

/// 여러 타이머를 동시에 관리하는 ViewModel
@AsyncViewModel
final class MultiTimerViewModel: ObservableObject {
    // MARK: - Types
    
    enum Input: Equatable, Sendable {
        case startTimerButtonTapped(TimerID)
        case stopTimerButtonTapped(TimerID)
        case resetTimerButtonTapped(TimerID)
        case startAllButtonTapped
        case stopAllButtonTapped
        case resetAllButtonTapped
    }
    
    enum Action: Equatable, Sendable {
        case startTimer(TimerID)
        case tick(TimerID)
        case stopTimer(TimerID)
        case resetTimer(TimerID)
    }
    
    struct State: Equatable, Sendable {
        var timers: [TimerID: TimerState] = [
            .timer1: TimerState(name: "타이머 1", interval: 1.0, color: "blue"),
            .timer2: TimerState(name: "타이머 2", interval: 0.5, color: "green"),
            .timer3: TimerState(name: "타이머 3", interval: 2.0, color: "orange"),
            .timer4: TimerState(name: "타이머 4", interval: 0.3, color: "purple")
        ]
        
        struct TimerState: Equatable, Sendable {
            let name: String
            let interval: TimeInterval
            let color: String
            var count: Int = 0
            var isRunning: Bool = false
        }
    }
    
    enum TimerID: String, Hashable, Sendable, CaseIterable {
        case timer1
        case timer2
        case timer3
        case timer4
    }
    
    enum CancelID: Hashable, Sendable {
        case timer(TimerID)
    }
    
    // MARK: - Properties
    
    @Published var state: State = State()
    
    // MARK: - Initialization
    
    init() {
        print("🟢 [MultiTimerViewModel] init called")
    }
    
    // MARK: - Transform
    
    func transform(_ input: Input) -> [Action] {
        switch input {
        case let .startTimerButtonTapped(id):
            return [.startTimer(id)]
            
        case let .stopTimerButtonTapped(id):
            return [.stopTimer(id)]
            
        case let .resetTimerButtonTapped(id):
            return [.resetTimer(id)]
            
        case .startAllButtonTapped:
            return TimerID.allCases.map { .startTimer($0) }
            
        case .stopAllButtonTapped:
            return TimerID.allCases.map { .stopTimer($0) }
            
        case .resetAllButtonTapped:
            return TimerID.allCases.map { .resetTimer($0) }
        }
    }
    
    // MARK: - Reduce
    
    func reduce(state: inout State, action: Action) -> [AsyncEffect<Action, CancelID>] {
        switch action {
        case let .startTimer(id):
            // 이미 실행 중인 타이머는 다시 시작하지 않음
            guard state.timers[id]?.isRunning == false else {
                return [.none]
            }
            
            state.timers[id]?.isRunning = true
            
            guard let interval = state.timers[id]?.interval else {
                return [.none]
            }
            
            return [
                .timer(id: .timer(id), interval: interval, action: .tick(id))
            ]
            
        case let .tick(id):
            guard state.timers[id]?.isRunning == true else {
                return [.none]
            }
            
            state.timers[id]?.count += 1
            return [.none]
            
        case let .stopTimer(id):
            state.timers[id]?.isRunning = false
            return [.cancel(id: .timer(id))]
            
        case let .resetTimer(id):
            state.timers[id]?.isRunning = false
            state.timers[id]?.count = 0
            return [.cancel(id: .timer(id))]
        }
    }
}

