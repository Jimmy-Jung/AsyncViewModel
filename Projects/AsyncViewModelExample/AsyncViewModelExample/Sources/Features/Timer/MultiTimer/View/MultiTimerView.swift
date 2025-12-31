//
//  MultiTimerView.swift
//  AsyncViewModelExample
//
//  Created by jimmy on 2025/12/29.
//

import AsyncViewModel
import SwiftUI

/// 여러 타이머를 동시에 표시하는 화면
struct MultiTimerView: View {
    @StateObject private var viewModel = MultiTimerViewModel()
    
    var body: some View {
        VStack(spacing: 0) {
            // 타이머 그리드
            ScrollView {
                LazyVGrid(
                    columns: [
                        GridItem(.flexible(), spacing: 16),
                        GridItem(.flexible(), spacing: 16)
                    ],
                    spacing: 16
                ) {
                    ForEach(MultiTimerViewModel.TimerID.allCases, id: \.self) { timerID in
                        if let timerState = viewModel.state.timers[timerID] {
                            TimerCardView(
                                timerState: timerState,
                                timerID: timerID,
                                onAction: { action in
                                    switch action {
                                    case .start: viewModel.send(.startTimerButtonTapped(timerID))
                                    case .stop: viewModel.send(.stopTimerButtonTapped(timerID))
                                    case .reset: viewModel.send(.resetTimerButtonTapped(timerID))
                                    }
                                }
                            )
                        }
                    }
                }
                .padding()
            }
            
            // 전체 컨트롤
            VStack(spacing: 12) {
                Divider()
                
                Text("전체 컨트롤")
                    .font(.headline)
                    .foregroundColor(.secondary)
                
                HStack(spacing: 12) {
                    Button {
                        viewModel.send(.startAllButtonTapped)
                    } label: {
                        Label("모두 시작", systemImage: "play.fill")
                            .font(.subheadline)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(Color.green)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                    
                    Button {
                        viewModel.send(.stopAllButtonTapped)
                    } label: {
                        Label("모두 중지", systemImage: "stop.fill")
                            .font(.subheadline)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(Color.orange)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                    
                    Button {
                        viewModel.send(.resetAllButtonTapped)
                    } label: {
                        Label("모두 초기화", systemImage: "arrow.counterclockwise")
                            .font(.subheadline)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(Color.gray.opacity(0.2))
                            .foregroundColor(.primary)
                            .cornerRadius(10)
                    }
                }
                .padding(.horizontal)
            }
            .padding(.vertical)
            .background(Color(.systemBackground))
        }
        .navigationTitle("멀티 타이머")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            print("🟢 [MultiTimerView] onAppear")
        }
        .onDisappear {
            print("🔴 [MultiTimerView] onDisappear")
            // SwiftUI의 생명주기 특성상 명시적으로 정리
            viewModel.send(.stopAllButtonTapped)
        }
    }
}

// MARK: - Timer Card

enum TimerCardAction {
    case start
    case stop
    case reset
}

struct TimerCardView: View {
    let timerState: MultiTimerViewModel.State.TimerState
    let timerID: MultiTimerViewModel.TimerID
    let onAction: (TimerCardAction) -> Void
    
    var body: some View {
        VStack(spacing: 12) {
            // 헤더
            HStack {
                Circle()
                    .fill(cardColor)
                    .frame(width: 12, height: 12)
                
                Text(timerState.name)
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Spacer()
                
                if timerState.isRunning {
                    Image(systemName: "timer")
                        .foregroundColor(cardColor)
                }
            }
            
            // 카운트 표시
            VStack(spacing: 4) {
                Text("\(timerState.count)")
                    .font(.system(size: 48, weight: .bold, design: .rounded))
                    .foregroundColor(cardColor)
                    .monospacedDigit()
                
                Text("\(String(format: "%.1f", timerState.interval))초 간격")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            
            // 컨트롤 버튼
            HStack(spacing: 8) {
                Button {
                    if timerState.isRunning {
                        onAction(.stop)
                    } else {
                        onAction(.start)
                    }
                } label: {
                    Image(systemName: timerState.isRunning ? "pause.fill" : "play.fill")
                        .font(.title3)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(timerState.isRunning ? Color.orange : cardColor)
                        .cornerRadius(8)
                }
                
                Button {
                    onAction(.reset)
                } label: {
                    Image(systemName: "arrow.counterclockwise")
                        .font(.title3)
                        .foregroundColor(.primary)
                        .frame(width: 44)
                        .padding(.vertical, 8)
                        .background(Color.gray.opacity(0.2))
                        .cornerRadius(8)
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.secondarySystemBackground))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(timerState.isRunning ? cardColor : Color.clear, lineWidth: 2)
        )
    }
    
    private var cardColor: Color {
        switch timerState.color {
        case "blue": return .blue
        case "green": return .green
        case "orange": return .orange
        case "purple": return .purple
        default: return .gray
        }
    }
}

// MARK: - Preview

#Preview("멀티 타이머") {
    NavigationView {
        MultiTimerView()
    }
}

#Preview("타이머 카드") {
    TimerCardView(
        timerState: MultiTimerViewModel.State.TimerState(
            name: "타이머 1",
            interval: 1.0,
            color: "blue",
            count: 42,
            isRunning: true
        ),
        timerID: .timer1,
        onAction: { _ in }
    )
    .padding()
}

