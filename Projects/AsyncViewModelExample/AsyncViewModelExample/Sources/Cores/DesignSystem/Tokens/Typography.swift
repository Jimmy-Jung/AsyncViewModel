//
//  Typography.swift
//  DesignSystem
//
//  Created by jimmy on 2025/12/29.
//

import SwiftUI

extension Font {
    public struct DS {
        // MARK: - Display
        public static let displayLarge = Font.system(size: 64, weight: .bold, design: .default)
        public static let displayMedium = Font.system(size: 48, weight: .bold, design: .default)
        public static let displaySmall = Font.system(size: 36, weight: .bold, design: .default)
        
        // MARK: - Headline
        public static let headlineLarge = Font.system(size: 24, weight: .semibold, design: .default)
        public static let headlineMedium = Font.system(size: 20, weight: .semibold, design: .default)
        public static let headlineSmall = Font.system(size: 18, weight: .semibold, design: .default)
        
        // MARK: - Body
        public static let bodyLarge = Font.system(size: 16, weight: .medium, design: .default)
        public static let bodyMedium = Font.system(size: 14, weight: .medium, design: .default)
        public static let bodySmall = Font.system(size: 12, weight: .medium, design: .default)
        
        // MARK: - Label
        public static let labelLarge = Font.system(size: 14, weight: .medium, design: .default)
        public static let labelMedium = Font.system(size: 12, weight: .medium, design: .default)
        public static let labelSmall = Font.system(size: 10, weight: .medium, design: .default)
    }
}

public extension Text {
    // MARK: - Display Styles
    func displayLarge() -> some View {
        self.font(.DS.displayLarge)
            .foregroundColor(.DS.primaryText)
    }
    
    func displayMedium() -> some View {
        self.font(.DS.displayMedium)
            .foregroundColor(.DS.primaryText)
    }
    
    // MARK: - Body Styles
    func bodyMedium() -> some View {
        self.font(.DS.bodyMedium)
            .foregroundColor(.DS.primaryText)
    }
    
    func bodySecondary() -> some View {
        self.font(.DS.bodyMedium)
            .foregroundColor(.DS.secondaryText)
    }
    
    func caption() -> some View {
        self.font(.DS.labelMedium)
            .foregroundColor(.DS.tertiaryText)
    }
} 
