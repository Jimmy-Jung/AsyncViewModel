//
//  ResponseProcessor.swift
//  Network
//
//  Created by 정준영 on 2025/8/3.
//

import Foundation
import Moya

/// `ResponseProcessor`
///
/// - 역할:
///   - 네트워크 응답을 처리하여 성공 데이터 또는 에러 데이터를 디코딩.
///   - HTTP 상태 코드에 따라 적절한 처리를 분기.
///
/// - 제네릭:
///   - `DTO`: 성공 응답 데이터를 디코딩할 `Codable` 타입.
///   - `ErrorDTO`: 에러 응답 데이터를 디코딩할 `ErrorResponse` 타입.
public struct ResponseProcessor {
    /// 초기화 메서드
    public init() {}

    /// 네트워크 응답 데이터를 처리하여 디코딩된 객체를 반환.
    /// - Parameters:
    ///   - request: 네트워크 요청의 정보.
    ///   - result: 네트워크 요청 결과. 성공 시 `Response`, 실패 시 `MoyaError`.
    ///   - decodeType: 성공 데이터를 디코딩할 모델 타입.
    ///   - errorType: 에러 데이터를 디코딩할 모델 타입.
    /// - Returns: 성공 시 디코딩된 데이터 모델을 반환. 실패 시 에러를 던짐.
    func process<DTO: Codable, ErrorDTO: ErrorResponseDto>(
        request: APIRequest,
        result: Result<Response, MoyaError>,
        decodeType: DTO.Type,
        errorType: ErrorDTO.Type
    ) async throws -> DTO {
        switch result {
        case let .success(response):
            // 성공 응답 처리
            return try processResponse(
                response: response,
                decodeType: decodeType,
                errorType: errorType
            )
        case let .failure(error):
            // MoyaError를 NetworkError로 변환
            throw NetworkError.networkFailed(error)
        }
    }

    /// HTTP 응답 데이터를 처리하고 디코딩.
    /// - Parameters:
    ///   - response: 네트워크 응답 객체.
    ///   - decodeType: 성공 데이터를 디코딩할 모델 타입.
    ///   - errorType: 에러 데이터를 디코딩할 모델 타입.
    /// - Returns: 성공적으로 디코딩된 데이터 또는 처리 중 발생한 에러.
    private func processResponse<DTO: Codable, ErrorDTO: ErrorResponseDto>(
        response: Response,
        decodeType: DTO.Type,
        errorType: ErrorDTO.Type
    ) throws -> DTO {
        switch response.statusCode {
        case 200 ... 299:
            // HTTP 상태 코드가 성공 범위(200~299)인 경우 처리
            return try decodeData(response.data, decodeTo: decodeType)

        case 400 ... 499:
            // HTTP 상태 코드가 클라이언트 에러 범위(400~499)인 경우 처리
            throw try handleError(response: response, decodeTo: errorType)

        case 500 ... 599:
            // HTTP 상태 코드가 서버 에러 범위(500~599)인 경우 처리
            // 서버 에러도 에러 메시지를 포함할 수 있으므로 handleError 시도
            if let error = try? handleError(response: response, decodeTo: errorType) {
                throw error
            }
            throw NetworkError.serverError(response.statusCode)

        default:
            // 처리되지 않은 상태 코드의 경우 처리
            throw NetworkError.unhandledStatusCode(response.statusCode)
        }
    }

    /// 성공 응답 데이터를 디코딩.
    /// - Parameters:
    ///   - data: 네트워크 응답 데이터.
    ///   - type: 디코딩할 데이터 모델 타입.
    /// - Returns: 디코딩된 성공 데이터.
    private func decodeData<DTO: Codable>(
        _ data: Data?,
        decodeTo type: DTO.Type
    ) throws -> DTO {
        guard let data else {
            throw NetworkError.noData
        }

        // EmptyResponse 타입이고 데이터가 비어있거나 길이가 매우 짧은 경우 빈 객체 반환
        if type is EmptyResponseDto.Type && (data.isEmpty || data.count < 5) {
            if let emptyResponse = EmptyResponseDto() as? DTO {
                return emptyResponse
            } else {
                throw NetworkError.decodingFailed(
                    NSError(
                        domain: "ResponseProcessor",
                        code: -1,
                        userInfo: [NSLocalizedDescriptionKey: "EmptyResponse 타입 캐스팅 실패"]
                    )
                )
            }
        }

        do {
            let decoded = try JSONDecoder().decode(DTO.self, from: data)
            return decoded
        } catch {
            print("DECODE ERROR: \(error)")
            throw NetworkError.decodingFailed(error)
        }
    }

    /// 에러 응답 데이터를 디코딩.
    /// - Parameters:
    ///   - response: 네트워크 응답 객체.
    ///   - type: 디코딩할 에러 모델 타입.
    /// - Returns: 에러 객체.
    private func handleError<ErrorDTO: ErrorResponseDto>(
        response: Response,
        decodeTo type: ErrorDTO.Type
    ) throws -> Error {
        do {
            let errorResponse = try JSONDecoder().decode(ErrorDTO.self, from: response.data)
            return NetworkError.errorResponse(errorResponse)
        } catch {
            print("DECODE ERROR: \(error)")
            throw NetworkError.errorResponseDecodingFailed(error)
        }
    }
}
