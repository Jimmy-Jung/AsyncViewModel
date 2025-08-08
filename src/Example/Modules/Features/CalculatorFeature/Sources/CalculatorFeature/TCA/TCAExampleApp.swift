//
//  TCAExampleApp.swift
//  CalculatorFeature
//
//  Created by 정준혁 on 2025/08/08
//

import SwiftUI
import ComposableArchitecture

// MARK: - TCA 버전 Calculator 사용 예제

/// TCA 패턴을 사용한 Calculator 예제
/// 
/// 사용 방법:
/// ```swift
/// @main
/// struct MyApp: App {
///     var body: some Scene {
///         WindowGroup {
///             TCACalculatorExampleView()
///         }
///     }
/// }
/// ```
struct TCACalculatorExampleView: View {
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                
                Text("Calculator Examples")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Text("TCA 패턴과 AsyncViewModel 패턴을 비교해보세요")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                
                VStack(spacing: 16) {
                    
                    // TCA 버전
                    NavigationLink(destination: tcaCalculatorView) {
                        ExampleCardView(
                            title: "TCA Calculator",
                            description: "The Composable Architecture 패턴을 사용한 계산기\n🚀 Effect & Cancellation 기능 포함",
                            color: .blue
                        )
                    }
                    
                    // AsyncViewModel 버전
                    NavigationLink(destination: asyncViewModelCalculatorView) {
                        ExampleCardView(
                            title: "AsyncViewModel Calculator", 
                            description: "AsyncViewModel 패턴을 사용한 계산기",
                            color: .green
                        )
                    }
                }
                
                Spacer()
                
                VStack(spacing: 8) {
                    Text("💡 두 패턴의 차이점을 직접 체험해보세요")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text("🚀 TCA 버전에서는 Effect 사용 예시를 확인할 수 있습니다!")
                        .font(.caption2)
                        .foregroundColor(.blue)
                        .multilineTextAlignment(.center)
                    
                    Text("계산 후 5초 뒤에 자동 클리어 • 새 입력 시 타이머 취소")
                        .font(.caption2)
                        .foregroundColor(.orange)
                        .multilineTextAlignment(.center)
                }
                .padding(.bottom)
            }
            .padding()
        }
    }
    
    // TCA 버전 계산기
    private var tcaCalculatorView: some View {
        CalculatorTCAView(
            store: Store(initialState: CalculatorFeature.State()) {
                CalculatorFeature()
            }
        )
        .navigationTitle("TCA Calculator")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    // AsyncViewModel 버전 계산기
    private var asyncViewModelCalculatorView: some View {
        CalculatorView(CalculatorAsyncViewModel())
            .navigationTitle("AsyncViewModel Calculator")
            .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Helper Views

struct ExampleCardView: View {
    let title: String
    let description: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(title)
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Image(systemName: "arrow.right")
                    .foregroundColor(color)
            }
            
            Text(description)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.leading)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(UIColor.systemBackground))
                .shadow(color: color.opacity(0.2), radius: 8, x: 0, y: 4)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(color.opacity(0.3), lineWidth: 1)
        )
    }
}

// MARK: - Preview

@available(iOS 17.0, *)
#Preview {
    TCACalculatorExampleView()
} 
