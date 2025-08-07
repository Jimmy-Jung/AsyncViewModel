//
//  SendableError.swift
//  AsyncViewModel
//
//  Created by 정준영 on 2025/8/7.
//

import Foundation

/// Sendable Error wrapper for Swift 6 concurrency compliance
public struct SendableError: Error, Sendable, Equatable {
    public let localizedDescription: String
    public let code: Int

    public init(_ error: Error) {
        self.localizedDescription = error.localizedDescription
        self.code = (error as NSError).code
    }

    public init(message: String, code: Int = 0) {
        self.localizedDescription = message
        self.code = code
    }
}
