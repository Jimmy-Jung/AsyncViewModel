//
//  StateSnapshot.swift
//  AsyncViewModel
//
//  Created by jimmy on 2025/01/20.
//

import Foundation

// MARK: - StateProperty

/// State의 개별 프로퍼티 정보를 담는 구조체
///
/// 로거가 State의 프로퍼티를 구조화된 형태로 접근할 수 있도록 합니다.
public struct StateProperty: Sendable, Equatable {
    /// 프로퍼티 이름
    public let name: String

    /// 프로퍼티 값의 문자열 표현
    public let value: String

    /// 프로퍼티 타입 이름
    public let typeName: String

    /// 중첩된 프로퍼티 (struct/class인 경우)
    public let children: [StateProperty]

    /// 값이 nil인지 여부 (Optional 타입인 경우)
    public let isNil: Bool

    public init(
        name: String,
        value: String,
        typeName: String,
        children: [StateProperty] = [],
        isNil: Bool = false
    ) {
        self.name = name
        self.value = value
        self.typeName = typeName
        self.children = children
        self.isNil = isNil
    }
}

// MARK: - StateSnapshot

/// State의 구조화된 스냅샷
///
/// 로거가 State를 구조화된 형태로 접근하여 다양한 포맷으로 출력할 수 있도록 합니다.
///
/// 사용 예시:
/// ```swift
/// let snapshot = StateSnapshot(from: state)
/// // 로거에서 snapshot.properties를 순회하며 원하는 형태로 포맷팅
/// ```
public struct StateSnapshot: Sendable, Equatable {
    /// State 타입 이름
    public let typeName: String

    /// State의 프로퍼티 목록
    public let properties: [StateProperty]

    public init(typeName: String, properties: [StateProperty]) {
        self.typeName = typeName
        self.properties = properties
    }

    /// Mirror를 사용하여 State에서 StateSnapshot 생성
    ///
    /// - Parameters:
    ///   - value: 스냅샷을 생성할 State 값
    ///   - maxDepth: 중첩 구조의 최대 깊이 (기본값: 5)
    ///   - usePrettyPrint: JSON 스타일 포맷팅 사용 여부 (기본값: true)
    /// - Returns: 구조화된 StateSnapshot
    public init<T>(from value: T, maxDepth: Int = 5, usePrettyPrint: Bool = true) {
        let mirror = Mirror(reflecting: value)
        typeName = StateSnapshot.shortTypeName(value)
        properties = StateSnapshot.extractProperties(
            from: mirror,
            currentDepth: 0,
            maxDepth: maxDepth,
            usePrettyPrint: usePrettyPrint
        )
    }

    private static func extractProperties(
        from mirror: Mirror,
        currentDepth: Int,
        maxDepth: Int,
        usePrettyPrint: Bool
    ) -> [StateProperty] {
        guard currentDepth < maxDepth else {
            return []
        }

        return mirror.children.compactMap { child -> StateProperty? in
            guard let label = child.label else { return nil }

            let childMirror = Mirror(reflecting: child.value)
            let typeName = shortTypeName(child.value)

            // 값 포맷팅
            let value: String
            if usePrettyPrint {
                let printer = PrettyPrinter(maxDepth: maxDepth - currentDepth)
                value = printer.format(child.value)
            } else {
                value = String(describing: child.value)
            }

            // Optional 처리
            let isNil = isOptionalNil(child.value)

            // 중첩 프로퍼티 추출 (struct, class인 경우)
            let children: [StateProperty]
            switch childMirror.displayStyle {
            case .struct, .class:
                children = extractProperties(
                    from: childMirror,
                    currentDepth: currentDepth + 1,
                    maxDepth: maxDepth,
                    usePrettyPrint: usePrettyPrint
                )
            default:
                children = []
            }

            return StateProperty(
                name: label,
                value: value,
                typeName: typeName,
                children: children,
                isNil: isNil
            )
        }
    }

    private static func isOptionalNil(_ value: Any) -> Bool {
        let mirror = Mirror(reflecting: value)
        guard mirror.displayStyle == .optional else { return false }
        return mirror.children.isEmpty
    }

    private static func shortTypeName(_ value: Any) -> String {
        let fullName = String(describing: type(of: value))
        // 모듈 이름 제거 (첫 번째 '.'까지가 모듈명)
        // 예: AsyncViewModelExample.Company.Department -> Company.Department
        if let firstDot = fullName.firstIndex(of: ".") {
            return String(fullName[fullName.index(after: firstDot)...])
        }
        return fullName
    }
}

// MARK: - StateSnapshot Formatting Extensions

public extension StateSnapshot {
    /// 한 줄로 압축된 문자열 표현
    var compactDescription: String {
        let props = properties.map { "\($0.name)=\($0.value)" }.joined(separator: ", ")
        return "\(typeName)(\(props))"
    }

    /// 표준 포맷의 문자열 표현
    var standardDescription: String {
        let props = properties.map { property -> String in
            if property.isNil {
                return "  \(property.name): nil"
            }
            return "  \(property.name): \(property.value)"
        }.joined(separator: "\n")
        return "\(typeName) {\n\(props)\n}"
    }

    /// 상세 포맷의 문자열 표현 (타입 정보 포함)
    var detailedDescription: String {
        formatDetailed(properties: properties, indent: 0)
    }

    private func formatDetailed(properties: [StateProperty], indent: Int) -> String {
        let indentStr = String(repeating: "  ", count: indent)
        let nextIndent = String(repeating: "  ", count: indent + 1)

        if indent == 0 {
            let props = properties.map { property -> String in
                formatProperty(property, indent: indent + 1)
            }.joined(separator: "\n")
            return "\(typeName) {\n\(props)\n}"
        } else {
            return properties.map { property -> String in
                formatProperty(property, indent: indent)
            }.joined(separator: "\n")
        }
    }

    private func formatProperty(_ property: StateProperty, indent: Int) -> String {
        let indentStr = String(repeating: "  ", count: indent)

        if property.isNil {
            return "\(indentStr)\(property.name): nil (\(property.typeName))"
        }

        if property.children.isEmpty {
            return "\(indentStr)\(property.name): \(property.value) (\(property.typeName))"
        } else {
            let childrenStr = property.children.map { child in
                formatProperty(child, indent: indent + 1)
            }.joined(separator: "\n")
            return "\(indentStr)\(property.name): \(property.typeName) {\n\(childrenStr)\n\(indentStr)}"
        }
    }
}

// MARK: - PrettyPrinter

/// 값을 JSON 스타일로 들여쓰기하여 포맷팅하는 유틸리티
public struct PrettyPrinter: Sendable {
    /// 들여쓰기 문자열
    public let indentString: String

    /// 최대 깊이
    public let maxDepth: Int

    public init(indentString: String = "  ", maxDepth: Int = 10) {
        self.indentString = indentString
        self.maxDepth = maxDepth
    }

    /// 값을 JSON 스타일로 포맷팅
    public func format(_ value: Any) -> String {
        formatValue(value, depth: 0)
    }

    private func formatValue(_ value: Any, depth: Int) -> String {
        guard depth < maxDepth else {
            return "..."
        }

        let mirror = Mirror(reflecting: value)
        let indent = String(repeating: indentString, count: depth)
        let nextIndent = String(repeating: indentString, count: depth + 1)

        switch mirror.displayStyle {
        case .struct, .class:
            return formatStructOrClass(mirror: mirror, typeName: shortTypeName(value), depth: depth)

        case .collection:
            return formatCollection(mirror: mirror, depth: depth)

        case .dictionary:
            return formatDictionary(mirror: mirror, depth: depth)

        case .optional:
            if mirror.children.isEmpty {
                return "nil"
            } else if let (_, unwrapped) = mirror.children.first {
                return formatValue(unwrapped, depth: depth)
            }
            return "nil"

        case .enum:
            return formatEnum(value: value, mirror: mirror, depth: depth)

        case .tuple:
            return formatTuple(mirror: mirror, depth: depth)

        case .set:
            return formatSet(mirror: mirror, depth: depth)

        case .none:
            // 기본 타입 (String, Int, Bool 등)
            return formatPrimitive(value)

        @unknown default:
            return String(describing: value)
        }
    }

    private func formatStructOrClass(mirror: Mirror, typeName: String, depth: Int) -> String {
        let indent = String(repeating: indentString, count: depth)
        let nextIndent = String(repeating: indentString, count: depth + 1)

        let children = mirror.children.compactMap { child -> String? in
            guard let label = child.label else { return nil }
            let formattedValue = formatValue(child.value, depth: depth + 1)
            return "\(nextIndent)\"\(label)\": \(formattedValue)"
        }

        if children.isEmpty {
            return "\(typeName) {}"
        }

        return "\(typeName) {\n\(children.joined(separator: ",\n"))\n\(indent)}"
    }

    private func formatCollection(mirror: Mirror, depth: Int) -> String {
        let indent = String(repeating: indentString, count: depth)
        let nextIndent = String(repeating: indentString, count: depth + 1)

        let items = mirror.children.map { child -> String in
            "\(nextIndent)\(formatValue(child.value, depth: depth + 1))"
        }

        if items.isEmpty {
            return "[]"
        }

        return "[\n\(items.joined(separator: ",\n"))\n\(indent)]"
    }

    private func formatDictionary(mirror: Mirror, depth: Int) -> String {
        let indent = String(repeating: indentString, count: depth)
        let nextIndent = String(repeating: indentString, count: depth + 1)

        let items = mirror.children.compactMap { child -> String? in
            guard let pair = child.value as? (key: Any, value: Any) else {
                // Mirror로 분해
                let pairMirror = Mirror(reflecting: child.value)
                guard pairMirror.children.count >= 2 else { return nil }
                let children = Array(pairMirror.children)
                let key = children[0].value
                let value = children[1].value
                return "\(nextIndent)\(formatValue(key, depth: depth + 1)): \(formatValue(value, depth: depth + 1))"
            }
            return "\(nextIndent)\(formatValue(pair.key, depth: depth + 1)): \(formatValue(pair.value, depth: depth + 1))"
        }

        if items.isEmpty {
            return "{}"
        }

        return "{\n\(items.joined(separator: ",\n"))\n\(indent)}"
    }

    private func formatEnum(value: Any, mirror: Mirror, depth: Int) -> String {
        let indent = String(repeating: indentString, count: depth)
        let nextIndent = String(repeating: indentString, count: depth + 1)

        // enum의 case 이름 추출
        let description = String(describing: value)

        if mirror.children.isEmpty {
            // Associated value 없는 경우
            return ".\(description)"
        }

        // Associated value가 있는 경우
        let caseName = description.components(separatedBy: "(").first ?? description

        let associatedValues = mirror.children.map { child -> String in
            if let label = child.label, !label.starts(with: ".") {
                return "\(nextIndent)\(label): \(formatValue(child.value, depth: depth + 1))"
            } else {
                return "\(nextIndent)\(formatValue(child.value, depth: depth + 1))"
            }
        }

        if associatedValues.count == 1 && !associatedValues[0].contains(":") {
            // 단일 값인 경우 간단하게 표시
            return ".\(caseName)(\(formatValue(mirror.children.first!.value, depth: depth)))"
        }

        return ".\(caseName)(\n\(associatedValues.joined(separator: ",\n"))\n\(indent))"
    }

    private func formatTuple(mirror: Mirror, depth: Int) -> String {
        let indent = String(repeating: indentString, count: depth)
        let nextIndent = String(repeating: indentString, count: depth + 1)

        let items = mirror.children.map { child -> String in
            if let label = child.label, !label.starts(with: ".") {
                return "\(nextIndent)\(label): \(formatValue(child.value, depth: depth + 1))"
            } else {
                return "\(nextIndent)\(formatValue(child.value, depth: depth + 1))"
            }
        }

        return "(\n\(items.joined(separator: ",\n"))\n\(indent))"
    }

    private func formatSet(mirror: Mirror, depth: Int) -> String {
        let indent = String(repeating: indentString, count: depth)
        let nextIndent = String(repeating: indentString, count: depth + 1)

        let items = mirror.children.map { child -> String in
            "\(nextIndent)\(formatValue(child.value, depth: depth + 1))"
        }

        if items.isEmpty {
            return "Set([])"
        }

        return "Set([\n\(items.joined(separator: ",\n"))\n\(indent)])"
    }

    private func formatPrimitive(_ value: Any) -> String {
        if let string = value as? String {
            return "\"\(string)\""
        } else if let bool = value as? Bool {
            return bool ? "true" : "false"
        } else if let date = value as? Date {
            let formatter = ISO8601DateFormatter()
            return "\"\(formatter.string(from: date))\""
        } else {
            return String(describing: value)
        }
    }

    private func shortTypeName(_ value: Any) -> String {
        let fullName = String(describing: type(of: value))
        // 모듈 이름 제거 (첫 번째 '.'까지가 모듈명)
        // 예: AsyncViewModelExample.Company.Department -> Company.Department
        if let firstDot = fullName.firstIndex(of: ".") {
            return String(fullName[fullName.index(after: firstDot)...])
        }
        return fullName
    }
}

// MARK: - StatePropertyChange

/// State 프로퍼티 변경 정보
public struct StatePropertyChange: Sendable, Equatable {
    /// 변경된 프로퍼티 이름
    public let propertyName: String

    /// 이전 값
    public let oldValue: StateProperty

    /// 새 값
    public let newValue: StateProperty

    public init(propertyName: String, oldValue: StateProperty, newValue: StateProperty) {
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
    public let oldState: StateSnapshot

    /// 새 State 스냅샷
    public let newState: StateSnapshot

    /// 변경된 프로퍼티 목록
    public let changes: [StatePropertyChange]

    public init(oldState: StateSnapshot, newState: StateSnapshot) {
        self.oldState = oldState
        self.newState = newState
        changes = StateChangeInfo.calculateChanges(
            oldProperties: oldState.properties,
            newProperties: newState.properties
        )
    }

    private static func calculateChanges(
        oldProperties: [StateProperty],
        newProperties: [StateProperty]
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
