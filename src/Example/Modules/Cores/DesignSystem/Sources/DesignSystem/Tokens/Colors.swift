//
//  Colors.swift
//  DesignSystem
//
//  Created by 정준혁 on 2025/08/08
//

import SwiftUI

extension Color {
    public struct DS {
        // MARK: - Background Colors
        public static let background = Color.white
        public static let surface = Color.gray.opacity(0.1)
        
        // MARK: - Button Colors
        public static let buttonBackground = Color.gray.opacity(0.15)
        public static let buttonBackgroundPressed = Color.gray.opacity(0.25)
        
        // MARK: - Text Colors
        public static let primaryText = Color.black
        public static let secondaryText = Color.gray
        public static let tertiaryText = Color.gray.opacity(0.7)
        
        // MARK: - Action Colors
        public static let destructive = Color.red.opacity(0.2)
        public static let warning = Color.orange.opacity(0.2)
        public static let accent = Color.blue.opacity(0.2)
    }
} 
