//
//  EffectInfo.swift
//  AsyncViewModel
//
//  Created by jimmy on 2025/01/21.
//

import Foundation

// MARK: - EffectInfo

/// Effect 정보를 담는 구조체
///
/// 로거가 Effect를 구조화된 형태로 접근하여 다양한 포맷으로 출력할 수 있도록 합니다.
public struct EffectInfo: Sendable, Equatable {
    /// Effect 타입
    public let effectType: EffectType

    /// Effect ID (있는 경우)
    public let id: String?

    /// 연관된 Action (action, sleepThen 등)
    public let relatedAction: ActionInfo?

    /// 전체 설명
    public let description: String

    public init(
        effectType: EffectType,
        id: String?,
        relatedAction: ActionInfo?,
        description: String
    ) {
        self.effectType = effectType
        self.id = id
        self.relatedAction = relatedAction
        self.description = description
    }

    /// Effect 타입 enum
    public enum EffectType: String, Sendable, Equatable {
        case none
        case action
        case run
        case cancel
        case concurrent
        case sleepThen
        case timer
    }
}
