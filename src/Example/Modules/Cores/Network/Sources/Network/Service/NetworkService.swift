//
//  NetworkService.swift
//  Network
//
//  Created by 정준영 on 2025/8/3.
//

import Moya
import Alamofire
import UIKit

// MARK: - NetworkService

/// 네트워크 요청을 처리하는 프로토콜.
public protocol NetworkService {
    /// 네트워크 요청을 실행하여 데이터를 디코딩 후 원하는 타입으로 반환.
    func request<DTO: Codable, ErrorDTO: ErrorResponseDto>(
        _ request: APIRequest,
        decodeType: DTO.Type,
        errorType: ErrorDTO.Type
    ) async throws -> DTO
}

/// `NetworkService`의 기본 구현체.
@available(iOS 13.0, macOS 10.15, *)
public struct DefaultNetworkService: NetworkService {
    private var provider: MoyaProvider<MultiTarget>
    private let responseProcessor: ResponseProcessor

    /// `DefaultNetworkService`의 초기화 메서드.
    public init(
        provider: MoyaProvider<MultiTarget>? = nil,
        plugins: [PluginType]? = nil,
        responseProcessor: ResponseProcessor = ResponseProcessor()
    ) {
        self.responseProcessor = responseProcessor
        if let provider {
            self.provider = provider
        } else {
            let session = Moya.Session(interceptor: RetryPolicy())
            var finalPlugins: [PluginType] = plugins ?? []
            #if DEBUG
            if !finalPlugins.contains(where: { $0 is NetworkLoggerPlugin }) {
                finalPlugins.append(NetworkLoggerPlugin())
            }
            #endif
            
            self.provider = MoyaProvider<MultiTarget>(session: session, plugins: finalPlugins)
        }
    }
    
    /// 테스트 목적으로 Provider를 교체하기 위한 메서드
    internal mutating func changeProvider(_ provider: MoyaProvider<MultiTarget>) {
        self.provider = provider
    }

    public func request<DTO: Codable, ErrorDTO: ErrorResponseDto>(
        _ request: APIRequest,
        decodeType: DTO.Type,
        errorType: ErrorDTO.Type
    ) async throws -> DTO {
        let result = await withCheckedContinuation { continuation in
            provider.request(MultiTarget(request)) { result in
                continuation.resume(returning: result)
            }
        }
        
        return try await responseProcessor.process(
            request: request,
            result: result,
            decodeType: decodeType,
            errorType: errorType
        )
    }
}

// MARK: - RetryPolicy
private final class RetryPolicy: RequestInterceptor {
    private let maxRetries = 2 // 첫 요청 포함 총 3번 시도
    
    func adapt(_ urlRequest: URLRequest, for session: Session, completion: @escaping (Result<URLRequest, Error>) -> Void) {
        completion(.success(urlRequest))
    }

    func retry(_ request: Alamofire.Request, for session: Alamofire.Session, dueTo error: Error, completion: @escaping (RetryResult) -> Void) {
        if request.retryCount < maxRetries, isRetryableError(error) {
            let delay = Double(request.retryCount + 1) // 1초, 2초 후 재시도
            completion(.retryWithDelay(delay))
        } else {
            completion(.doNotRetry)
        }
    }
    
    private func isRetryableError(_ error: Error) -> Bool {
        // Moya 에러 중 statusCode가 500번대인 경우 재시도
        if let moyaError = error as? MoyaError,
           case .statusCode(let response) = moyaError,
           (500...599).contains(response.statusCode) {
            return true
        }

        // Alamofire의 네트워크 관련 에러인 경우 재시도
        if let afError = error.asAFError, afError.isSessionTaskError {
            if let urlError = afError.underlyingError as? URLError {
                switch urlError.code {
                case .networkConnectionLost,
                     .timedOut,
                     .cannotFindHost,
                     .cannotConnectToHost,
                     .dnsLookupFailed,
                     .notConnectedToInternet:
                    return true
                default:
                    return false
                }
            }
            return true
        }
        return false
    }
}
