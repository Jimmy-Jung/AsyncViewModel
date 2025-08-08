//
//  APIRequest.swift
//  Network
//
//  Created by 정준영 on 2025/8/3.
//

import Foundation
import Moya

/// API 요청을 나타내는 프로토콜
public protocol APIRequest: TargetType, AccessTokenAuthorizable {
    var baseURL: URL { get }
    var path: String { get }
    var originalPath: String { get }
    var method: Moya.Method { get }
    var task: Task { get }
    var headers: [String: String]? { get }
}

public extension APIRequest {
    var headers: [String: String]? {
        return nil
    }

    var authorizationType: AuthorizationType? {
        return AuthorizationType.none
    }
}
