//
//  ActionButton.swift
//  DesignSystem
//
//  Created by 정준혁 on 2025/08/08
//

import SwiftUI

public struct ActionButton: View {
    public let title: String
    public let iconName: String
    public let isLoading: Bool
    public let action: () -> Void
    
    public var body: some View {
        Button(action: action) {
            HStack(spacing: .DS.sm) {
                // Icon
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .DS.primaryText))
                        .scaleEffect(0.8)
                        .frame(width: 16, height: 16)
                } else {
                    Image(systemName: iconName)
                        .font(.DS.bodyMedium)
                        .foregroundColor(.DS.primaryText)
                        .frame(width: 16, height: 16)
                }
                
                // Title
                Text(title)
                    .bodyMedium()
                
                Spacer()
            }
            .padding(.horizontal, .DS.md)
            .padding(.vertical, .DS.buttonPadding)
            .background(
                RoundedRectangle(cornerRadius: .DS.buttonRadius)
                    .fill(Color.DS.buttonBackground)
            )
        }
        .disabled(isLoading)
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview("ActionButton") {
    VStack(spacing: .DS.md) {
        ActionButton(
            title: "Increase",
            iconName: "plus",
            isLoading: false
        ) {
            print("Increase tapped")
        }
        
        ActionButton(
            title: "Loading...",
            iconName: "minus",
            isLoading: true
        ) {
            print("Loading tapped")
        }
    }
    .padding()
} 