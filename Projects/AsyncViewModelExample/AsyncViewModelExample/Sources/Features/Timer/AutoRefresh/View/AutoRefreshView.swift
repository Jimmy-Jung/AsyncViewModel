//
//  AutoRefreshView.swift
//  AsyncViewModelExample
//
//  Created by jimmy on 2025/12/29.
//

import SwiftUI

struct AutoRefreshView: View {
    @StateObject private var viewModel = AutoRefreshViewModel(
        repository: MockDataRepository()
    )
    
    var body: some View {
        VStack(spacing: 24) {
            // 타이틀
            Text("자동 새로고침")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            // 상태 정보
            VStack(spacing: 12) {
                HStack {
                    Text("새로고침 횟수:")
                        .fontWeight(.medium)
                    Spacer()
                    Text("\(viewModel.state.refreshCount)")
                        .foregroundColor(.blue)
                        .fontWeight(.bold)
                }
                
                HStack {
                    Text("마지막 새로고침:")
                        .fontWeight(.medium)
                    Spacer()
                    if let lastRefreshTime = viewModel.state.lastRefreshTime {
                        Text(lastRefreshTime, style: .time)
                            .foregroundColor(.secondary)
                    } else {
                        Text("없음")
                            .foregroundColor(.secondary)
                    }
                }
                
                HStack {
                    Text("자동 새로고침:")
                        .fontWeight(.medium)
                    Spacer()
                    Circle()
                        .fill(viewModel.state.isAutoRefreshing ? Color.green : Color.gray)
                        .frame(width: 12, height: 12)
                    Text(viewModel.state.isAutoRefreshing ? "활성" : "비활성")
                        .foregroundColor(viewModel.state.isAutoRefreshing ? .green : .gray)
                        .fontWeight(.semibold)
                }
            }
            .padding()
            .background(Color.gray.opacity(0.1))
            .cornerRadius(12)
            
            // 데이터 표시
            VStack(alignment: .leading, spacing: 8) {
                Text("현재 데이터:")
                    .font(.headline)
                    .foregroundColor(.secondary)
                
                if viewModel.state.data.isEmpty {
                    Text("데이터 없음")
                        .foregroundColor(.secondary)
                        .italic()
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.vertical, 32)
                } else {
                    Text(viewModel.state.data)
                        .font(.body)
                        .foregroundColor(.primary)
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(8)
                }
            }
            .padding()
            .background(Color.gray.opacity(0.05))
            .cornerRadius(12)
            
            Spacer()
            
            // 컨트롤 버튼
            VStack(spacing: 12) {
                Button(action: {
                    if viewModel.state.isAutoRefreshing {
                        viewModel.send(.stopAutoRefreshButtonTapped)
                    } else {
                        viewModel.send(.startAutoRefreshButtonTapped)
                    }
                }) {
                    HStack {
                        Image(systemName: viewModel.state.isAutoRefreshing ? "stop.fill" : "play.fill")
                        Text(viewModel.state.isAutoRefreshing ? "자동 새로고침 중지" : "자동 새로고침 시작")
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(viewModel.state.isAutoRefreshing ? Color.red : Color.green)
                    .cornerRadius(12)
                }
                
                Button(action: {
                    viewModel.send(.manualRefreshButtonTapped)
                }) {
                    HStack {
                        Image(systemName: "arrow.clockwise")
                        Text("수동 새로고침")
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(12)
                }
            }
        }
        .padding()
        .navigationTitle("자동 새로고침 예제")
        .navigationBarTitleDisplayMode(.inline)
        .onDisappear {
            // 화면을 벗어날 때 자동 새로고침 중지
            if viewModel.state.isAutoRefreshing {
                viewModel.send(.stopAutoRefreshButtonTapped)
            }
        }
    }
}

#Preview {
    NavigationView {
        AutoRefreshView()
    }
}

