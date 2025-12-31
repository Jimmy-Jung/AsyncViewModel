//
//  HandleErrorExample.swift
//  AsyncViewModelExample
//
//  Created by jimmy on 2025/12/29.
//

import AsyncViewModel
import Foundation

/// handleError 사용 예시 모음

// MARK: - 방법 1: 직접 State 변경 (권장)

@AsyncViewModel
final class DirectStateErrorViewModel: ObservableObject {
    enum Input: Equatable, Sendable {
        case fetchButtonTapped
        case clearErrorButtonTapped
    }
    
    enum Action: Equatable, Sendable {
        case fetch
        case updateData(String)
    }
    
    struct State: Equatable, Sendable {
        var data: String = ""
        var errorMessage: String?
        var isLoading: Bool = false
    }
    
    enum CancelID: Hashable, Sendable {
        case fetch
    }
    
    @Published var state: State = State()
    
    func transform(_ input: Input) -> [Action] {
        switch input {
        case .fetchButtonTapped:
            return [.fetch]
        case .clearErrorButtonTapped:
            state.errorMessage = nil  // Input에서 직접 처리
            return []
        }
    }
    
    func reduce(state: inout State, action: Action) -> [AsyncEffect<Action, CancelID>] {
        switch action {
        case .fetch:
            state.isLoading = true
            state.errorMessage = nil
            return [
                .run(id: .fetch) {
                    try await Task.sleep(nanoseconds: 500_000_000)
                    // 에러 발생 시뮬레이션
                    throw SendableError(NSError(domain: "Network", code: -1, userInfo: [
                        NSLocalizedDescriptionKey: "네트워크 연결 실패"
                    ]))
                }
            ]
            
        case let .updateData(data):
            state.isLoading = false
            state.data = data
            return [.none]
        }
    }
    
    // ✅ 권장: 직접 State 변경
    func handleError(_ error: SendableError) {
        state.isLoading = false
        state.errorMessage = error.localizedDescription
    }
}

// MARK: - 방법 2: Input으로 에러 전달

@AsyncViewModel
final class InputErrorViewModel: ObservableObject {
    enum Input: Equatable, Sendable {
        case fetchButtonTapped
    }
    
    enum Action: Equatable, Sendable {
        case fetch
        case updateData(String)
        case handleError(SendableError)
    }
    
    struct State: Equatable, Sendable {
        var data: String = ""
        var errorMessage: String?
        var isLoading: Bool = false
    }
    
    enum CancelID: Hashable, Sendable {
        case fetch
    }
    
    @Published var state: State = State()
    
    func transform(_ input: Input) -> [Action] {
        switch input {
        case .fetchButtonTapped:
            return [.fetch]
        }
    }
    
    func reduce(state: inout State, action: Action) -> [AsyncEffect<Action, CancelID>] {
        switch action {
        case .fetch:
            state.isLoading = true
            state.errorMessage = nil
            return [
                .run(id: .fetch) {
                    try await Task.sleep(nanoseconds: 500_000_000)
                    throw SendableError(NSError(domain: "Network", code: -1))
                }
            ]
            
        case let .updateData(data):
            state.isLoading = false
            state.data = data
            return [.none]
            
        case let .handleError(error):
            state.isLoading = false
            state.errorMessage = error.localizedDescription
            return [.none]
        }
    }
    
    // ✅ Action으로 에러 처리 (권장)
    func handleError(_ error: SendableError) {
        perform(.handleError(error))
    }
}

// MARK: - 방법 3: 복잡한 에러 처리

@AsyncViewModel
final class ComplexErrorViewModel: ObservableObject {
    enum Input: Equatable, Sendable {
        case fetchButtonTapped
        case retryButtonTapped
    }
    
    enum Action: Equatable, Sendable {
        case fetch
        case updateData(String)
    }
    
    struct State: Equatable, Sendable {
        var data: String = ""
        var error: ErrorInfo?
        var isLoading: Bool = false
        var retryCount: Int = 0
        
        struct ErrorInfo: Equatable, Sendable {
            let message: String
            let canRetry: Bool
            let timestamp: Date
        }
    }
    
    enum CancelID: Hashable, Sendable {
        case fetch
    }
    
    @Published var state: State = State()
    
    func transform(_ input: Input) -> [Action] {
        switch input {
        case .fetchButtonTapped:
            return [.fetch]
        case .retryButtonTapped:
            guard state.error?.canRetry == true else { return [] }
            return [.fetch]
        }
    }
    
    func reduce(state: inout State, action: Action) -> [AsyncEffect<Action, CancelID>] {
        switch action {
        case .fetch:
            state.isLoading = true
            state.error = nil
            return [
                .run(id: .fetch) {
                    try await Task.sleep(nanoseconds: 500_000_000)
                    return .updateData("Success!")
                }
            ]
            
        case let .updateData(data):
            state.isLoading = false
            state.data = data
            state.retryCount = 0
            return [.none]
        }
    }
    
    // ✅ 복잡한 에러 처리 로직
    func handleError(_ error: SendableError) {
        state.isLoading = false
        state.retryCount += 1
        
        // 에러 타입별 처리
        let canRetry = state.retryCount < 3 && 
                      error.domain == NSURLErrorDomain && 
                      error.code != NSURLErrorNotConnectedToInternet
        
        state.error = State.ErrorInfo(
            message: error.localizedDescription,
            canRetry: canRetry,
            timestamp: Date()
        )
        
        // 자동 재시도 (선택적)
        if canRetry && state.retryCount <= 1 {
            Task { @MainActor in
                try? await Task.sleep(nanoseconds: 1_000_000_000)
                send(.retryButtonTapped)
            }
        }
    }
}

// MARK: - 사용 예시

/*
 // SwiftUI View에서
 struct ErrorHandlingExampleView: View {
     @StateObject var viewModel = DirectStateErrorViewModel()
     
     var body: some View {
         VStack {
             if let error = viewModel.state.errorMessage {
                 Text("에러: \(error)")
                     .foregroundColor(.red)
                 
                 Button("다시 시도") {
                     viewModel.send(.clearErrorButtonTapped)
                     viewModel.send(.fetchButtonTapped)
                 }
             }
         }
     }
 }
 */

