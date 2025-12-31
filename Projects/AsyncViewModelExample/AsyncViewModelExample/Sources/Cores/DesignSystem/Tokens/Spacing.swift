//
//  Spacing.swift
//  DesignSystem
//
//  Created by jimmy on 2025/12/29.
//

import SwiftUI

extension CGFloat {
    public struct DS {
        // MARK: - Spacing Scale
        public static let xs: CGFloat = 4
        public static let sm: CGFloat = 8
        public static let md: CGFloat = 16
        public static let lg: CGFloat = 24
        public static let xl: CGFloat = 32
        public static let xxl: CGFloat = 48
        public static let xxxl: CGFloat = 64
        
        // MARK: - Component Specific
        public static let buttonPadding: CGFloat = 16
        public static let buttonRadius: CGFloat = 12
        public static let cardPadding: CGFloat = 20
        public static let sectionSpacing: CGFloat = 32
    }
}

extension EdgeInsets {
    public struct DS {
        public static let buttonPadding = EdgeInsets(
            top: .DS.sm,
            leading: .DS.md,
            bottom: .DS.sm,
            trailing: .DS.md
        )
        
        public static let cardPadding = EdgeInsets(
            top: .DS.cardPadding,
            leading: .DS.cardPadding,
            bottom: .DS.cardPadding,
            trailing: .DS.cardPadding
        )
    }
} 
