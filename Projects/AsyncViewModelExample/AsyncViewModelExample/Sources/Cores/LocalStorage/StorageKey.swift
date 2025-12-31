//
//  StorageKey.swift
//  LocalStorage
//
//  Created by jimmy on 2025/12/29.
//

import Foundation

/// 스토리지 키로 사용될 타입이 준수해야 하는 프로토콜
///
/// `RawRepresentable`을 채택하고 `RawValue`가 `String`이도록 제약하여
/// 열거형(enum)을 타입-세이프한 키로 사용할 수 있도록 합니다.
///
/// 예시:
/// ```swift
/// enum MyKeys: String, StorageKey {
///     case userName // rawValue는 "userName"이 됩니다.
///     case lastLoginDate = "last_login_date"
/// }
/// ```
public protocol StorageKey: RawRepresentable where RawValue == String {}

