//
//  ActionInfo.swift
//  AsyncViewModel
//
//  Created by jimmy on 2025/01/21.
//

import Foundation

// MARK: - ActionInfo

/// Action 정보를 담는 구조체
///
/// 로거가 Action을 구조화된 형태로 접근하여 다양한 포맷으로 출력할 수 있도록 합니다.
public struct ActionInfo: Sendable, Equatable {
    /// Action case 이름 (예: "increment", "fetchData")
    public let caseName: String

    /// Associated values (있는 경우)
    ///
    /// ValueProperty를 사용하여 State와 동일한 구조로 값을 표현합니다.
    public let associatedValues: [ValueProperty]

    /// 전체 설명 (기본 String(describing:) 결과)
    public let fullDescription: String

    public init(caseName: String, associatedValues: [ValueProperty], fullDescription: String) {
        self.caseName = caseName
        self.associatedValues = associatedValues
        self.fullDescription = fullDescription
    }
}
