//
//  CalculatorState.swift
//  CalculatorDomain
//
//  Created by 정준영 on 2025/12/17
//

import Foundation

/// 계산기의 상태를 나타내는 Entity
public struct CalculatorState: Equatable, Sendable {
    public let display: String
    public let currentValue: Double
    public let previousValue: Double
    public let currentOperation: CalculatorOperation?
    public let shouldResetDisplay: Bool
    
    public init(
        display: String = "0",
        currentValue: Double = 0,
        previousValue: Double = 0,
        currentOperation: CalculatorOperation? = nil,
        shouldResetDisplay: Bool = false
    ) {
        self.display = display
        self.currentValue = currentValue
        self.previousValue = previousValue
        self.currentOperation = currentOperation
        self.shouldResetDisplay = shouldResetDisplay
    }
    
    /// 초기 상태
    public static let initial = CalculatorState()
}

