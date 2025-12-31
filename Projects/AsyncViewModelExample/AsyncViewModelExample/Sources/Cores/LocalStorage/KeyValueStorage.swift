//
//  KeyValueStorage.swift
//  LocalStorage
//
//  Created by jimmy on 2025/12/29.
//

import Foundation

/// 키-값 기반 데이터 저장소를 위한 프로토콜
///
/// 데이터를 특정 키에 연결하여 저장, 로드, 삭제하는 기능을 정의합니다.
/// 파일 시스템, UserDefaults, 데이터베이스 등 다양한 방식으로 구현될 수 있습니다.
public protocol KeyValueStorage {
    /// 데이터를 지정된 키에 저장합니다.
    /// - Parameters:
    ///   - data: 저장할 `Codable` 데이터
    ///   - key: 데이터를 식별하는 `StorageKey` 준수 열거형 키
    /// - Throws: 저장 과정에서 발생하는 에러
    func save<T: Codable, K: StorageKey>(_ data: T, forKey key: K) async throws

    /// 지정된 키에서 데이터를 불러옵니다.
    /// - Parameters:
    ///   - type: 불러올 데이터의 타입
    ///   - key: 불러올 데이터의 `StorageKey` 준수 열거형 키
    /// - Returns: 디코딩된 데이터
    /// - Throws: 데이터를 찾을 수 없거나 디코딩에 실패했을 때 발생하는 에러
    func load<T: Codable, K: StorageKey>(_ type: T.Type, fromKey key: K) async throws -> T

    /// 지정된 키에 해당하는 데이터가 존재하는지 확인합니다.
    /// - Parameter key: 확인할 데이터의 `StorageKey` 준수 열거형 키
    /// - Returns: 데이터 존재 여부 (true/false)
    func exists<K: StorageKey>(forKey key: K) async -> Bool

    /// 지정된 키의 데이터를 삭제합니다.
    /// - Parameter key: 삭제할 데이터의 `StorageKey` 준수 열거형 키
    /// - Throws: 삭제 과정에서 발생하는 에러
    func delete<K: StorageKey>(forKey key: K) async throws
}

