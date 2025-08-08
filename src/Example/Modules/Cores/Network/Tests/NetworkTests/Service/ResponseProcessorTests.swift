//
//  ResponseProcessorTests.swift
//  NetworkTests
//
//  Created by 정준영 on 2025/8/3.
//

import Foundation
import Moya
@testable import Network
import Testing

// MARK: - Test Suite

struct ResponseProcessorTests {
    // MARK: - Properties

    let processor = ResponseProcessor()

    // MARK: - Test Models

    /// 테스트용 성공 응답 모델
    struct TestSuccessModel: Codable {
        let id: Int
        let message: String
        let timestamp: String

        init(id: Int, message: String, timestamp: String) {
            self.id = id
            self.message = message
            self.timestamp = timestamp
        }
    }

    /// 테스트용 에러 응답 모델
    struct TestErrorModel: ErrorResponseDto {
        let message: String
        let code: Int
        let details: String?

        init(message: String, code: Int, details: String? = nil) {
            self.message = message
            self.code = code
            self.details = details
        }
    }

    /// 테스트용 빈 응답 모델
    struct TestEmptyModel: Codable {
        init() {}
    }

    // MARK: - Helper Methods

    /// 테스트용 Mock Response 생성
    private func createMockResponse(
        statusCode: Int,
        data: Data = Data()
    ) -> Response {
        return Response(
            statusCode: statusCode,
            data: data,
            request: nil,
            response: nil
        )
    }

    /// JSON 데이터 생성 헬퍼
    private func createJSONData<T: Codable>(_ model: T) throws -> Data {
        return try JSONEncoder().encode(model)
    }

    // MARK: - Success Response Processing Tests

    @Test("2xx 성공 응답 처리 테스트", arguments: [200, 201, 202, 204, 299])
    func processSuccessResponse(statusCode: Int) async throws {
        // Given
        let testModel = TestSuccessModel(
            id: 1,
            message: "Success",
            timestamp: "2024-01-01T00:00:00Z"
        )
        let responseData = try createJSONData(testModel)
        let response = createMockResponse(statusCode: statusCode, data: responseData)
        let result: Result<Response, MoyaError> = .success(response)
        let mockRequest = MockAPIRequest()

        // When
        let decodedModel = try await processor.process(
            request: mockRequest,
            result: result,
            decodeType: TestSuccessModel.self,
            errorType: TestErrorModel.self
        )

        // Then
        #expect(decodedModel.id == testModel.id)
        #expect(decodedModel.message == testModel.message)
        #expect(decodedModel.timestamp == testModel.timestamp)
    }

    @Test("EmptyResponse 처리 테스트")
    func processEmptyResponse() async throws {
        // Given
        let emptyData = Data()
        let response = createMockResponse(statusCode: 200, data: emptyData)
        let result: Result<Response, MoyaError> = .success(response)
        let mockRequest = MockAPIRequest()

        // When
        let _ = try await processor.process(
            request: mockRequest,
            result: result,
            decodeType: EmptyResponseDto.self,
            errorType: TestErrorModel.self
        )

        // Then
        #expect(true)
    }

    @Test("204 No Content 응답 처리 테스트")
    func process204NoContentResponse() async throws {
        // Given
        let response = createMockResponse(statusCode: 204, data: Data())
        let result: Result<Response, MoyaError> = .success(response)
        let mockRequest = MockAPIRequest()
        
        // When
        let _ = try await processor.process(
            request: mockRequest,
            result: result,
            decodeType: EmptyResponseDto.self,
            errorType: TestErrorModel.self
        )
        
        // Then
        #expect(true) // 성공적으로 처리되면 통과
    }

    // MARK: - Client Error Response Processing Tests

    @Test("4xx 클라이언트 에러 응답 처리 테스트", arguments: [400, 401, 403, 404, 422, 499])
    func processClientErrorResponse(statusCode: Int) async throws {
        // Given
        let errorModel = TestErrorModel(
            message: "Client error occurred",
            code: statusCode,
            details: "Invalid request format"
        )
        let errorData = try createJSONData(errorModel)
        let response = createMockResponse(statusCode: statusCode, data: errorData)
        let result: Result<Response, MoyaError> = .success(response)
        let mockRequest = MockAPIRequest()

        // When & Then
        await #expect(throws: NetworkError.self) {
            _ = try await processor.process(
                request: mockRequest,
                result: result,
                decodeType: TestSuccessModel.self,
                errorType: TestErrorModel.self
            )
        }
    }

    @Test("4xx 클라이언트 에러 응답 디코딩 실패 테스트")
    func processClientErrorWithInvalidErrorResponse() async throws {
        // Given
        let invalidErrorData = "{\"message\": 123}".data(using: .utf8)! // message가 문자열이 아님
        let response = createMockResponse(statusCode: 400, data: invalidErrorData)
        let result: Result<Response, MoyaError> = .success(response)
        let mockRequest = MockAPIRequest()

        // When & Then
        do {
            _ = try await processor.process(
                request: mockRequest,
                result: result,
                decodeType: TestSuccessModel.self,
                errorType: TestErrorModel.self
            )
            #expect(Bool(false), "에러가 발생해야 합니다.")
        } catch let error as NetworkError {
            switch error {
            case .errorResponseDecodingFailed:
                #expect(true) // 예상된 에러
            default:
                #expect(Bool(false), "예상치 못한 에러 타입: \(error)")
            }
        }
    }

    // MARK: - Server Error Response Processing Tests

    @Test("5xx 서버 에러 응답 처리 테스트", arguments: [500, 501, 502, 503, 504, 599])
    func processServerErrorResponse(statusCode: Int) async throws {
        // Given
        let response = createMockResponse(statusCode: statusCode, data: Data())
        let result: Result<Response, MoyaError> = .success(response)
        let mockRequest = MockAPIRequest()

        // When & Then
        await #expect(throws: NetworkError.self) {
            _ = try await processor.process(
                request: mockRequest,
                result: result,
                decodeType: TestSuccessModel.self,
                errorType: TestErrorModel.self
            )
        }
    }


    @Test("5xx 서버 에러에서 에러 응답 디코딩 성공 시")
    func processServerErrorWithValidErrorResponse() async throws {
        // Given
        let errorModel = TestErrorModel(
            message: "Internal server error",
            code: 500,
            details: "Database connection failed"
        )
        let errorData = try createJSONData(errorModel)
        let response = createMockResponse(statusCode: 500, data: errorData)
        let result: Result<Response, MoyaError> = .success(response)
        let mockRequest = MockAPIRequest()

        // When & Then
        do {
            _ = try await processor.process(
                request: mockRequest,
                result: result,
                decodeType: TestSuccessModel.self,
                errorType: TestErrorModel.self
            )
            #expect(Bool(false), "Should have thrown an error")
        } catch let error as NetworkError {
            switch error {
            case let .errorResponse(errorResponse):
                #expect(errorResponse.message == "Internal server error")
            default:
                #expect(Bool(false), "Expected errorResponse case")
            }
        }
    }

    // MARK: - Unhandled Status Code Tests

    @Test("처리되지 않은 상태 코드 응답 테스트", arguments: [100, 199, 300, 350, 600, 700])
    func processUnhandledStatusCode(statusCode: Int) async throws {
        // Given
        let response = createMockResponse(statusCode: statusCode, data: Data())
        let result: Result<Response, MoyaError> = .success(response)
        let mockRequest = MockAPIRequest()

        // When & Then
        do {
            _ = try await processor.process(
                request: mockRequest,
                result: result,
                decodeType: TestSuccessModel.self,
                errorType: TestErrorModel.self
            )
            #expect(Bool(false), "Should have thrown an error")
        } catch let error as NetworkError {
            switch error {
            case let .unhandledStatusCode(code):
                #expect(code == statusCode)
            default:
                #expect(Bool(false), "Expected unhandledStatusCode case")
            }
        }
    }

    // MARK: - MoyaError Processing Tests

    @Test("다양한 MoyaError 처리 테스트", arguments: [
        MoyaError.requestMapping("http://test.com"),
        MoyaError.jsonMapping(Response(statusCode: 200, data: Data())),
        MoyaError.underlying(NSError(domain: "TestDomain", code: 456), nil)
    ])
    func processVariousMoyaErrors(moyaError: MoyaError) async throws {
        // Given
        let result: Result<Response, MoyaError> = .failure(moyaError)
        let mockRequest = MockAPIRequest()

        // When & Then
        do {
            _ = try await processor.process(
                request: mockRequest,
                result: result,
                decodeType: TestSuccessModel.self,
                errorType: TestErrorModel.self
            )
            #expect(Bool(false), "에러가 발생해야 합니다.")
        } catch let error as NetworkError {
            switch error {
            case let .networkFailed(failedError):
                #expect(failedError is MoyaError)
            default:
                #expect(Bool(false), "예상치 못한 에러 타입: \(error)")
            }
        }
    }

    // MARK: - Decoding Failure Tests

    @Test("잘못된 JSON 디코딩 실패 테스트")
    func processInvalidJSONDecoding() async throws {
        // Given
        let invalidJSONData = "{ invalid json }".data(using: .utf8)!
        let response = createMockResponse(statusCode: 200, data: invalidJSONData)
        let result: Result<Response, MoyaError> = .success(response)
        let mockRequest = MockAPIRequest()

        // When & Then
        do {
            _ = try await processor.process(
                request: mockRequest,
                result: result,
                decodeType: TestSuccessModel.self,
                errorType: TestErrorModel.self
            )
            #expect(Bool(false), "Should have thrown an error")
        } catch let error as NetworkError {
            switch error {
            case .decodingFailed:
                #expect(true) // 예상된 에러
            default:
                #expect(Bool(false), "Expected decodingFailed case, but got \(error)")
            }
        }
    }

    @Test("응답 데이터가 없는 경우 테스트")
    func processNoDataResponse() async throws {
        // Given
        let response = Response(
            statusCode: 200,
            data: Data(), // 빈 데이터가 아닌 nil 데이터를 시뮬레이션하기 위해
            request: nil,
            response: nil
        )
        let result: Result<Response, MoyaError> = .success(response)
        let mockRequest = MockAPIRequest()

        // When & Then
        // EmptyResponse가 아닌 일반 모델에 대해 빈 데이터는 디코딩 실패가 될 것
        await #expect(throws: NetworkError.self) {
            _ = try await processor.process(
                request: mockRequest,
                result: result,
                decodeType: TestSuccessModel.self,
                errorType: TestErrorModel.self
            )
        }
    }
}

// MARK: - Mock API Request

private struct MockAPIRequest: APIRequest {
    var baseURL: URL {
        return URL(string: "https://api.test.com")!
    }

    var originalPath: String {
        return "/test"
    }

    var path: String {
        return originalPath
    }

    var method: Moya.Method {
        return .get
    }

    var task: Task {
        return .requestPlain
    }

    var headers: [String: String]? {
        return nil
    }
}
