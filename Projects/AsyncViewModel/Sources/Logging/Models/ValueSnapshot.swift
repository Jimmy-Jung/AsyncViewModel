//
//  ValueSnapshot.swift
//  AsyncViewModel
//
//  Created by jimmy on 2025/01/21.
//

import Foundation

// MARK: - ValueProperty

/// 값의 개별 프로퍼티 정보를 담는 구조체
///
/// 로거가 State, Action 등의 프로퍼티를 구조화된 형태로 접근할 수 있도록 합니다.
public struct ValueProperty: Sendable, Equatable {
    /// 프로퍼티 이름
    public let name: String

    /// 프로퍼티 값의 문자열 표현
    public let value: String

    /// 프로퍼티 타입 이름
    public let typeName: String

    /// 중첩된 프로퍼티 (struct/class인 경우)
    public let children: [ValueProperty]

    /// 값이 nil인지 여부 (Optional 타입인 경우)
    public let isNil: Bool

    public init(
        name: String,
        value: String,
        typeName: String,
        children: [ValueProperty] = [],
        isNil: Bool = false
    ) {
        self.name = name
        self.value = value
        self.typeName = typeName
        self.children = children
        self.isNil = isNil
    }
}

// MARK: - ValueSnapshot

/// 값의 구조화된 스냅샷
///
/// 로거가 State, Action 등을 구조화된 형태로 접근하여 다양한 포맷으로 출력할 수 있도록 합니다.
///
/// 사용 예시:
/// ```swift
/// let snapshot = ValueSnapshot(from: state)
/// // 로거에서 snapshot.properties를 순회하며 원하는 형태로 포맷팅
/// ```
public struct ValueSnapshot: Sendable, Equatable {
    /// 타입 이름
    public let typeName: String

    /// 프로퍼티 목록
    public let properties: [ValueProperty]

    public init(typeName: String, properties: [ValueProperty]) {
        self.typeName = typeName
        self.properties = properties
    }

    /// Mirror를 사용하여 값에서 ValueSnapshot 생성
    ///
    /// 원본 데이터를 그대로 보관합니다. 출력 시 포맷터에서 깊이 제한 등을 적용합니다.
    ///
    /// - Parameter value: 스냅샷을 생성할 값
    /// - Returns: 구조화된 ValueSnapshot
    public init<T>(from value: T) {
        let mirror = Mirror(reflecting: value)
        typeName = ValueSnapshot.shortTypeName(value)
        properties = ValueSnapshot.extractProperties(from: mirror)
    }

    /// Mirror에서 ValueProperty 배열 추출 (재사용 가능)
    ///
    /// - Parameters:
    ///   - mirror: 분석할 Mirror
    ///   - printer: 값 포맷팅에 사용할 PrettyPrinter (기본값: maxDepth nil)
    /// - Returns: 추출된 ValueProperty 배열
    static func extractProperties(
        from mirror: Mirror,
        printer: PrettyPrinter = PrettyPrinter(maxDepth: nil)
    ) -> [ValueProperty] {
        return mirror.children.compactMap { child -> ValueProperty? in
            guard let label = child.label else { return nil }

            let childMirror = Mirror(reflecting: child.value)
            let typeName = shortTypeName(child.value)

            // 원본 값 저장 (PrettyPrinter로 JSON 스타일 포맷팅)
            let value = printer.format(child.value)

            // Optional 처리
            let isNil = isOptionalNil(child.value)

            // 중첩 프로퍼티 추출 (struct, class인 경우)
            let children: [ValueProperty]
            switch childMirror.displayStyle {
            case .struct, .class:
                children = extractProperties(from: childMirror, printer: printer)
            default:
                children = []
            }

            return ValueProperty(
                name: label,
                value: value,
                typeName: typeName,
                children: children,
                isNil: isNil
            )
        }
    }

    /// Optional 값이 nil인지 확인 (재사용 가능)
    ///
    /// - Parameter value: 확인할 값
    /// - Returns: Optional이면서 nil인 경우 true
    static func isOptionalNil(_ value: Any) -> Bool {
        let mirror = Mirror(reflecting: value)
        guard mirror.displayStyle == .optional else { return false }
        return mirror.children.isEmpty
    }

    /// 타입 이름에서 모듈 접두사 제거 (재사용 가능)
    ///
    /// 예: AsyncViewModelExample.Company.Department -> Company.Department
    static func shortTypeName(_ value: Any) -> String {
        let fullName = String(describing: type(of: value))
        // 모듈 이름 제거 (첫 번째 '.'까지가 모듈명)
        // 예: AsyncViewModelExample.Company.Department -> Company.Department
        if let firstDot = fullName.firstIndex(of: ".") {
            return String(fullName[fullName.index(after: firstDot)...])
        }
        return fullName
    }
}

// MARK: - ValueSnapshot Formatting Extensions

public extension ValueSnapshot {
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

    private func formatDetailed(properties: [ValueProperty], indent: Int) -> String {
        _ = String(repeating: "  ", count: indent)

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

    private func formatProperty(_ property: ValueProperty, indent: Int) -> String {
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

// MARK: - Type Aliases for Backward Compatibility

/// StateProperty의 별칭 (하위 호환성)
public typealias StateProperty = ValueProperty

/// StateSnapshot의 별칭 (하위 호환성)
public typealias StateSnapshot = ValueSnapshot
