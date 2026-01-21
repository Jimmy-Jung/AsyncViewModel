//
//  ActionInfoConverter.swift
//  AsyncViewModel
//
//  Created by jimmy on 2025/01/21.
//

import Foundation

// MARK: - ActionInfoConverter

/// Action을 ActionInfo로 변환하는 유틸리티
///
/// enum Action의 case 이름과 associated values를 추출하여
/// 구조화된 ActionInfo로 변환합니다.
struct ActionInfoConverter {
    // MARK: - Properties

    private let printer: PrettyPrinter

    // MARK: - Initialization

    init(printer: PrettyPrinter = PrettyPrinter(maxDepth: nil)) {
        self.printer = printer
    }

    // MARK: - Public Methods

    /// Action을 ActionInfo로 변환
    ///
    /// - Parameter action: 변환할 Action
    /// - Returns: 구조화된 ActionInfo
    func convert<Action>(_ action: Action) -> ActionInfo {
        let caseName = extractCaseName(from: action)
        let fullDescription = String(describing: action)
        let mirror = Mirror(reflecting: action)

        var associatedValues: [ValueProperty] = []

        // enum의 associated values 추출
        for child in mirror.children {
            let name = child.label?.starts(with: ".") == true
                ? ""
                : (child.label ?? "")
            let value = printer.format(child.value)
            let typeName = String(describing: type(of: child.value))

            // 중첩 프로퍼티 추출 (ValueSnapshot 재사용)
            let childMirror = Mirror(reflecting: child.value)
            let children: [ValueProperty]
            switch childMirror.displayStyle {
            case .struct, .class:
                children = ValueSnapshot.extractProperties(from: childMirror, printer: printer)
            default:
                children = []
            }

            associatedValues.append(ValueProperty(
                name: name,
                value: value,
                typeName: typeName,
                children: children,
                isNil: ValueSnapshot.isOptionalNil(child.value)
            ))
        }

        return ActionInfo(
            caseName: caseName,
            associatedValues: associatedValues,
            fullDescription: fullDescription
        )
    }

    /// Action에서 case 이름만 추출 (중첩 타입 제거)
    ///
    /// - Parameter action: Action 값
    /// - Returns: case 이름만 (예: "increment", "fetchData")
    func extractCaseName<Action>(from action: Action) -> String {
        let description = String(describing: action)

        // 먼저 첫 번째 '('를 찾아 associated value 부분을 제거
        // 이렇게 해야 associated value 내부의 '.'에 영향받지 않음
        let baseDescription: String
        if let firstParenIndex = description.firstIndex(of: "(") {
            baseDescription = String(description[..<firstParenIndex])
        } else {
            baseDescription = description
        }

        // 그 다음 마지막 '.'를 찾아 case name만 추출
        // "ModuleName.EnumName.caseName" -> "caseName"
        if let lastDotIndex = baseDescription.lastIndex(of: ".") {
            return String(baseDescription[baseDescription.index(after: lastDotIndex)...])
        }

        return baseDescription
    }
}
