//
//  CounterDisplayView.swift
//  DesignSystem
//
//  Created by 정준혁 on 2025/08/08
//

import SwiftUI

public struct CounterDisplayView: View {
    public let value: Int
    public let description: String
    
    public var body: some View {
        VStack(spacing: .DS.sm) {
            Text("\(value)")
                .displayLarge()
                .multilineTextAlignment(.center)
            
            Text(description)
                .caption()
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, .DS.xl)
    }
}

#Preview("CounterDisplayView") {
    CounterDisplayView(
        value: 0,
        description: "허용 범위: -10 ~ 10"
    )
    .padding()
} 