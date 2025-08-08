//
//  Parameterable.swift
//  Network
//
//  Created by 정준영 on 2025/8/3.
//

import Foundation

/// 파라미터 처리 프로토콜
public protocol Parameterable {
    func compactParameters(_ parameters: [String: Any?]) -> [String: Any]
}

public extension Parameterable {
    func compactParameters(_ parameters: [String: Any?]) -> [String: Any] {
        return parameters.compactMapValues { $0 }
    }
}
