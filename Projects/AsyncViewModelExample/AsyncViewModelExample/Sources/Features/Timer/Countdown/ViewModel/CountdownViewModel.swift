//
//  CountdownViewModel.swift
//  AsyncViewModelExample
//
//  Created by jimmy on 2025/12/24.
//

import AsyncViewModel
import Foundation

/// AsyncTimer를 활용한 카운트다운 타이머 예시
@AsyncViewModel
final class CountdownViewModel: ObservableObject {
    // MARK: - Types
    
    enum Input: Equatable, Sendable {
        case startCountdown
        case pauseCountdown
        case resumeCountdown
        case resetCountdown
    }
    
    enum Action: Equatable, Sendable {
        case countdownStarted
        case tick
        case countdownPaused
        case countdownResumed
        case countdownFinished
        case countdownReset
    }
    
    struct State: Equatable, Sendable {
        var remainingSeconds: Int = 60
        var isRunning: Bool = false
        var isPaused: Bool = false
    }
    
    enum CancelID: Hashable, Sendable {
        case countdown
    }
    
    // MARK: - Properties
    
    @Published var state: State
    
    // MARK: - Initialization
    
    init(initialSeconds: Int = 60) {
        self.state = State(remainingSeconds: initialSeconds)
    }
    
    // MARK: - Transform
    
    func transform(_ input: Input) -> [Action] {
        switch input {
        case .startCountdown:
            return [.countdownStarted]
        case .pauseCountdown:
            return [.countdownPaused]
        case .resumeCountdown:
            return [.countdownResumed]
        case .resetCountdown:
            return [.countdownReset]
        }
    }
    
    // MARK: - Reduce
    
    func reduce(state: inout State, action: Action) -> [AsyncEffect<Action, CancelID>] {
        switch action {
        case .countdownStarted:
            state.isRunning = true
            state.isPaused = false
            // 1초마다 tick Action 실행
            return [.timer(id: .countdown, interval: 1.0, action: .tick)]
            
        case .tick:
            guard state.isRunning && !state.isPaused else {
                return [.none]
            }
            
            state.remainingSeconds -= 1
            
            if state.remainingSeconds <= 0 {
                state.isRunning = false
                return [
                    .cancel(id: .countdown),
                    .action(.countdownFinished)
                ]
            }
            
            return [.none]
            
        case .countdownPaused:
            state.isPaused = true
            return [.cancel(id: .countdown)]
            
        case .countdownResumed:
            state.isPaused = false
            // 타이머 재시작
            return [.timer(id: .countdown, interval: 1.0, action: .tick)]
            
        case .countdownFinished:
            // 완료 처리 (알림 등)
            print("⏰ 카운트다운 완료!")
            return [.none]
            
        case .countdownReset:
            state.isRunning = false
            state.isPaused = false
            state.remainingSeconds = 60
            return [.cancel(id: .countdown)]
        }
    }
}

