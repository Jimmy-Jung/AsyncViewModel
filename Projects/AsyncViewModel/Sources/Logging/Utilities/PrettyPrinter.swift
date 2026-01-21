//
//  PrettyPrinter.swift
//  AsyncViewModel
//
//  Created by jimmy on 2025/01/21.
//

import Foundation

// MARK: - PrettyPrinter

/// 값을 JSON 스타일로 들여쓰기하여 포맷팅하는 유틸리티
public struct PrettyPrinter: Sendable {
    /// 들여쓰기 문자열
    public let indentString: String

    /// 최대 깊이 (nil이면 무제한)
    public let maxDepth: Int?

    public init(indentString: String = "  ", maxDepth: Int? = 10) {
        self.indentString = indentString
        self.maxDepth = maxDepth
    }

    /// 값을 JSON 스타일로 포맷팅
    public func format(_ value: Any) -> String {
        formatValue(value, depth: 0)
    }

    private func formatValue(_ value: Any, depth: Int) -> String {
        // maxDepth가 nil이면 무제한, 아니면 깊이 체크
        if let maxDepth = maxDepth, depth >= maxDepth {
            return "..."
        }

        let mirror = Mirror(reflecting: value)
        _ = String(repeating: indentString, count: depth)
        _ = String(repeating: indentString, count: depth + 1)

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

        case .foreignReference:
            return String(describing: value)

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

        if associatedValues.count == 1 && !associatedValues[0].contains(":"),
           let firstChild = mirror.children.first {
            // 단일 값인 경우 간단하게 표시
            return ".\(caseName)(\(formatValue(firstChild.value, depth: depth)))"
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
