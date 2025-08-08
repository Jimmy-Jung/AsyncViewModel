//
//  AccessTokenAuthorizable.swift
//  Network
//
//  Created by 정준영 on 2025/8/3.
//

import Foundation

/// 토큰 인증 프로토콜
public protocol AccessTokenAuthorizable {
    var authorizationType: AuthorizationType? { get }
}
