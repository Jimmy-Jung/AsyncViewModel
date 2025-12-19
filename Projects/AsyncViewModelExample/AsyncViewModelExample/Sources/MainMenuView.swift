//
//  MainMenuView.swift
//  AsyncViewModelExample
//
//  Created by 정준혁 on 2025/12/17
//

import ComposableArchitecture
import SwiftUI

struct MainMenuView: View {
    
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        List {
            Section {
                Text("AsyncViewModel 예제")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                    .listRowBackground(Color.clear)
                    .listRowInsets(EdgeInsets(top: 20, leading: 20, bottom: 10, trailing: 20))
                
                Text("다양한 아키텍처 패턴으로 구현된 계산기 앱")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .listRowBackground(Color.clear)
                    .listRowInsets(EdgeInsets(top: 0, leading: 20, bottom: 20, trailing: 20))
            }
            
            Section(header: Text("UIKit 예제")) {
                NavigationLink {
                    UIKitCalculatorWrapper(title: "UIKit + AsyncViewModel")
                        .navigationBarTitleDisplayMode(.inline)
                } label: {
                    ExampleRow(
                        icon: "hammer.fill",
                        title: "UIKit + AsyncViewModel",
                        description: "코드 기반 UIKit 구현",
                        color: .blue
                    )
                }
                
                NavigationLink {
                    ReactorKitCalculatorWrapper()
                        .navigationBarTitleDisplayMode(.inline)
                } label: {
                    ExampleRow(
                        icon: "arrow.triangle.2.circlepath",
                        title: "ReactorKit",
                        description: "단방향 데이터 플로우",
                        color: .purple
                    )
                }
                
                NavigationLink {
                    TCAUIKitCalculatorWrapper()
                        .navigationBarTitleDisplayMode(.inline)
                } label: {
                    ExampleRow(
                        icon: "building.columns.fill",
                        title: "TCA UIKit",
                        description: "The Composable Architecture",
                        color: .orange
                    )
                }
            }
            
            Section(header: Text("SwiftUI 예제")) {
                NavigationLink {
                    CalculatorSwiftUIView()
                        .navigationBarTitleDisplayMode(.inline)
                } label: {
                    ExampleRow(
                        icon: "swift",
                        title: "SwiftUI + AsyncViewModel",
                        description: "선언형 UI 구현",
                        color: .green
                    )
                }
                
                NavigationLink {
                    CalculatorTCASwiftUIView()
                        .navigationBarTitleDisplayMode(.inline)
                } label: {
                    ExampleRow(
                        icon: "sparkles",
                        title: "TCA SwiftUI",
                        description: "함수형 아키텍처",
                        color: .pink
                    )
                }
            }
        }
        .navigationTitle("계산기 예제")
        .listStyle(.insetGrouped)
    }
}

// MARK: - Example Row
struct ExampleRow: View {
    let icon: String
    let title: String
    let description: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.white)
                .frame(width: 44, height: 44)
                .background(
                    LinearGradient(
                        gradient: Gradient(colors: [color, color.opacity(0.7)]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .cornerRadius(10)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - UIKit Wrappers
struct UIKitCalculatorWrapper: UIViewControllerRepresentable {
    let title: String
    
    @MainActor
    func makeUIViewController(context: Context) -> CalculatorUIKitViewController {
        let vc = CalculatorUIKitViewController()
        vc.title = title
        return vc
    }
    
    func updateUIViewController(_ uiViewController: CalculatorUIKitViewController, context: Context) {}
}

struct ReactorKitCalculatorWrapper: UIViewControllerRepresentable {
    @MainActor
    func makeUIViewController(context: Context) -> CalculatorReactorViewController {
        let vc = CalculatorReactorViewController()
        vc.title = "ReactorKit Calculator"
        return vc
    }
    
    func updateUIViewController(_ uiViewController: CalculatorReactorViewController, context: Context) {}
}

struct TCAUIKitCalculatorWrapper: UIViewControllerRepresentable {
    @MainActor
    func makeUIViewController(context: Context) -> CalculatorTCAUIKitViewController {
        let store = Store(initialState: CalculatorTCAFeature.State()) {
            CalculatorTCAFeature()
        }
        let vc = CalculatorTCAUIKitViewController(store: store)
        vc.title = "TCA UIKit Calculator"
        return vc
    }
    
    func updateUIViewController(_ uiViewController: CalculatorTCAUIKitViewController, context: Context) {}
}

// MARK: - Preview
#Preview {
    NavigationView {
        MainMenuView()
    }
}

