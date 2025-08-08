//
//  CoffeeDTO.swift
//  Network
//
//  Created by zundaeng on 2024/07/11.
//

import Foundation

public struct CoffeeDTO: Codable, Identifiable {
    public let title: String
    public let description: String
    public let ingredients: [String]
    public let image: String
    public let id: Int
    
    enum CodingKeys: String, CodingKey {
        case title, description, ingredients, image, id
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.title = try container.decode(String.self, forKey: .title)
        self.description = try container.decode(String.self, forKey: .description)
        self.image = try container.decode(String.self, forKey: .image)
        self.id = try container.decode(Int.self, forKey: .id)
        
        if let ingredientsArray = try? container.decode([String].self, forKey: .ingredients) {
            self.ingredients = ingredientsArray
        } else if let ingredientsString = try? container.decode(String.self, forKey: .ingredients) {
            self.ingredients = ingredientsString.components(separatedBy: ",").map { $0.trimmingCharacters(in: .whitespaces) }
        } else {
            self.ingredients = []
        }
    }
}

