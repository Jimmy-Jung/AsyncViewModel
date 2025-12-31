//
//  BundleResourceLoadable.swift
//  LocalStorage
//
//  Created by jimmy on 2025/12/29.
//

import Foundation

/// 앱 번들에서 리소스를 로드하는 기능을 위한 프로토콜
public protocol BundleResourceLoadable {
    /// 번들에서 파일을 불러와 디코딩합니다. 구현체에 따라 특정 포맷(예: JSON, Plist)을 처리합니다.
    /// - Parameters:
    ///   - type: 불러올 데이터 타입
    ///   - fileName: 파일명 (확장자 제외)
    ///   - bundle: 리소스가 포함된 번들
    /// - Returns: 디코딩된 데이터
    /// - Throws: 파일을 찾을 수 없거나 디코딩에 실패했을 때 발생하는 에러
    func loadFromBundle<T: Codable>(
        _ type: T.Type,
        fileName: String,
        in bundle: Bundle
    ) async throws -> T
}

