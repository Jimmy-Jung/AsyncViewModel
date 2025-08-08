//
//  GetCoffeesRequest.swift
//  Network
//
//  Created by zundaeng on 2024/07/11.
//

import Foundation
import Moya

public struct GetCoffeesRequest: APIRequest {
    public typealias Response = [CoffeeDTO]

    public enum CoffeeType: String {
        case hot
        case iced
    }

    private let type: CoffeeType

    public var baseURL: URL {
        return URL(string: "https://api.sampleapis.com")!
    }

    public var originalPath: String {
        return "/coffee/\(type.rawValue)"
    }

    public var path: String {
        return originalPath
    }

    public var method: Moya.Method {
        return .get
    }

    public var task: Task {
        return .requestPlain
    }
    
    public init(type: CoffeeType) {
        self.type = type
    }
}
