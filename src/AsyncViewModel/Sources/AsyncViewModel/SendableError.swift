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
    public let domain: String
    public let typeName: String

    public init(_ error: Error) {
        let nsError = error as NSError
        self.localizedDescription = error.localizedDescription
        self.code = nsError.code
        self.domain = nsError.domain
        self.typeName = String(reflecting: type(of: error))
    }

    public init(message: String, code: Int = 0, domain: String = "custom", typeName: String = "CustomError") {
        self.localizedDescription = message
        self.code = code
        self.domain = domain
        self.typeName = typeName
    }

    public var isCancellationError: Bool {
        domain == NSURLErrorDomain && code == NSURLErrorCancelled
    }
}
