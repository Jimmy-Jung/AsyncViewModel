//
//  SendableError.swift
//  AsyncViewModel
//
//  Created by 정준영 on 2025/8/7.
//

import Foundation

/// Sendable Error wrapper for Swift 6 concurrency compliance
///
/// 이 구조체는 Swift 동시성 컨텍스트에서 안전하게 전달할 수 있도록
/// Error 프로토콜을 준수하는 Sendable 타입입니다.
public struct SendableError: Error, Sendable, Equatable {
    public let localizedDescription: String
    public let code: Int
    public let domain: String
    public let typeName: String
    /// 에러의 추가 정보를 담고 있는 딕셔너리 (NSError의 userInfo를 문자열로 변환)
    public let userInfo: [String: String]

    public init(_ error: any Error) {
        let nsError = error as NSError
        self.localizedDescription = error.localizedDescription
        self.code = nsError.code
        self.domain = nsError.domain
        self.typeName = String(reflecting: type(of: error))
        
        // userInfo를 Sendable한 형태로 변환
        self.userInfo = nsError.userInfo.reduce(into: [:]) { result, element in
            let key = String(describing: element.key)
            result[key] = String(describing: element.value)
        }
    }

    public init(
        message: String, 
        code: Int = 0, 
        domain: String = "custom", 
        typeName: String = "CustomError",
        userInfo: [String: String] = [:]
    ) {
        self.localizedDescription = message
        self.code = code
        self.domain = domain
        self.typeName = typeName
        self.userInfo = userInfo
    }

    public var isCancellationError: Bool {
        // NSURLErrorCancelled 체크
        domain == NSURLErrorDomain && code == NSURLErrorCancelled ||
        // Swift.CancellationError 체크
        domain == "Swift.CancellationError" && code == 1
    }
}
