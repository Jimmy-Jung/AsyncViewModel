//
//  LogLevel.swift
//  AsyncViewModel
//
//  Created by jimmy on 2025/12/18.
//

import Foundation

// MARK: - LogLevel

/// 로깅 레벨을 정의하는 열거형
public enum LogLevel: Int, CaseIterable, Sendable {
    case debug = 0
    case info = 1
    case warning = 2
    case error = 3

    public var description: String {
        switch self {
        case .debug: return "DEBUG"
        case .info: return "INFO"
        case .warning: return "WARNING"
        case .error: return "ERROR"
        }
    }
}
