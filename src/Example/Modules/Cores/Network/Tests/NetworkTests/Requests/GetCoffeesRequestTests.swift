//
//  GetCoffeesRequestTests.swift
//  NetworkTests
//
//  Created by zundaeng on 2024/07/11.
//

import Testing
import Moya
import Foundation
@testable import Network


struct GetCoffeesRequestTests {

    @Test("GetCoffeesRequest 프로퍼티 검증", arguments: [
        GetCoffeesRequest.CoffeeType.hot,
        GetCoffeesRequest.CoffeeType.iced
    ])
    func getCoffeesRequestProperties(coffeeType: GetCoffeesRequest.CoffeeType) {
        // Given
        let request = GetCoffeesRequest(type: coffeeType)

        // Then
        #expect(request.baseURL == URL(string: "https://api.sampleapis.com")!)
        #expect(request.path == "/coffee/\(coffeeType.rawValue)")
        #expect(request.method == .get)
        
        switch request.task {
        case .requestPlain:
            break // 성공
        default:
            Issue.record("Task should be .requestPlain")
        }
    }
}

