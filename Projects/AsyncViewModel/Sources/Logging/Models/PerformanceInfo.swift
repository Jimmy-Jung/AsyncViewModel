//
//  PerformanceInfo.swift
//  AsyncViewModel
//
//  Created by jimmy on 2025/01/21.
//

import Foundation

// MARK: - PerformanceInfo

/// 성능 측정 정보를 담는 구조체
///
/// 로거가 성능 정보를 구조화된 형태로 접근하여 다양한 포맷으로 출력할 수 있도록 합니다.
public struct PerformanceInfo: Sendable, Equatable {
    /// 작업 이름
    public let operation: String

    /// 작업 타입
    public let operationType: PerformanceThreshold.OperationType

    /// 실행 시간
    public let duration: TimeInterval

    /// 임계값
    public let threshold: TimeInterval

    /// 임계값 초과 여부
    public let exceededThreshold: Bool

    public init(
        operation: String,
        operationType: PerformanceThreshold.OperationType,
        duration: TimeInterval,
        threshold: TimeInterval,
        exceededThreshold: Bool
    ) {
        self.operation = operation
        self.operationType = operationType
        self.duration = duration
        self.threshold = threshold
        self.exceededThreshold = exceededThreshold
    }
}
