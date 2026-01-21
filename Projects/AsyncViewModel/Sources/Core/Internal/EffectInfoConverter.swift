//
//  EffectInfoConverter.swift
//  AsyncViewModel
//
//  Created by jimmy on 2025/01/21.
//

import Foundation

// MARK: - EffectInfoConverter

/// AsyncEffect를 EffectInfo로 변환하는 유틸리티
///
/// Effect의 타입과 관련 정보를 추출하여 구조화된 EffectInfo로 변환합니다.
struct EffectInfoConverter<Action: Equatable & Sendable, CancelID: Hashable & Sendable> {
    // MARK: - Properties

    private let actionConverter: ActionInfoConverter

    // MARK: - Initialization

    init(actionConverter: ActionInfoConverter = ActionInfoConverter()) {
        self.actionConverter = actionConverter
    }

    // MARK: - Public Methods

    /// AsyncEffect를 EffectInfo로 변환
    ///
    /// - Parameter effect: 변환할 AsyncEffect
    /// - Returns: 구조화된 EffectInfo
    func convert(_ effect: AsyncEffect<Action, CancelID>) -> EffectInfo {
        let description = String(describing: effect)

        switch effect {
        case .none:
            return EffectInfo(
                effectType: .none,
                id: nil,
                relatedAction: nil,
                description: description
            )

        case let .action(action):
            return EffectInfo(
                effectType: .action,
                id: nil,
                relatedAction: actionConverter.convert(action),
                description: description
            )

        case let .run(id, _):
            let idString = id.map { String(describing: $0) }
            return EffectInfo(
                effectType: .run,
                id: idString,
                relatedAction: nil,
                description: description
            )

        case let .cancel(id):
            return EffectInfo(
                effectType: .cancel,
                id: String(describing: id),
                relatedAction: nil,
                description: description
            )

        case let .concurrent(effects):
            return EffectInfo(
                effectType: .concurrent,
                id: nil,
                relatedAction: nil,
                description: "concurrent(\(effects.count) effects)"
            )

        case let .sleepThen(id, duration, action):
            let idString = id.map { String(describing: $0) }
            let caseName = actionConverter.extractCaseName(from: action)
            return EffectInfo(
                effectType: .sleepThen,
                id: idString,
                relatedAction: actionConverter.convert(action),
                description: "sleepThen(duration: \(duration), action: \(caseName))"
            )

        case let .timer(id, interval, action):
            let idString = id.map { String(describing: $0) }
            let caseName = actionConverter.extractCaseName(from: action)
            return EffectInfo(
                effectType: .timer,
                id: idString,
                relatedAction: actionConverter.convert(action),
                description: "timer(interval: \(interval), action: \(caseName))"
            )
        }
    }
}
