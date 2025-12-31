//
//  AutoRefreshViewModel.swift
//  AsyncViewModelExample
//
//  Created by jimmy on 2025/12/29.
//

import AsyncViewModel
import Foundation

/// AsyncTimer를 활용한 자동 새로고침 예시
@AsyncViewModel
final class AutoRefreshViewModel: ObservableObject {
    // MARK: - Types
    
    enum Input: Equatable, Sendable {
        case startAutoRefreshButtonTapped
        case stopAutoRefreshButtonTapped
        case manualRefreshButtonTapped
    }
    
    enum Action: Equatable, Sendable {
        case startAutoRefresh
        case refresh
        case updateData(String)
        case stopAutoRefresh
    }
    
    struct State: Equatable, Sendable {
        var data: String = ""
        var refreshCount: Int = 0
        var isAutoRefreshing: Bool = false
        var lastRefreshTime: Date?
    }
    
    enum CancelID: Hashable, Sendable {
        case autoRefresh
        case fetchData
    }
    
    // MARK: - Properties
    
    @Published var state: State
    
    // MARK: - Dependencies
    
    private let repository: DataRepository
    
    // MARK: - Initialization
    
    init(
        initialState: State = State(),
        repository: DataRepository
    ) {
        self.state = initialState
        self.repository = repository
    }
    
    // MARK: - Transform
    
    func transform(_ input: Input) -> [Action] {
        switch input {
        case .startAutoRefreshButtonTapped:
            return [.startAutoRefresh]
        case .stopAutoRefreshButtonTapped:
            return [.stopAutoRefresh]
        case .manualRefreshButtonTapped:
            return [.refresh]
        }
    }
    
    // MARK: - Reduce
    
    func reduce(state: inout State, action: Action) -> [AsyncEffect<Action, CancelID>] {
        switch action {
        case .startAutoRefresh:
            state.isAutoRefreshing = true
            // 5초마다 자동 새로고침
            return [
                .action(.refresh), // 즉시 첫 새로고침
                .timer(id: .autoRefresh, interval: 5.0, action: .refresh)
            ]
            
        case .refresh:
            state.refreshCount += 1
            return [
                .run(id: .fetchData) { [repository] in
                    let data = try await repository.fetchData()
                    return .updateData(data)
                }
            ]
            
        case let .updateData(data):
            state.data = data
            state.lastRefreshTime = Date()
            return [.none]
            
        case .stopAutoRefresh:
            state.isAutoRefreshing = false
            return [.cancel(id: .autoRefresh)]
        }
    }
    
    // MARK: - Error Handling
    
    func handleError(_ error: SendableError) {
        print("❌ 에러 발생: \(error.localizedDescription)")
    }
}

// MARK: - Dependencies

protocol DataRepository: Sendable {
    func fetchData() async throws -> String
}

struct MockDataRepository: DataRepository {
    nonisolated func fetchData() async throws -> String {
        try await Task.sleep(nanoseconds: 500_000_000) // 0.5초 지연
        return "데이터 \(Date())"
    }
}

