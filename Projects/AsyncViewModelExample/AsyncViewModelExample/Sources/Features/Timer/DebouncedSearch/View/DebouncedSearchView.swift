//
//  DebouncedSearchView.swift
//  AsyncViewModelExample
//
//  Created by jimmy on 2025/12/29.
//

import SwiftUI

struct DebouncedSearchView: View {
    @StateObject private var viewModel = DebouncedSearchViewModel(
        searchService: MockSearchService()
    )
    
    var body: some View {
        VStack(spacing: 0) {
            // 검색창
            VStack(spacing: 16) {
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.gray)
                    
                    TextField("검색어를 입력하세요", text: Binding(
                        get: { viewModel.state.query },
                        set: { viewModel.send(.searchTextChanged($0)) }
                    ))
                    .textFieldStyle(PlainTextFieldStyle())
                    
                    if !viewModel.state.query.isEmpty {
                        Button(action: {
                            viewModel.send(.clearButtonTapped)
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.gray)
                        }
                    }
                    
                    if viewModel.state.isSearching {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle())
                    }
                }
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(12)
                
                // 검색 상태 표시
                HStack {
                    Text("검색 쿼리:")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    if viewModel.state.query.isEmpty {
                        Text("없음")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .italic()
                    } else {
                        Text("\"\(viewModel.state.query)\"")
                            .font(.caption)
                            .foregroundColor(.blue)
                            .fontWeight(.medium)
                    }
                    
                    Spacer()
                    
                    Text("결과: \(viewModel.state.results.count)개")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal)
            }
            .padding()
            .background(Color.white)
            .shadow(color: Color.black.opacity(0.05), radius: 5, y: 2)
            
            // 검색 결과
            if viewModel.state.query.isEmpty {
                VStack(spacing: 16) {
                    Spacer()
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 64))
                        .foregroundColor(.gray.opacity(0.5))
                    Text("검색어를 입력해주세요")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    Text("0.3초 디바운스가 적용됩니다")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                }
                .frame(maxWidth: .infinity)
            } else if viewModel.state.isSearching {
                VStack(spacing: 16) {
                    Spacer()
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle())
                        .scaleEffect(1.5)
                    Text("검색 중...")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    Spacer()
                }
                .frame(maxWidth: .infinity)
            } else if viewModel.state.results.isEmpty {
                VStack(spacing: 16) {
                    Spacer()
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 64))
                        .foregroundColor(.gray.opacity(0.5))
                    Text("검색 결과가 없습니다")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    Spacer()
                }
                .frame(maxWidth: .infinity)
            } else {
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(Array(viewModel.state.results.enumerated()), id: \.offset) { index, result in
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Image(systemName: "doc.text")
                                        .foregroundColor(.blue)
                                    Text(result)
                                        .font(.body)
                                    Spacer()
                                    Text("#\(index + 1)")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                .padding()
                            }
                            .background(Color.white)
                            
                            if index < viewModel.state.results.count - 1 {
                                Divider()
                                    .padding(.leading, 52)
                            }
                        }
                    }
                }
            }
            
            Spacer()
        }
        .background(Color.gray.opacity(0.05))
        .navigationTitle("디바운스 검색 예제")
        .navigationBarTitleDisplayMode(.inline)
        .onDisappear {
            // 화면을 벗어날 때 검색 정리
            if !viewModel.state.query.isEmpty || viewModel.state.isSearching {
                viewModel.send(.clearButtonTapped)
            }
        }
    }
}

#Preview {
    NavigationView {
        DebouncedSearchView()
    }
}

