//
//  StorageError.swift
//  LocalStorage
//
//  Created by jimmy on 2025/12/29.
//

import Foundation

/// 데이터 저장소 관련 에러 유형
public enum StorageError: Error, LocalizedError {
    case keyNotFound
    case bundleResourceNotFound
    case decodingFailed(Error)

    public var errorDescription: String? {
        switch self {
        case .keyNotFound:
            return "지정된 키에 해당하는 데이터를 찾을 수 없습니다."
        case .bundleResourceNotFound:
            return "번들에서 해당 리소스를 찾을 수 없습니다."
        case .decodingFailed(let error):
            return "데이터 디코딩에 실패했습니다. 원인: \(error.localizedDescription)"
        }
    }
}

