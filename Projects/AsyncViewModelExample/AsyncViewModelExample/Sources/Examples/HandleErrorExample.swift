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
        case fetchData
        case clearError
    }
    
    enum Action: Equatable, Sendable {
        case startFetch
        case dataLoaded(String)
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
        case .fetchData:
            return [.startFetch]
        case .clearError:
            state.errorMessage = nil  // Input에서 직접 처리
            return []
        }
    }
    
    func reduce(state: inout State, action: Action) -> [AsyncEffect<Action, CancelID>] {
        switch action {
        case .startFetch:
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
            
        case let .dataLoaded(data):
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
        case fetchData
        case handleError(SendableError)  // ← 에러용 Input 추가
    }
    
    enum Action: Equatable, Sendable {
        case startFetch
        case dataLoaded(String)
        case errorOccurred(SendableError)
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
        case .fetchData:
            return [.startFetch]
        case let .handleError(error):
            return [.errorOccurred(error)]
        }
    }
    
    func reduce(state: inout State, action: Action) -> [AsyncEffect<Action, CancelID>] {
        switch action {
        case .startFetch:
            state.isLoading = true
            state.errorMessage = nil
            return [
                .run(id: .fetch) {
                    try await Task.sleep(nanoseconds: 500_000_000)
                    throw SendableError(NSError(domain: "Network", code: -1))
                }
            ]
            
        case let .dataLoaded(data):
            state.isLoading = false
            state.data = data
            return [.none]
            
        case let .errorOccurred(error):
            state.isLoading = false
            state.errorMessage = error.localizedDescription
            return [.none]
        }
    }
    
    // ✅ Input으로 에러 전달
    func handleError(_ error: SendableError) {
        send(.handleError(error))
    }
}

// MARK: - 방법 3: 복잡한 에러 처리

@AsyncViewModel
final class ComplexErrorViewModel: ObservableObject {
    enum Input: Equatable, Sendable {
        case fetchData
        case retryLastAction
    }
    
    enum Action: Equatable, Sendable {
        case startFetch
        case dataLoaded(String)
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
        case .fetchData:
            return [.startFetch]
        case .retryLastAction:
            guard state.error?.canRetry == true else { return [] }
            return [.startFetch]
        }
    }
    
    func reduce(state: inout State, action: Action) -> [AsyncEffect<Action, CancelID>] {
        switch action {
        case .startFetch:
            state.isLoading = true
            state.error = nil
            return [
                .run(id: .fetch) {
                    try await Task.sleep(nanoseconds: 500_000_000)
                    return .dataLoaded("Success!")
                }
            ]
            
        case let .dataLoaded(data):
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
                send(.retryLastAction)
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
                     viewModel.send(.clearError)
                     viewModel.send(.fetchData)
                 }
             }
         }
     }
 }
 */

