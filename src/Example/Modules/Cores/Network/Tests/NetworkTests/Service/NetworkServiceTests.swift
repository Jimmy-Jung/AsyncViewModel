//
//  NetworkServiceTests.swift
//  NetworkTests
//
//  Created by 정준영 on 2025/8/3.
//

import Foundation
import Moya
@testable import Network
import Testing

// MARK: - Test Suite

struct NetworkServiceTests {
    // MARK: - Test Models

    /// 테스트용 응답 모델
    struct TestResponse: Codable, Equatable {
        let id: Int
        let name: String
        let status: String
    }

    /// 테스트용 에러 응답 모델
    struct TestErrorResponse: ErrorResponseDto, Equatable {
        let message: String
        let errorCode: Int

        init(message: String, errorCode: Int = 400) {
            self.message = message
            self.errorCode = errorCode
        }
    }

    /// 테스트용 API 요청
    struct TestRequest: APIRequest {
        
        
        var baseURL: URL { return URL(string: "https://test.com")! }
        var path: String { return originalPath }
        var originalPath: String { return "/test" }
        var method: Moya.Method { return .get }
        var task: Task { return .requestPlain }
    }

    // MARK: - Request Processing Tests

    @Test("성공적인 네트워크 요청 처리")
    func processSuccessfulRequest() async throws {
        // Given
        let successResponse = TestResponse(id: 1, name: "Success", status: "OK")
        let responseData = try JSONEncoder().encode(successResponse)
        let provider = createStubProvider(statusCode: 200, data: responseData)
        let networkService = DefaultNetworkService(provider: provider)
        let request = TestRequest()

        // When
        let decodedResponse = try await networkService.request(
            request,
            decodeType: TestResponse.self,
            errorType: TestErrorResponse.self
        )

        // Then
        #expect(decodedResponse == successResponse)
    }

    @Test("재시도 없는 클라이언트 에러 요청 실패 테스트")
    func processRequestWithNonRetryableFailure() async throws {
        // Given
        let errorResponse = TestErrorResponse(message: "Not Found", errorCode: 404)
        let errorData = try JSONEncoder().encode(errorResponse)
        let provider = createStubProvider(statusCode: 404, data: errorData)
        let networkService = DefaultNetworkService(provider: provider)
        let request = TestRequest()

        // When & Then
        do {
            _ = try await networkService.request(
                request,
                decodeType: TestResponse.self,
                errorType: TestErrorResponse.self
            )
            #expect(Bool(false), "에러가 발생해야 합니다.")
        } catch let error as NetworkError {
            switch error {
            case let .errorResponse(response):
                #expect(response.message == "Not Found")
                if let testResponse = response as? TestErrorResponse {
                    #expect(testResponse.errorCode == 404)
                }
            default:
                #expect(Bool(false), "예상치 못한 에러 타입: \(error)")
            }
        }
    }

    // MARK: - Helper Methods
    
    private func createStubProvider(statusCode: Int, data: Data) -> MoyaProvider<MultiTarget> {
        let endpointClosure = { (target: MultiTarget) -> Endpoint in
            return Endpoint(
                url: URL(target: target).absoluteString,
                sampleResponseClosure: { .networkResponse(statusCode, data) },
                method: target.method,
                task: target.task,
                httpHeaderFields: target.headers
            )
        }
        return MoyaProvider<MultiTarget>(endpointClosure: endpointClosure, stubClosure: MoyaProvider.immediatelyStub)
    }
}
