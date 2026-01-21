//
//  DefaultLogFormatter.swift
//  AsyncViewModel
//
//  Created by jimmy on 2025/01/21.
//

import Foundation

// MARK: - FormatterConfiguration

/// 로그 포맷터 설정
///
/// DefaultLogFormatter의 동작을 커스터마이징할 수 있는 옵션들입니다.
public struct FormatterConfiguration: Sendable {
    /// compact 모드에서 구조체 최대 프로퍼티 수 (기본값: 3)
    ///
    /// 이 수를 초과하는 프로퍼티는 "..." 으로 생략됩니다.
    public var maxProperties: Int

    /// 개별 값의 최대 문자 수 (기본값: 50)
    ///
    /// 이 길이를 초과하는 값은 잘려서 "..." 으로 표시됩니다.
    public var maxValueLength: Int

    /// standard 모드에서 최대 줄 수 (기본값: 10)
    ///
    /// 이 줄 수를 초과하면 잘려서 "..." 으로 표시됩니다.
    public var standardMaxLines: Int

    /// standard 모드에서 최대 깊이 (기본값: 3)
    ///
    /// 이 깊이를 초과하는 중첩 구조는 "..." 으로 표시됩니다.
    public var standardMaxDepth: Int

    /// 성능 측정 시간 소수점 자릿수 (기본값: 3)
    public var performanceDecimalPlaces: Int

    /// State 변경 화살표 기호 (기본값: "→")
    public var stateChangeArrow: String

    /// 들여쓰기 문자열 (기본값: "  ")
    public var indentString: String

    /// Optional 래핑 제거 여부 (기본값: true)
    public var unwrapOptional: Bool

    /// 변경된 프로퍼티 아이콘 (기본값: "◦")
    public var changedPropertyIcon: String

    /// OLD 값 아이콘 (기본값: "⊖")
    public var oldValueIcon: String

    /// NEW 값 아이콘 (기본값: "⊕")
    public var newValueIcon: String

    /// 기본 설정
    public static let `default` = FormatterConfiguration()

    public init(
        maxProperties: Int = 3,
        maxValueLength: Int = 50,
        standardMaxLines: Int = 10,
        standardMaxDepth: Int = 3,
        performanceDecimalPlaces: Int = 3,
        stateChangeArrow: String = "→",
        indentString: String = "  ",
        unwrapOptional: Bool = true,
        changedPropertyIcon: String = "🔘",
        oldValueIcon: String = "⛔️",
        newValueIcon: String = "🔵"
    ) {
        self.maxProperties = maxProperties
        self.maxValueLength = maxValueLength
        self.standardMaxLines = standardMaxLines
        self.standardMaxDepth = standardMaxDepth
        self.performanceDecimalPlaces = performanceDecimalPlaces
        self.stateChangeArrow = stateChangeArrow
        self.indentString = indentString
        self.unwrapOptional = unwrapOptional
        self.changedPropertyIcon = changedPropertyIcon
        self.oldValueIcon = oldValueIcon
        self.newValueIcon = newValueIcon
    }
}

// MARK: - DefaultLogFormatter

/// 기본 로그 포맷터
///
/// compact, standard, detailed 포맷을 지원하는 기본 구현체입니다.
///
/// ## 포맷 설명
///
/// - compact: 최소한의 정보만 표시 (case 이름, 변경된 값만)
/// - standard: 일반적인 정보 표시 (associated values 포함)
/// - detailed: 전체 정보 표시 (타입 정보, 전체 상태 포함)
///
/// ## 사용 예시
///
/// ```swift
/// // 기본 설정
/// let formatter = DefaultLogFormatter()
///
/// // 커스텀 설정
/// let config = FormatterConfiguration(
///     maxValueLength: 100,
///     stateChangeArrow: "->",
///     indentString: "    "
/// )
/// let customFormatter = DefaultLogFormatter(configuration: config)
/// ```
public struct DefaultLogFormatter: LogFormatter {
    /// 포맷터 설정
    public let configuration: FormatterConfiguration

    public init(configuration: FormatterConfiguration = .default) {
        self.configuration = configuration
    }

    // MARK: - Action Formatting

    public func formatAction(
        _ action: ActionInfo,
        format: LogFormat
    ) -> String {
        switch format {
        case .compact:
            return action.caseName

        case .standard:
            if action.associatedValues.isEmpty {
                return action.caseName
            }

            let indent = configuration.indentString
            let doubleIndent = indent + indent
            let icon = configuration.changedPropertyIcon

            // associated value가 1개이고 라벨이 caseName과 동일하면 라벨 생략
            if action.associatedValues.count == 1,
               let av = action.associatedValues.first,
               av.name == action.caseName
            {
                let truncatedValue = standardTruncateValue(av.value)
                let formattedValue = indentMultilineValue(truncatedValue, indent: indent)
                return "\(action.caseName): \(formattedValue)"
            }

            let formattedValues = action.associatedValues.map { av in
                let truncatedValue = standardTruncateValue(av.value)
                let formattedValue = indentMultilineValue(truncatedValue, indent: doubleIndent)
                if !av.name.isEmpty {
                    return "\(indent)\(icon) \(av.name): \(formattedValue)"
                }
                return "\(indent)\(icon) \(formattedValue)"
            }.joined(separator: "\n")

            return "\(action.caseName):\n\(formattedValues)"

        case .detailed:
            // detailed: JSON 스타일 구조화된 출력 (제한 없음)
            if action.associatedValues.isEmpty {
                return action.caseName
            }

            let indent = configuration.indentString
            let doubleIndent = indent + indent
            let icon = configuration.changedPropertyIcon

            // associated value가 1개이고 라벨이 caseName과 동일하면 라벨 생략
            if action.associatedValues.count == 1,
               let av = action.associatedValues.first,
               av.name == action.caseName
            {
                let formattedValue = indentMultilineValue(av.value, indent: indent)
                return "\(action.caseName): \(formattedValue)"
            }

            let formattedValues = action.associatedValues.map { av in
                // PrettyPrinter로 이미 포맷된 값을 그대로 사용
                let formattedValue = indentMultilineValue(av.value, indent: doubleIndent)
                if !av.name.isEmpty {
                    return "\(indent)\(icon) \(av.name): \(formattedValue)"
                }
                return "\(indent)\(icon) \(formattedValue)"
            }.joined(separator: "\n")

            return "\(action.caseName):\n\(formattedValues)"
        }
    }

    // MARK: - State Change Formatting

    public func formatStateChange(
        _ stateChange: StateChangeInfo,
        format: LogFormat
    ) -> String {
        let arrow = configuration.stateChangeArrow
        let indent = configuration.indentString
        let propertyIcon = configuration.changedPropertyIcon

        switch format {
        case .compact:
            if stateChange.changes.isEmpty {
                return "State: no changes"
            }
            let changedProps = stateChange.changes.map { change in
                let oldVal = compactValue(change.oldValue)
                let newVal = compactValue(change.newValue)
                return "\(indent)\(propertyIcon) \(change.propertyName): \(oldVal) \(arrow) \(newVal)"
            }.joined(separator: "\n")
            return "State changed (\(stateChange.changes.count) properties):\n\(changedProps)"

        case .standard:
            if stateChange.changes.isEmpty {
                return "State unchanged"
            }

            let oldIcon = configuration.oldValueIcon
            let newIcon = configuration.newValueIcon
            let doubleIndent = indent + indent
            let tripleIndent = doubleIndent + indent

            let changeDescriptions = stateChange.changes.map { change in
                let oldVal = standardValue(change.oldValue)
                let newVal = standardValue(change.newValue)

                // 멀티라인 값의 각 줄에 들여쓰기 적용
                let formattedOld = indentMultilineValue(oldVal, indent: tripleIndent)
                let formattedNew = indentMultilineValue(newVal, indent: tripleIndent)

                return "\(indent)\(propertyIcon) \(change.propertyName):\n\(doubleIndent)\(oldIcon) OLD: \(formattedOld)\n\(doubleIndent)\(newIcon) NEW: \(formattedNew)"
            }.joined(separator: "\n")

            return "State changed (\(stateChange.changes.count) properties):\n\(changeDescriptions)"

        case .detailed:
            // detailed: old/new 분리 표시, 전체 값 출력 (제한 없음)
            if stateChange.changes.isEmpty {
                return "State unchanged"
            }

            let oldIcon = configuration.oldValueIcon
            let newIcon = configuration.newValueIcon
            let doubleIndent = indent + indent
            let tripleIndent = doubleIndent + indent

            let changeDescriptions = stateChange.changes.map { change in
                let oldVal = detailedValue(change.oldValue)
                let newVal = detailedValue(change.newValue)

                // 멀티라인 값의 각 줄에 들여쓰기 적용
                let formattedOld = indentMultilineValue(oldVal, indent: tripleIndent)
                let formattedNew = indentMultilineValue(newVal, indent: tripleIndent)

                return "\(indent)\(propertyIcon) \(change.propertyName):\n\(doubleIndent)\(oldIcon) OLD: \(formattedOld)\n\(doubleIndent)\(newIcon) NEW: \(formattedNew)"
            }.joined(separator: "\n")

            return "State changed (\(stateChange.changes.count) properties):\n\(changeDescriptions)"
        }
    }

    /// 멀티라인 값의 각 줄에 들여쓰기를 적용
    ///
    /// 첫 줄은 그대로 두고, 나머지 줄에 들여쓰기를 추가합니다.
    private func indentMultilineValue(_ value: String, indent: String) -> String {
        let lines = value.split(separator: "\n", omittingEmptySubsequences: false)
        guard lines.count > 1 else {
            return value
        }

        // 첫 줄은 그대로, 나머지 줄에 들여쓰기 적용
        let firstLine = String(lines[0])
        let restLines = lines.dropFirst().map { indent + $0 }
        return ([firstLine] + restLines).joined(separator: "\n")
    }

    // MARK: - Effect Formatting

    public func formatEffect(
        _ effect: EffectInfo,
        format: LogFormat
    ) -> String {
        switch format {
        case .compact:
            if let id = effect.id {
                return "\(effect.effectType.rawValue)(\(id))"
            }
            return effect.effectType.rawValue

        case .standard:
            if let id = effect.id {
                return ".\(effect.effectType.rawValue)(id: \(id))"
            }
            return ".\(effect.effectType.rawValue)"

        case .detailed:
            var parts: [String] = []
            parts.append("type: \(effect.effectType.rawValue)")
            if let id = effect.id {
                parts.append("id: \(id)")
            }
            if let action = effect.relatedAction {
                parts.append("action: \(action.caseName)")
            }
            return "Effect(\(parts.joined(separator: ", ")))"
        }
    }

    public func formatEffects(
        _ effects: [EffectInfo],
        format: LogFormat
    ) -> [String] {
        switch format {
        case .compact:
            let summary = effects.map { effect in
                if let id = effect.id {
                    return "\(effect.effectType.rawValue)(\(id))"
                }
                return effect.effectType.rawValue
            }.joined(separator: ", ")
            return ["\(effects.count) effects: \(summary)"]

        case .standard:
            let summary = effects.map { effect in
                if let id = effect.id {
                    return "\(effect.effectType.rawValue)(\(id))"
                }
                return effect.effectType.rawValue
            }.joined(separator: ", ")
            return ["Effects[\(effects.count)]: \(summary)"]

        case .detailed:
            return effects.enumerated().map { index, effect in
                var parts: [String] = []
                parts.append("type: \(effect.effectType.rawValue)")
                if let id = effect.id {
                    parts.append("id: \(id)")
                }
                if let action = effect.relatedAction {
                    parts.append("action: \(action.caseName)")
                }
                let effectDescription = "Effect(\(parts.joined(separator: ", ")))"
                return "Effect \(index + 1)/\(effects.count): \(effectDescription)"
            }
        }
    }

    // MARK: - Performance Formatting

    public func formatPerformance(
        _ performance: PerformanceInfo,
        options: LoggingOptions
    ) -> String? {
        // 임계값 이하이고 showZeroPerformance가 false면 nil 반환
        if !options.showZeroPerformance, !performance.exceededThreshold {
            return nil
        }

        let formatString = "%.\(configuration.performanceDecimalPlaces)f"
        let durationStr = String(format: formatString, performance.duration)
        return "Performance - \(performance.operation): \(durationStr)s"
    }

    // MARK: - Error Formatting

    public func formatError(_ error: SendableError) -> String {
        "Error: \(error.localizedDescription) [\(error.domain):\(error.code)]"
    }

    // MARK: - Private Helpers

    /// compact 포맷용 값 변환
    ///
    /// 첫 줄을 최대한 보여줍니다. 멀티라인인 경우 첫 줄 전체 + "..."
    private func compactValue(_ property: StateProperty) -> String {
        // nil인 경우
        if property.isNil {
            return "nil"
        }

        // Optional 래핑 제거
        var displayValue = property.value
        if configuration.unwrapOptional,
           displayValue.hasPrefix("Optional("),
           displayValue.hasSuffix(")")
        {
            displayValue = String(displayValue.dropFirst(9).dropLast(1))
        }

        // 첫 줄만 표시 (첫 줄은 전체 출력)
        return truncateValue(displayValue)
    }

    /// standard 포맷용 값 변환
    ///
    /// compact보다 더 많은 정보를 한 줄로 표시합니다.
    /// 멀티라인 값은 첫 줄만 표시하되, compact보다 더 긴 길이를 허용합니다.
    private func standardValue(_ property: StateProperty) -> String {
        if property.isNil {
            return "nil"
        }

        var displayValue = property.value

        // Optional 래핑 제거
        if configuration.unwrapOptional,
           displayValue.hasPrefix("Optional("),
           displayValue.hasSuffix(")")
        {
            displayValue = String(displayValue.dropFirst(9).dropLast(1))
        }

        // 멀티라인 지원: 줄 수 제한 적용
        let lines = displayValue.split(separator: "\n", omittingEmptySubsequences: false)
        let maxLines = configuration.standardMaxLines

        if lines.count > maxLines {
            // 줄 수 제한 초과 시 잘라서 표시
            let truncatedLines = lines.prefix(maxLines)
            return truncatedLines.joined(separator: "\n") + "\n..."
        }

        return displayValue
    }

    /// detailed 포맷용 값 변환
    ///
    /// PrettyPrinter로 이미 포맷된 값을 그대로 출력합니다.
    private func detailedValue(_ property: StateProperty) -> String {
        if property.isNil {
            return "nil"
        }

        // PrettyPrinter로 이미 포맷된 값을 그대로 반환
        return property.value
    }

    /// 값을 첫 줄까지 표시 (compact용)
    ///
    /// - Parameter value: 원본 문자열
    /// - Returns: 첫 줄 전체 (멀티라인인 경우 "..." 추가)
    private func truncateValue(_ value: String) -> String {
        // 줄바꿈이 있으면 첫 줄만 사용 (첫 줄은 전체 출력)
        if let newlineIndex = value.firstIndex(of: "\n") {
            return String(value[..<newlineIndex]) + "..."
        }

        return value
    }

    /// 값 줄 수를 제한하여 표시 (standard용)
    ///
    /// - Parameter value: 원본 문자열
    /// - Returns: 잘린 문자열 (초과 시 "..." 추가)
    private func standardTruncateValue(_ value: String) -> String {
        let maxLines = configuration.standardMaxLines
        let lines = value.split(separator: "\n", omittingEmptySubsequences: false)

        if lines.count > maxLines {
            let truncatedLines = lines.prefix(maxLines)
            return truncatedLines.joined(separator: "\n") + "\n..."
        }

        return value
    }

    /// 타입 이름에서 모듈 접두사 제거
    ///
    /// 예: "AsyncViewModelExample.Company" → "Company"
    private func removeModulePrefix(_ typeName: String) -> String {
        // 마지막 점 이후의 문자열을 반환 (중첩 타입 지원)
        if let lastDotIndex = typeName.lastIndex(of: ".") {
            return String(typeName[typeName.index(after: lastDotIndex)...])
        }
        return typeName
    }

    /// 값 문자열에서 모듈 접두사 제거
    ///
    /// 예: "AsyncViewModelExample.Company(name: ...)" → "Company(name: ...)"
    private func removeModulePrefixFromValue(_ value: String) -> String {
        // 패턴: ModuleName.TypeName( 형태를 찾아서 TypeName( 로 변경
        var result = value

        // 정규식 대신 간단한 문자열 처리
        // "ModuleName.TypeName(" 패턴 찾기
        if let parenIndex = result.firstIndex(of: "(") {
            let prefix = String(result[..<parenIndex])
            if let lastDotIndex = prefix.lastIndex(of: ".") {
                let shortPrefix = String(prefix[prefix.index(after: lastDotIndex)...])
                let suffix = String(result[parenIndex...])
                result = shortPrefix + suffix
            }
        }

        return result
    }
}
