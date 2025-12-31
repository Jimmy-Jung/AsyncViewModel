//
//  Colors.swift
//  DesignSystem
//
//  Created by jimmy on 2025/12/29.
//

import SwiftUI

extension Color {
    public struct DS {
        // MARK: - Background Colors
        public static let background = Color(uiColor: .systemBackground)
        public static let secondaryBackground = Color(uiColor: .secondarySystemBackground)
        public static let surface = Color(uiColor: .systemGray6)
        
        // MARK: - Button Colors
        public static let buttonBackground = Color(uiColor: .systemGray5)
        public static let numberButton = Color(uiColor: .systemGray)
        public static let operationButton = Color(uiColor: .systemBlue)
        public static let clearButton = Color(uiColor: .systemOrange)
        public static let equalsButton = Color(uiColor: .systemGreen)
        
        // MARK: - Text Colors
        public static let primaryText = Color(uiColor: .label)
        public static let secondaryText = Color(uiColor: .secondaryLabel)
        public static let tertiaryText = Color(uiColor: .tertiaryLabel)
        
        // MARK: - Timer Colors
        public static let timerWarning = Color(uiColor: .systemOrange)
        public static let timerBorder = Color(uiColor: .systemOrange).opacity(0.6)
        
        // MARK: - Action Colors
        public static let destructive = Color(uiColor: .systemRed)
        public static let warning = Color(uiColor: .systemOrange)
        public static let accent = Color(uiColor: .systemBlue)
    }
} 
