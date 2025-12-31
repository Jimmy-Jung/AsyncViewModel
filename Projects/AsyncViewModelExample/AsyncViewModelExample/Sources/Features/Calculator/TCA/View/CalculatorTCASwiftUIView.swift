//
//  CalculatorTCASwiftUIView.swift
//  TCAFeature
//
//  Created by jimmy on 2025/12/29.
//

import ComposableArchitecture
import SwiftUI

public struct CalculatorTCASwiftUIView: View {
    let store: StoreOf<CalculatorTCAFeature>
    
    public init(store: StoreOf<CalculatorTCAFeature>? = nil) {
        self.store = store ?? Store(initialState: CalculatorTCAFeature.State()) {
            CalculatorTCAFeature()
        }
    }
    
    public var body: some View {
        WithPerceptionTracking {
            VStack(spacing: .DS.lg) {
                CalculatorTCADisplayView(
                    display: store.display,
                    isAutoClearActive: store.isAutoClearTimerActive
                )
                
                CalculatorTCAButtonsView(
                    onNumberTap: { number in
                        store.send(.numberTapped(number))
                    },
                    onOperationTap: { operation in
                        store.send(.operationTapped(operation))
                    },
                    onEqualsTap: {
                        store.send(.equalsTapped)
                    },
                    onClearTap: {
                        store.send(.clearTapped)
                    }
                )
            }
            .padding(.DS.lg)
            .background(
                Color(uiColor: .systemGroupedBackground)
                    .ignoresSafeArea()
            )
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .navigationTitle("TCA SwiftUI")
            .alert(
                item: Binding<CalculatorTCAFeature.State.AlertType?>(
                    get: { store.activeAlert },
                    set: { _ in store.send(.dismissAlert) }
                )
            ) { alertType in
                switch alertType {
                case .error(let error):
                    return Alert(
                        title: Text("오류"),
                        message: Text(error.localizedDescription),
                        dismissButton: .default(Text("확인")) {
                            store.send(.dismissAlert)
                        }
                    )
                }
            }
        }
    }
}

// MARK: - Display View
struct CalculatorTCADisplayView: View {
    let display: String
    let isAutoClearActive: Bool
    
    var body: some View {
        VStack {
            if isAutoClearActive {
                HStack {
                    Image(systemName: "timer")
                        .foregroundColor(.orange)
                    Text("5초 후 자동 클리어됩니다")
                        .font(.caption)
                        .foregroundColor(.orange)
                    Spacer()
                }
                .padding(.horizontal)
                .padding(.top, 8)
            }
            
            Spacer()
            
            HStack {
                Spacer()
                Text(display)
                    .font(.system(size: 48, weight: .light, design: .default))
                    .foregroundColor(.DS.primaryText)
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
                    .accessibilityIdentifier("calculator_display_tca_swiftui")
            }
        }
        .frame(height: isAutoClearActive ? 140 : 120)
        .padding(.horizontal, .DS.lg)
        .background(
            RoundedRectangle(cornerRadius: .DS.buttonRadius)
                .fill(Color(uiColor: .secondarySystemGroupedBackground))
                .overlay(
                    RoundedRectangle(cornerRadius: .DS.buttonRadius)
                        .stroke(isAutoClearActive ? Color.orange.opacity(0.6) : Color.clear, lineWidth: 2)
                )
                .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
        )
        .animation(.easeInOut(duration: 0.3), value: isAutoClearActive)
    }
}

// MARK: - Buttons View
struct CalculatorTCAButtonsView: View {
    let onNumberTap: (Int) -> Void
    let onOperationTap: (CalculatorOperation) -> Void
    let onEqualsTap: () -> Void
    let onClearTap: () -> Void
    
    private let buttonSpacing: CGFloat = 12
    
    var body: some View {
        VStack(spacing: buttonSpacing) {
            HStack(spacing: buttonSpacing) {
                CalculatorTCAButton(
                    title: "C",
                    backgroundColor: .orange,
                    accessibilityId: "clear_button_tca_swiftui",
                    action: onClearTap
                )
                
                Spacer()
                Spacer()
                
                CalculatorTCAButton(
                    title: "÷",
                    backgroundColor: .blue,
                    accessibilityId: "operation_button_divide_tca_swiftui",
                    action: { onOperationTap(.divide) }
                )
            }
            
            HStack(spacing: buttonSpacing) {
                CalculatorTCAButton(title: "7", accessibilityId: "number_button_7_tca_swiftui", action: { onNumberTap(7) })
                CalculatorTCAButton(title: "8", accessibilityId: "number_button_8_tca_swiftui", action: { onNumberTap(8) })
                CalculatorTCAButton(title: "9", accessibilityId: "number_button_9_tca_swiftui", action: { onNumberTap(9) })
                CalculatorTCAButton(title: "×", backgroundColor: .blue, accessibilityId: "operation_button_multiply_tca_swiftui", action: { onOperationTap(.multiply) })
            }
            
            HStack(spacing: buttonSpacing) {
                CalculatorTCAButton(title: "4", accessibilityId: "number_button_4_tca_swiftui", action: { onNumberTap(4) })
                CalculatorTCAButton(title: "5", accessibilityId: "number_button_5_tca_swiftui", action: { onNumberTap(5) })
                CalculatorTCAButton(title: "6", accessibilityId: "number_button_6_tca_swiftui", action: { onNumberTap(6) })
                CalculatorTCAButton(title: "-", backgroundColor: .blue, accessibilityId: "operation_button_subtract_tca_swiftui", action: { onOperationTap(.subtract) })
            }
            
            HStack(spacing: buttonSpacing) {
                CalculatorTCAButton(title: "1", accessibilityId: "number_button_1_tca_swiftui", action: { onNumberTap(1) })
                CalculatorTCAButton(title: "2", accessibilityId: "number_button_2_tca_swiftui", action: { onNumberTap(2) })
                CalculatorTCAButton(title: "3", accessibilityId: "number_button_3_tca_swiftui", action: { onNumberTap(3) })
                CalculatorTCAButton(title: "+", backgroundColor: .blue, accessibilityId: "operation_button_add_tca_swiftui", action: { onOperationTap(.add) })
            }
            
            HStack(spacing: buttonSpacing) {
                CalculatorTCAButton(title: "0", accessibilityId: "number_button_0_tca_swiftui", action: { onNumberTap(0) })
                
                Spacer()
                
                CalculatorTCAButton(title: "=", backgroundColor: .green, accessibilityId: "equals_button_tca_swiftui", action: onEqualsTap)
            }
        }
    }
}

// MARK: - Button Component
struct CalculatorTCAButton: View {
    let title: String
    let backgroundColor: Color
    let accessibilityId: String
    let action: () -> Void
    
    init(title: String, backgroundColor: Color = .gray, accessibilityId: String = "", action: @escaping () -> Void) {
        self.title = title
        self.backgroundColor = backgroundColor
        self.accessibilityId = accessibilityId
        self.action = action
    }
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 24, weight: .medium))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .aspectRatio(1, contentMode: .fit)
        }
        .frame(height: 60)
        .background(
            RoundedRectangle(cornerRadius: .DS.buttonRadius)
                .fill(backgroundColor)
        )
        .accessibilityIdentifier(accessibilityId)
    }
}

// MARK: - Preview
@available(iOS 17.0, *)
#Preview {
    NavigationView {
        CalculatorTCASwiftUIView()
    }
}

