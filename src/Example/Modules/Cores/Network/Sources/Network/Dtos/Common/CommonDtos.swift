//
//  CommonDtos.swift
//  Network
//
//  Created by 정준영 on 2025/8/3.
//

import Foundation

/// 빈 응답을 나타내는 구조체
public struct EmptyResponseDto: Codable {
    public init() {}
}

/// 에러 응답을 나타내는 프로토콜
public protocol ErrorResponseDto: Codable, Error {
    var message: String { get }
}

/// 기본 에러 응답 구조체
public struct DefaultErrorResponseDto: ErrorResponseDto {
    public let message: String

    public init(message: String = "Unknown error") {
        self.message = message
    }
}
