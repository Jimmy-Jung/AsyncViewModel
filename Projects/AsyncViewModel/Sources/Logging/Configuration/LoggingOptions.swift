//
//  LoggingOptions.swift
//  AsyncViewModel
//
//  Created by jimmy on 2025/12/19.
//

import Foundation

// MARK: - PerformanceThreshold

public struct PerformanceThreshold: Sendable, Codable {
    public enum OperationType: String, Sendable, Codable {
        case actionProcessing = "Action processing"
        case effectOperation = "Effect operation"
        case stateUpdate = "State update"
        case custom = "Custom"

        public var recommendedThreshold: TimeInterval {
            switch self {
            case .actionProcessing: return 0.050
            case .effectOperation: return 0.100
            case .stateUpdate: return 0.016
            case .custom: return 0.100
            }
        }
    }

    public let type: OperationType
    public let customThreshold: TimeInterval?

    public var threshold: TimeInterval {
        customThreshold ?? type.recommendedThreshold
    }

    public init(type: OperationType, customThreshold: TimeInterval? = nil) {
        self.type = type
        self.customThreshold = customThreshold
    }

    public static func infer(from operation: String) -> OperationType {
        let lowercased = operation.lowercased()
        if lowercased.contains("action") && lowercased.contains("processing") {
            return .actionProcessing
        } else if lowercased.contains("effect") {
            return .effectOperation
        } else if lowercased.contains("state") {
            return .stateUpdate
        } else {
            return .custom
        }
    }
}

// MARK: - LogFormat

public enum LogFormat: Sendable, Codable {
    case compact
    case standard
    case detailed
}

// MARK: - LoggingOptions

public struct LoggingOptions: Sendable, Codable {
    public var actionFormat: LogFormat
    public var stateFormat: LogFormat
    public var effectFormat: LogFormat
    public var performanceThreshold: PerformanceThreshold?
    public var showZeroPerformance: Bool

    /// 상태 출력 시 최대 깊이 (기본값: 5)
    public var maxDepth: Int

    /// 값 출력 시 최대 문자열 길이 (기본값: 500)
    public var maxValueLength: Int

    public init(
        actionFormat: LogFormat = .standard,
        stateFormat: LogFormat = .standard,
        effectFormat: LogFormat = .standard,
        performanceThreshold: PerformanceThreshold? = nil,
        showZeroPerformance: Bool = false,
        maxDepth: Int = 5,
        maxValueLength: Int = 500
    ) {
        self.actionFormat = actionFormat
        self.stateFormat = stateFormat
        self.effectFormat = effectFormat
        self.performanceThreshold = performanceThreshold
        self.showZeroPerformance = showZeroPerformance
        self.maxDepth = maxDepth
        self.maxValueLength = maxValueLength
    }
}
