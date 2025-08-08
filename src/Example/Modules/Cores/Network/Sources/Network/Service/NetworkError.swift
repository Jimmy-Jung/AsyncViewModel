//
//  NetworkError.swift
//  Network
//
//  Created by 정준영 on 2025/8/3.
//

import Foundation

public enum NetworkError: Error {
    case decodingFailed(Error)
    case errorResponseDecodingFailed(Error)
    case noData
    case errorResponse(ErrorResponseDto)
    case unhandledStatusCode(Int)
    case serverError(Int)
    case networkFailed(Error)
    case unknown
}

extension NetworkError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .decodingFailed:
            return "데이터를 디코딩하는 데 실패했습니다."
        case .errorResponseDecodingFailed:
            return "에러 응답을 디코딩하는 데 실패했습니다."
        case .noData:
            return "데이터가 없습니다."
        case let .errorResponse(errorResponse):
            return errorResponse.message
        case let .unhandledStatusCode(code):
            return "알 수 없는 상태 코드(\(code))가 발생했습니다."
        case let .serverError(code):
            return "서버 에러(\(code))가 발생했습니다."
        case .networkFailed:
            return "네트워크 연결에 실패했습니다."
        case .unknown:
            return "알 수 없는 오류가 발생했습니다."
        }
    }
}
