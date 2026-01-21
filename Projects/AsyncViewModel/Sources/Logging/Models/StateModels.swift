//
//  StateModels.swift
//  AsyncViewModel
//
//  Created by jimmy on 2025/01/21.
//

import Foundation

// MARK: - StatePropertyChange

/// State 프로퍼티 변경 정보
public struct StatePropertyChange: Sendable, Equatable {
    /// 변경된 프로퍼티 이름
    public let propertyName: String

    /// 이전 값
    public let oldValue: ValueProperty

    /// 새 값
    public let newValue: ValueProperty

    public init(propertyName: String, oldValue: ValueProperty, newValue: ValueProperty) {
        self.propertyName = propertyName
        self.oldValue = oldValue
        self.newValue = newValue
    }
}

// MARK: - StateChangeInfo

/// State 변경 정보를 담는 구조체
///
/// 로거가 State 변경을 구조화된 형태로 접근할 수 있도록 합니다.
public struct StateChangeInfo: Sendable, Equatable {
    /// 이전 State 스냅샷
    public let oldState: ValueSnapshot

    /// 새 State 스냅샷
    public let newState: ValueSnapshot

    /// 변경된 프로퍼티 목록
    public let changes: [StatePropertyChange]

    public init(oldState: ValueSnapshot, newState: ValueSnapshot) {
        self.oldState = oldState
        self.newState = newState
        changes = StateChangeInfo.calculateChanges(
            oldProperties: oldState.properties,
            newProperties: newState.properties
        )
    }

    private static func calculateChanges(
        oldProperties: [ValueProperty],
        newProperties: [ValueProperty]
    ) -> [StatePropertyChange] {
        var changes: [StatePropertyChange] = []

        for (oldProp, newProp) in zip(oldProperties, newProperties) {
            if oldProp.value != newProp.value {
                changes.append(StatePropertyChange(
                    propertyName: oldProp.name,
                    oldValue: oldProp,
                    newValue: newProp
                ))
            }
        }

        return changes
    }
}
