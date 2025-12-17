//
//  CalculatorSwiftUIView.swift
//  SwiftUIFeature
//
//  Created by 정준영 on 2025/12/17
//

import SwiftUI

public struct CalculatorSwiftUIView: View {
    @StateObject private var viewModel: CalculatorSwiftUIViewModel
    
    public init(_ viewModel: CalculatorSwiftUIViewModel? = nil) {
        if let viewModel = viewModel {
            self._viewModel = StateObject(wrappedValue: viewModel)
        } else {
            self._viewModel = StateObject(wrappedValue: CalculatorSwiftUIViewModel())
        }
    }
    
    public var body: some View {
        VStack(spacing: .DS.lg) {
            CalculatorDisplayView(
                display: viewModel.state.display,
                isAutoClearActive: viewModel.state.isAutoClearTimerActive
            )
            
            CalculatorButtonsView(
                onNumberTap: { number in
                    viewModel.send(.number(number))
                },
                onOperationTap: { operation in
                    viewModel.send(.operation(operation))
                },
                onEqualsTap: {
                    viewModel.send(.equals)
                },
                onClearTap: {
                    viewModel.send(.clear)
                }
            )
        }
        .padding(.DS.lg)
        .background(
            Color(uiColor: .systemGroupedBackground)
                .ignoresSafeArea()
        )
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .navigationTitle("SwiftUI Calculator")
        .alert(item: $viewModel.state.activeAlert) { alertType in
            switch alertType {
            case .error(let error):
                return Alert(
                    title: Text("오류"),
                    message: Text(error.localizedDescription),
                    dismissButton: .default(Text("확인")) {
                        viewModel.send(.dismissAlert)
                    }
                )
            }
        }
    }
}

// MARK: - Display View
public struct CalculatorDisplayView: View {
    public let display: String
    public let isAutoClearActive: Bool
    
    public var body: some View {
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
                    .accessibilityIdentifier("calculator_display_swiftui")
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
public struct CalculatorButtonsView: View {
    public let onNumberTap: (Int) -> Void
    public let onOperationTap: (CalculatorOperation) -> Void
    public let onEqualsTap: () -> Void
    public let onClearTap: () -> Void
    
    private let buttonSpacing: CGFloat = 12
    
    public var body: some View {
        VStack(spacing: buttonSpacing) {
            HStack(spacing: buttonSpacing) {
                CalculatorButton(
                    title: "C",
                    backgroundColor: .orange,
                    accessibilityId: "clear_button_swiftui",
                    action: onClearTap
                )
                
                Spacer()
                Spacer()
                
                CalculatorButton(
                    title: "÷",
                    backgroundColor: .blue,
                    accessibilityId: "operation_button_divide_swiftui",
                    action: { onOperationTap(.divide) }
                )
            }
            
            HStack(spacing: buttonSpacing) {
                CalculatorButton(title: "7", accessibilityId: "number_button_7_swiftui", action: { onNumberTap(7) })
                CalculatorButton(title: "8", accessibilityId: "number_button_8_swiftui", action: { onNumberTap(8) })
                CalculatorButton(title: "9", accessibilityId: "number_button_9_swiftui", action: { onNumberTap(9) })
                CalculatorButton(title: "×", backgroundColor: .blue, accessibilityId: "operation_button_multiply_swiftui", action: { onOperationTap(.multiply) })
            }
            
            HStack(spacing: buttonSpacing) {
                CalculatorButton(title: "4", accessibilityId: "number_button_4_swiftui", action: { onNumberTap(4) })
                CalculatorButton(title: "5", accessibilityId: "number_button_5_swiftui", action: { onNumberTap(5) })
                CalculatorButton(title: "6", accessibilityId: "number_button_6_swiftui", action: { onNumberTap(6) })
                CalculatorButton(title: "-", backgroundColor: .blue, accessibilityId: "operation_button_subtract_swiftui", action: { onOperationTap(.subtract) })
            }
            
            HStack(spacing: buttonSpacing) {
                CalculatorButton(title: "1", accessibilityId: "number_button_1_swiftui", action: { onNumberTap(1) })
                CalculatorButton(title: "2", accessibilityId: "number_button_2_swiftui", action: { onNumberTap(2) })
                CalculatorButton(title: "3", accessibilityId: "number_button_3_swiftui", action: { onNumberTap(3) })
                CalculatorButton(title: "+", backgroundColor: .blue, accessibilityId: "operation_button_add_swiftui", action: { onOperationTap(.add) })
            }
            
            HStack(spacing: buttonSpacing) {
                CalculatorButton(title: "0", accessibilityId: "number_button_0_swiftui", action: { onNumberTap(0) })
                
                Spacer()
                
                CalculatorButton(title: "=", backgroundColor: .green, accessibilityId: "equals_button_swiftui", action: onEqualsTap)
            }
        }
    }
}

// MARK: - Button Component
public struct CalculatorButton: View {
    public let title: String
    public let backgroundColor: Color
    public let accessibilityId: String
    public let action: () -> Void
    
    init(title: String, backgroundColor: Color = .gray, accessibilityId: String = "", action: @escaping () -> Void) {
        self.title = title
        self.backgroundColor = backgroundColor
        self.accessibilityId = accessibilityId
        self.action = action
    }
    
    public var body: some View {
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
        CalculatorSwiftUIView()
    }
}

