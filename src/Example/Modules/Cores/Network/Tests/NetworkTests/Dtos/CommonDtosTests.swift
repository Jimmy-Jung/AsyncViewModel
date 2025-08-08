//
//  CommonDtosTests.swift
//  NetworkTests
//
//  Created by zundaeng on 2024/07/15.
//

import Testing
import Foundation
@testable import Network

struct CommonDtosTests {
    
    // MARK: - EmptyResponseDto Tests
    
    @Test("EmptyResponseDto 초기화 테스트")
    func emptyResponseDtoInitialization() {
        // Given & When
        let _ = EmptyResponseDto()
        
        // Then
        #expect(true) // Should not be nil, this check is implicit
    }
    
    @Test("EmptyResponseDto 인코딩 및 디코딩 테스트")
    func emptyResponseDtoEncodingAndDecoding() throws {
        // Given
        let emptyResponse = EmptyResponseDto()
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()
        
        // When
        let encodedData = try encoder.encode(emptyResponse)
        let _ = try decoder.decode(EmptyResponseDto.self, from: encodedData)
        
        // Then
        #expect(true) // Should not be nil
    }
    
    // MARK: - DefaultErrorResponseDto Tests
    
    @Test("DefaultErrorResponseDto 기본 초기화 테스트")
    func defaultErrorResponseDtoDefaultInitialization() {
        // Given & When
        let errorResponse = DefaultErrorResponseDto()
        
        // Then
        #expect(errorResponse.message == "Unknown error")
    }
    
    @Test("DefaultErrorResponseDto 커스텀 메시지 초기화 테스트")
    func defaultErrorResponseDtoCustomMessageInitialization() {
        // Given
        let customMessage = "A specific error occurred."
        
        // When
        let errorResponse = DefaultErrorResponseDto(message: customMessage)
        
        // Then
        #expect(errorResponse.message == customMessage)
    }
    
    @Test("DefaultErrorResponseDto 인코딩 테스트")
    func defaultErrorResponseDtoEncoding() throws {
        // Given
        let errorResponse = DefaultErrorResponseDto(message: "Test Message")
        let encoder = JSONEncoder()
        
        // When
        let data = try encoder.encode(errorResponse)
        let dictionary = try #require(JSONSerialization.jsonObject(with: data) as? [String: String])
        
        // Then
        #expect(dictionary["message"] == "Test Message")
    }

    @Test("DefaultErrorResponseDto 디코딩 테스트")
    func defaultErrorResponseDtoDecoding() throws {
        // Given
        let json = """
        {
            "message": "Error from server"
        }
        """.data(using: .utf8)!
        let decoder = JSONDecoder()
        
        // When
        let errorResponse = try decoder.decode(DefaultErrorResponseDto.self, from: json)
        
        // Then
        #expect(errorResponse.message == "Error from server")
    }
}

