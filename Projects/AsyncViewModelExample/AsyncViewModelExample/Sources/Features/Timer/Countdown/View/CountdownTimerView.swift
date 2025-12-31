//
//  CountdownTimerView.swift
//  AsyncViewModelExample
//
//  Created by jimmy on 2025/12/29.
//

import AsyncViewModel
import SwiftUI

/// CountdownViewModel을 사용한 타이머 화면
struct CountdownTimerView: View {
    @StateObject private var viewModel: CountdownViewModel
    
    init(initialSeconds: Int = 60) {
        _viewModel = StateObject(wrappedValue: CountdownViewModel(initialSeconds: initialSeconds))
    }
    
    var body: some View {
        VStack(spacing: 40) {
            Spacer()
            
            // 타이머 디스플레이
            ZStack {
                // 배경 원
                Circle()
                    .stroke(Color.gray.opacity(0.2), lineWidth: 20)
                    .frame(width: 280, height: 280)
                
                // 진행 원
                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(
                        LinearGradient(
                            colors: gradientColors,
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        style: StrokeStyle(lineWidth: 20, lineCap: .round)
                    )
                    .frame(width: 280, height: 280)
                    .rotationEffect(.degrees(-90))
                    .animation(.linear(duration: 0.5), value: progress)
                
                // 시간 표시
                VStack(spacing: 8) {
                    Text(timeString)
                        .font(.system(size: 72, weight: .bold, design: .rounded))
                        .foregroundColor(.primary)
                        .monospacedDigit()
                    
                    Text(statusText)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            // 컨트롤 버튼
            HStack(spacing: 20) {
                if !viewModel.state.isRunning {
                    // 시작 버튼
                    Button {
                        viewModel.send(.startButtonTapped)
                    } label: {
                        Label("시작", systemImage: "play.fill")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.green)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                    }
                } else {
                    // 일시정지/재개 버튼
                    Button {
                        if viewModel.state.isPaused {
                            viewModel.send(.resumeButtonTapped)
                        } else {
                            viewModel.send(.pauseButtonTapped)
                        }
                    } label: {
                        Label(
                            viewModel.state.isPaused ? "재개" : "일시정지",
                            systemImage: viewModel.state.isPaused ? "play.fill" : "pause.fill"
                        )
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(viewModel.state.isPaused ? Color.blue : Color.orange)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                    }
                }
                
                // 리셋 버튼
                Button {
                    viewModel.send(.resetButtonTapped)
                } label: {
                    Label("초기화", systemImage: "arrow.counterclockwise")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.gray.opacity(0.2))
                        .foregroundColor(.primary)
                        .cornerRadius(12)
                }
            }
            .padding(.horizontal)
            .padding(.bottom, 40)
        }
        .navigationTitle("카운트다운 타이머")
        .navigationBarTitleDisplayMode(.inline)
        .onDisappear {
            // 화면을 벗어날 때 타이머 정리
            if viewModel.state.isRunning {
                viewModel.send(.resetButtonTapped)
            }
        }
    }
    
    // MARK: - Computed Properties
    
    private var timeString: String {
        let minutes = viewModel.state.remainingSeconds / 60
        let seconds = viewModel.state.remainingSeconds % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
    
    private var progress: CGFloat {
        let total: Double = 60.0
        let remaining = Double(viewModel.state.remainingSeconds)
        return CGFloat(remaining / total)
    }
    
    private var statusText: String {
        if !viewModel.state.isRunning {
            return "대기 중"
        } else if viewModel.state.isPaused {
            return "일시정지됨"
        } else {
            return "진행 중"
        }
    }
    
    private var gradientColors: [Color] {
        if viewModel.state.remainingSeconds <= 10 {
            return [.red, .orange]
        } else if viewModel.state.remainingSeconds <= 30 {
            return [.orange, .yellow]
        } else {
            return [.green, .blue]
        }
    }
}

// MARK: - Preview
#Preview("카운트다운 60초") {
    NavigationView {
        CountdownTimerView(initialSeconds: 60)
    }
}

#Preview("카운트다운 10초") {
    NavigationView {
        CountdownTimerView(initialSeconds: 10)
    }
}

