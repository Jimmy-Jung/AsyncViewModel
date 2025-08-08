//
//  APIRequestTests.swift
//  NetworkTests
//
//  Created by zundaeng on 2024/07/11.
//

import Testing
import Moya
import Foundation
@testable import Network

/// 테스트용으로 사용되는 샘플 요청입니다.
private struct SampleRequest: APIRequest {
    var baseURL: URL
    var originalPath: String
    var method: Moya.Method
    var task: Task

    var path: String {
        return originalPath
    }
}

struct APIRequestTests {
    
    @Test("SampleRequest 초기화 및 프로퍼티 검증")
    func sampleRequestInitialization() {
        // Given
        let baseURL = URL(string: "https://sample.com")!
        let path = "/test"
        let method: Moya.Method = .get
        let task: Task = .requestPlain
        
        // When
        let request = SampleRequest(
            baseURL: baseURL,
            originalPath: path,
            method: method,
            task: task
        )
        
        // Then
        #expect(request.baseURL == baseURL)
        #expect(request.path == path)
        #expect(request.method == method)
        
        switch request.task {
        case .requestPlain:
            break // 성공
        default:
            Issue.record("Task should be .requestPlain")
        }
    }

    @Test("SampleRequest 초기화 및 프로퍼티 검증 (with Parameters)")
    func sampleRequestInitializationWithParameters() {
        // Given
        let baseURL = URL(string: "https://sample.com")!
        let path = "/search"
        let method: Moya.Method = .post
        let parameters: [String: Any] = ["query": "swift", "page": 1]
        let task: Task = .requestParameters(parameters: parameters, encoding: JSONEncoding.default)
        
        // When
        let request = SampleRequest(
            baseURL: baseURL,
            originalPath: path,
            method: method,
            task: task
        )
        
        // Then
        #expect(request.baseURL == baseURL)
        #expect(request.path == path)
        #expect(request.method == method)
        
        switch request.task {
        case .requestParameters(let receivedParams, let encoding):
            #expect(receivedParams["query"] as? String == "swift")
            #expect(receivedParams["page"] as? Int == 1)
            #expect(encoding is JSONEncoding)
        default:
            Issue.record("Task should be .requestParameters")
        }
    }
}
