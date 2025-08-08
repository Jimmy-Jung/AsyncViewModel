//
//  NetworkErrorTests.swift
//  NetworkTests
//
//  Created by 정준영 on 2025/8/3.
//

import Foundation
@testable import Network
import Testing

// MARK: - Test Suite

struct NetworkErrorTests {
    // MARK: - Test Models

    /// 테스트용 에러 응답 모델
    struct TestErrorResponse: ErrorResponseDto {
        let message: String
        let errorCode: Int

        init(message: String, errorCode: Int = 400) {
            self.message = message
            self.errorCode = errorCode
        }
    }

    // MARK: - NetworkError Case Tests

    @Test("NetworkError.decodingFailed 케이스 생성 및 확인")
    func networkErrorDecodingFailed() {
        // Given
        let underlyingError = NSError(
            domain: "DecodingError",
            code: 100,
            userInfo: [NSLocalizedDescriptionKey: "JSON parsing failed"]
        )

        // When
        let networkError = NetworkError.decodingFailed(underlyingError)

        // Then
        switch networkError {
        case let .decodingFailed(error):
            #expect(error.localizedDescription.contains("JSON parsing failed"))
            #expect((error as NSError).code == 100)
        default:
            #expect(Bool(false), "Expected decodingFailed case")
        }
    }

    @Test("NetworkError.noData 케이스 생성 및 확인")
    func networkErrorNoData() {
        // Given & When
        let networkError = NetworkError.noData

        // Then
        switch networkError {
        case .noData:
            #expect(true) // 예상된 케이스
        default:
            #expect(Bool(false), "Expected noData case")
        }
    }

    @Test("NetworkError.errorResponse 케이스 생성 및 확인")
    func networkErrorErrorResponse() {
        // Given
        let testErrorResponse = TestErrorResponse(
            message: "Invalid request parameters",
            errorCode: 400
        )

        // When
        let networkError = NetworkError.errorResponse(testErrorResponse)

        // Then
        switch networkError {
        case let .errorResponse(errorResponse):
            #expect(errorResponse.message == "Invalid request parameters")
            if let testResponse = errorResponse as? TestErrorResponse {
                #expect(testResponse.errorCode == 400)
            }
        default:
            #expect(Bool(false), "Expected errorResponse case")
        }
    }

    @Test("NetworkError.unhandledStatusCode 케이스 생성 및 확인", arguments: [
        100, 199, 300, 350, 600, 700, 999
    ])
    func networkErrorUnhandledStatusCode(statusCode: Int) {
        // Given & When
        let networkError = NetworkError.unhandledStatusCode(statusCode)

        // Then
        switch networkError {
        case let .unhandledStatusCode(code):
            #expect(code == statusCode)
        default:
            #expect(Bool(false), "Expected unhandledStatusCode case")
        }
    }

    @Test("NetworkError.serverError 케이스 생성 및 확인", arguments: [
        500, 501, 502, 503, 504, 505, 599
    ])
    func networkErrorServerError(statusCode: Int) {
        // Given & When
        let networkError = NetworkError.serverError(statusCode)

        // Then
        switch networkError {
        case let .serverError(code):
            #expect(code == statusCode)
            #expect(code >= 500) // 서버 에러 범위 확인
        default:
            #expect(Bool(false), "Expected serverError case")
        }
    }

    @Test("NetworkError.networkFailed 케이스 생성 및 확인")
    func networkErrorNetworkFailed() {
        // Given
        let underlyingError = URLError(.networkConnectionLost)

        // When
        let networkError = NetworkError.networkFailed(underlyingError)

        // Then
        switch networkError {
        case let .networkFailed(error):
            #expect(error is URLError)
            if let urlError = error as? URLError {
                #expect(urlError.code == .networkConnectionLost)
            }
        default:
            #expect(Bool(false), "Expected networkFailed case")
        }
    }

    @Test("NetworkError.unknown 케이스 생성 및 확인")
    func networkErrorUnknown() {
        // Given & When
        let networkError = NetworkError.unknown

        // Then
        switch networkError {
        case .unknown:
            #expect(true) // 예상된 케이스
        default:
            #expect(Bool(false), "Expected unknown case")
        }
    }

    // MARK: - NetworkError Equality Tests

    @Test("동일한 NetworkError 케이스 비교 테스트")
    func networkErrorEquality() {
        // Given
        let error1 = NetworkError.noData
        let error2 = NetworkError.noData
        let error3 = NetworkError.unknown

        // When & Then
        // NetworkError가 Equatable을 구현하지 않았으므로 케이스별로 확인
        switch (error1, error2) {
        case (.noData, .noData):
            #expect(true) // 같은 케이스
        default:
            #expect(Bool(false), "Should be same case")
        }

        switch (error1, error3) {
        case (.noData, .unknown):
            #expect(true) // 다른 케이스임을 확인
        default:
            #expect(Bool(false), "Should be different cases")
        }
    }

    // MARK: - NetworkError with Real-world Scenarios Tests

    @Test("JSON 디코딩 실패 시나리오")
    func jsonDecodingFailureScenario() throws {
        // Given
        let invalidJSON = "{ invalid json format }"
        let data = try #require(invalidJSON.data(using: .utf8))

        // When
        do {
            _ = try JSONDecoder().decode(TestErrorResponse.self, from: data)
            #expect(Bool(false), "Should have failed to decode")
        } catch {
            let networkError = NetworkError.decodingFailed(error)

            // Then
            switch networkError {
            case let .decodingFailed(decodingError):
                #expect(decodingError is DecodingError)
            default:
                #expect(Bool(false), "Expected decodingFailed case")
            }
        }
    }

    @Test("다양한 ErrorResponse 타입과 함께 사용")
    func networkErrorWithDifferentErrorResponseTypes() {
        // Given
        let defaultError = DefaultErrorResponseDto(message: "Default error")
        let customError = TestErrorResponse(message: "Custom error", errorCode: 500)

        // When
        let networkError1 = NetworkError.errorResponse(defaultError)
        let networkError2 = NetworkError.errorResponse(customError)

        // Then
        switch networkError1 {
        case let .errorResponse(errorResponse):
            #expect(errorResponse.message == "Default error")
            #expect(errorResponse is DefaultErrorResponseDto)
        default:
            #expect(Bool(false), "Expected errorResponse case")
        }

        switch networkError2 {
        case let .errorResponse(errorResponse):
            #expect(errorResponse.message == "Custom error")
            #expect(errorResponse is TestErrorResponse)
        default:
            #expect(Bool(false), "Expected errorResponse case")
        }
    }

    // MARK: - NetworkError Pattern Matching Tests

    @Test("NetworkError 패턴 매칭 포괄성 테스트")
    func networkErrorPatternMatchingComprehensiveness() {
        // Given
        let allNetworkErrors: [NetworkError] = [
            .decodingFailed(NSError(domain: "test", code: 1)),
            .noData,
            .errorResponse(TestErrorResponse(message: "Error")),
            .unhandledStatusCode(999),
            .serverError(500),
            .networkFailed(URLError(.timedOut)),
            .unknown,
        ]

        // When & Then
        for error in allNetworkErrors {
            var matchedCase = ""

            switch error {
            case .decodingFailed:
                matchedCase = "decodingFailed"
            case .noData:
                matchedCase = "noData"
            case .errorResponse:
                matchedCase = "errorResponse"
            case .unhandledStatusCode:
                matchedCase = "unhandledStatusCode"
            case .serverError:
                matchedCase = "serverError"
            case .networkFailed:
                matchedCase = "networkFailed"
            case .unknown:
                matchedCase = "unknown"
            case .errorResponseDecodingFailed(_):
                matchedCase = "errorResponseDecodingFailed"
            }

            #expect(matchedCase.isEmpty == false)
        }
    }

    // MARK: - Error Conversion Tests

    @Test("URLError를 NetworkError로 변환")
    func urlErrorToNetworkErrorConversion() {
        // Given
        let urlErrors: [URLError] = [
            URLError(.networkConnectionLost),
            URLError(.timedOut),
            URLError(.cannotFindHost),
            URLError(.notConnectedToInternet),
        ]

        // When & Then
        for urlError in urlErrors {
            let networkError = NetworkError.networkFailed(urlError)

            switch networkError {
            case let .networkFailed(error):
                #expect(error is URLError)
            default:
                #expect(Bool(false), "Expected networkFailed case")
            }
        }
    }
}
