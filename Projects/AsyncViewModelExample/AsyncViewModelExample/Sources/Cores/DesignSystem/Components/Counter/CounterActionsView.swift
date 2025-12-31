//
//  CounterActionsView.swift
//  DesignSystem
//
//  Created by jimmy on 2025/12/29.
//

import SwiftUI

public struct CounterActionsView: View {
    public let isIncreaseLoading: Bool
    public let isDecreaseLoading: Bool
    public let onIncrease: () -> Void
    public let onDecrease: () -> Void
    public let onReset: () -> Void
    public let onShow: () -> Void
    
    public var body: some View {
        VStack(spacing: .DS.md) {
            ActionButton(
                title: "Increase",
                iconName: "plus",
                isLoading: isIncreaseLoading,
                action: onIncrease
            )
            
            ActionButton(
                title: "Decrease",
                iconName: "minus",
                isLoading: isDecreaseLoading,
                action: onDecrease
            )
            
            ActionButton(
                title: "Reset",
                iconName: "arrow.counterclockwise.circle",
                isLoading: false,
                action: onReset
            )
            
            ActionButton(
                title: "Show",
                iconName: "exclamationmark.circle.fill",
                isLoading: false,
                action: onShow
            )
        }
    }
}

#Preview("CounterActionsView") {
    CounterActionsView(
        isIncreaseLoading: false,
        isDecreaseLoading: false,
        onIncrease: { print("Increase") },
        onDecrease: { print("Decrease") },
        onReset: { print("Reset") },
        onShow: { print("Show") }
    )
    .padding()
} 