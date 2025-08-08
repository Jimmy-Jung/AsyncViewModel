//
//  CoffeeDTOTests.swift
//  NetworkTests
//
//  Created by zundaeng on 2024/07/11.
//

import Testing
import Foundation
@testable import Network

struct CoffeeDTOTests {

    @Test("배열 형태의 ingredients 디코딩 테스트")
    func decodeWithIngredientArray() throws {
        // Given
        let json = """
        {
            "title": "Americano",
            "description": "An Americano is a type of coffee drink prepared by diluting an espresso with hot water, giving it a similar strength to, but different flavor from, traditionally brewed coffee.",
            "ingredients": ["Espresso", "Hot Water"],
            "image": "https://sample.com/americano.jpg",
            "id": 1
        }
        """.data(using: .utf8)!
        
        // When
        let decoder = JSONDecoder()
        let coffee = try decoder.decode(CoffeeDTO.self, from: json)
        
        // Then
        #expect(coffee.title == "Americano")
        #expect(coffee.ingredients == ["Espresso", "Hot Water"])
    }
    
    @Test("문자열 형태의 ingredients 디코딩 테스트")
    func decodeWithIngredientString() throws {
        // Given
        let json = """
        {
            "title": "Iced Coffee",
            "description": "A coffee with ice, typically served with a dash of milk, cream or sweetener.",
            "ingredients": "Coffee,Ice,Sugar*,Cream*",
            "image": "https://sample.com/icedcoffee.jpg",
            "id": 2
        }
        """.data(using: .utf8)!
        
        // When
        let decoder = JSONDecoder()
        let coffee = try decoder.decode(CoffeeDTO.self, from: json)
        
        // Then
        #expect(coffee.title == "Iced Coffee")
        #expect(coffee.ingredients == ["Coffee", "Ice", "Sugar*", "Cream*"])
    }
    
    @Test("ingredients 필드가 없는 경우 디코딩 테스트")
    func decodeWithMissingIngredients() throws {
        // Given
        let json = """
        {
            "title": "Espresso",
            "description": "Full-flavored, concentrated form of coffee.",
            "image": "https://sample.com/espresso.jpg",
            "id": 3
        }
        """.data(using: .utf8)!

        // When
        let decoder = JSONDecoder()
        let coffee = try decoder.decode(CoffeeDTO.self, from: json)

        // Then
        #expect(coffee.title == "Espresso")
        #expect(coffee.ingredients.isEmpty)
    }
}

