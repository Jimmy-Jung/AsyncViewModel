//
//  CountdownViewModel.swift
//  AsyncViewModelExample
//
//  Created by jimmy on 2025/12/29.
//

import AsyncViewModel
import Foundation

/// AsyncTimer를 활용한 카운트다운 타이머 예시
@AsyncViewModel
final class CountdownViewModel: ObservableObject {
    // MARK: - Types
    
    enum Input: Equatable, Sendable {
        case startButtonTapped
        case pauseButtonTapped
        case resumeButtonTapped
        case resetButtonTapped
    }
    
    enum Action: Equatable, Sendable {
        case startCountdown
        case tick
        case pauseCountdown
        case resumeCountdown
        case finishCountdown
        case resetCountdown
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
        case .startButtonTapped:
            return [.startCountdown]
        case .pauseButtonTapped:
            return [.pauseCountdown]
        case .resumeButtonTapped:
            return [.resumeCountdown]
        case .resetButtonTapped:
            return [.resetCountdown]
        }
    }
    
    // MARK: - Reduce
    
    func reduce(state: inout State, action: Action) -> [AsyncEffect<Action, CancelID>] {
        switch action {
        case .startCountdown:
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
                    .action(.finishCountdown)
                ]
            }
            
            return [.none]
            
        case .pauseCountdown:
            state.isPaused = true
            return [.cancel(id: .countdown)]
            
        case .resumeCountdown:
            state.isPaused = false
            // 타이머 재시작
            return [.timer(id: .countdown, interval: 1.0, action: .tick)]
            
        case .finishCountdown:
            // 완료 처리 (알림 등)
            print("⏰ 카운트다운 완료!")
            return [.none]
            
        case .resetCountdown:
            state.isRunning = false
            state.isPaused = false
            state.remainingSeconds = 60
            return [.cancel(id: .countdown)]
        }
    }
}

