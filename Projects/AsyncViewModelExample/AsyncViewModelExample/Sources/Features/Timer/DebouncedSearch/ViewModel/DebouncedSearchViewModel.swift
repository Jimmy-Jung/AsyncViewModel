//
//  DebouncedSearchViewModel.swift
//  AsyncViewModelExample
//
//  Created by jimmy on 2025/12/29.
//

import AsyncViewModel
import Foundation

/// AsyncTimer를 활용한 디바운스 검색 예시
@AsyncViewModel
final class DebouncedSearchViewModel: ObservableObject {
    // MARK: - Types
    
    enum Input: Equatable, Sendable {
        case searchTextChanged(String)
        case clearButtonTapped
    }
    
    enum Action: Equatable, Sendable {
        case updateQuery(String)
        case performSearch(String)
        case updateSearchResults([String])
        case clearSearch
    }
    
    struct State: Equatable, Sendable {
        var query: String = ""
        var results: [String] = []
        var isSearching: Bool = false
    }
    
    enum CancelID: Hashable, Sendable {
        case search
    }
    
    // MARK: - Properties
    
    @Published var state: State
    
    // MARK: - Dependencies
    
    private let searchService: SearchService
    
    // MARK: - Initialization
    
    init(
        initialState: State = State(),
        searchService: SearchService
    ) {
        self.state = initialState
        self.searchService = searchService
    }
    
    // MARK: - Transform
    
    func transform(_ input: Input) -> [Action] {
        switch input {
        case let .searchTextChanged(query):
            return [.updateQuery(query)]
        case .clearButtonTapped:
            return [.clearSearch]
        }
    }
    
    // MARK: - Reduce
    
    func reduce(state: inout State, action: Action) -> [AsyncEffect<Action, CancelID>] {
        switch action {
        case let .updateQuery(query):
            state.query = query
            
            guard !query.isEmpty else {
                return [.cancel(id: .search)]
            }
            
            // 0.3초 디바운스
            return [
                .cancel(id: .search), // 이전 검색 취소
                .run(id: .search) {
                    try await Task.sleep(nanoseconds: 300_000_000) // 0.3초
                    return .performSearch(query)
                }
            ]
            
        case let .performSearch(query):
            state.isSearching = true
            return [
                .run(id: .search) { [searchService] in
                    let results = try await searchService.search(query: query)
                    return .updateSearchResults(results)
                }
            ]
            
        case let .updateSearchResults(results):
            state.isSearching = false
            state.results = results
            return [.none]
            
        case .clearSearch:
            state.query = ""
            state.results = []
            state.isSearching = false
            return [.cancel(id: .search)]
        }
    }
    
    // MARK: - Error Handling
    
    func handleError(_ error: SendableError) {
        state.isSearching = false
        print("❌ 검색 에러: \(error.localizedDescription)")
    }
}

// MARK: - Search Dependencies

protocol SearchService: Sendable {
    func search(query: String) async throws -> [String]
}

struct MockSearchService: SearchService {
    nonisolated func search(query: String) async throws -> [String] {
        try await Task.sleep(nanoseconds: 200_000_000) // 0.2초 지연
        return (1...5).map { "\(query) 결과 \($0)" }
    }
}

