//
//  LogFormatterTests.swift
//  AsyncViewModelTests
//
//  Created by jimmy on 2025/01/21.
//

@testable import AsyncViewModelCore
import Foundation
import Testing

// MARK: - LogFormatter Tests

@Suite("LogFormatter Tests")
struct LogFormatterTests {
    let formatter = DefaultLogFormatter()

    // MARK: - Action Formatting Tests

    @Test("Action compact 포맷은 case 이름만 반환한다")
    func actionCompactFormat() {
        let action = ActionInfo(
            caseName: "fetchData",
            associatedValues: [
                ValueProperty(name: "id", value: "123", typeName: "Int")
            ],
            fullDescription: "fetchData(id: 123)"
        )

        let result = formatter.formatAction(action, format: .compact)
        #expect(result == "fetchData")
    }

    @Test("Action standard 포맷은 멀티라인으로 associated values를 반환한다")
    func actionStandardFormat() {
        let action = ActionInfo(
            caseName: "fetchData",
            associatedValues: [
                ValueProperty(name: "id", value: "123", typeName: "Int")
            ],
            fullDescription: "fetchData(id: 123)"
        )

        let result = formatter.formatAction(action, format: .standard)
        let expected = """
        fetchData:
          🟡 id: 123
        """
        #expect(result == expected)
    }

    @Test("Action detailed 포맷은 구조화된 출력을 제공한다")
    func actionDetailedFormat() {
        let action = ActionInfo(
            caseName: "fetchData",
            associatedValues: [
                ValueProperty(name: "id", value: "123", typeName: "Int")
            ],
            fullDescription: "fetchData(id: 123)"
        )

        let result = formatter.formatAction(action, format: .detailed)
        let expected = """
        fetchData:
          🟡 id: 123
        """
        #expect(result == expected)
    }

    @Test("Action associated values 없으면 case 이름만 반환한다")
    func actionWithoutAssociatedValues() {
        let action = ActionInfo(
            caseName: "increment",
            associatedValues: [],
            fullDescription: "increment"
        )

        #expect(formatter.formatAction(action, format: .compact) == "increment")
        #expect(formatter.formatAction(action, format: .standard) == "increment")
        #expect(formatter.formatAction(action, format: .detailed) == "increment")
    }

    @Test("Action 라벨 없는 associated value도 처리한다")
    func actionWithUnlabeledAssociatedValue() {
        let action = ActionInfo(
            caseName: "setCount",
            associatedValues: [
                ValueProperty(name: "", value: "42", typeName: "Int")
            ],
            fullDescription: "setCount(42)"
        )

        let result = formatter.formatAction(action, format: .standard)
        let expected = """
        setCount:
          🟡 42
        """
        #expect(result == expected)
    }

    // MARK: - Effect Formatting Tests

    @Test("Effect compact 포맷은 타입만 반환한다")
    func effectCompactFormat() {
        let effect = EffectInfo(
            effectType: .run,
            id: "fetchUser",
            relatedAction: nil,
            description: ".run(id: fetchUser)"
        )

        let result = formatter.formatEffect(effect, format: .compact)
        #expect(result == "run(fetchUser)")
    }

    @Test("Effect standard 포맷은 타입과 id를 반환한다")
    func effectStandardFormat() {
        let effect = EffectInfo(
            effectType: .run,
            id: "fetchUser",
            relatedAction: nil,
            description: ".run(id: fetchUser)"
        )

        let result = formatter.formatEffect(effect, format: .standard)
        #expect(result == ".run(id: fetchUser)")
    }

    @Test("Effect detailed 포맷은 전체 정보를 반환한다")
    func effectDetailedFormat() {
        let relatedAction = ActionInfo(
            caseName: "fetchCompleted",
            associatedValues: [],
            fullDescription: "fetchCompleted"
        )
        let effect = EffectInfo(
            effectType: .run,
            id: "fetchUser",
            relatedAction: relatedAction,
            description: ".run(id: fetchUser)"
        )

        let result = formatter.formatEffect(effect, format: .detailed)
        #expect(result == "Effect(type: run, id: fetchUser, action: fetchCompleted)")
    }

    @Test("Effect id 없으면 타입만 반환한다")
    func effectWithoutId() {
        let effect = EffectInfo(
            effectType: .none,
            id: nil,
            relatedAction: nil,
            description: ".none"
        )

        #expect(formatter.formatEffect(effect, format: .compact) == "none")
        #expect(formatter.formatEffect(effect, format: .standard) == ".none")
    }

    // MARK: - Effects (Multiple) Formatting Tests

    @Test("Effects compact/standard는 단일 문자열 배열을 반환한다")
    func effectsCompactAndStandardFormat() {
        let effects = [
            EffectInfo(effectType: .run, id: "fetch1", relatedAction: nil, description: ""),
            EffectInfo(effectType: .cancel, id: "fetch2", relatedAction: nil, description: "")
        ]

        let compactResult = formatter.formatEffects(effects, format: .compact)
        #expect(compactResult.count == 1)
        #expect(compactResult[0].contains("run(fetch1)"))
        #expect(compactResult[0].contains("cancel(fetch2)"))

        let standardResult = formatter.formatEffects(effects, format: .standard)
        #expect(standardResult.count == 1)
        #expect(standardResult[0].contains("Effects[2]"))
    }

    @Test("Effects detailed는 개별 문자열 배열을 반환한다")
    func effectsDetailedFormat() {
        let effects = [
            EffectInfo(effectType: .run, id: "fetch1", relatedAction: nil, description: ""),
            EffectInfo(effectType: .cancel, id: "fetch2", relatedAction: nil, description: "")
        ]

        let result = formatter.formatEffects(effects, format: .detailed)
        #expect(result.count == 2)
        #expect(result[0].contains("Effect 1/2"))
        #expect(result[1].contains("Effect 2/2"))
    }

    // MARK: - Performance Formatting Tests

    @Test("Performance는 임계값 초과 시 문자열을 반환한다")
    func performanceExceedsThreshold() {
        let performance = PerformanceInfo(
            operation: "Action processing",
            operationType: .actionProcessing,
            duration: 0.1,
            threshold: 0.05,
            exceededThreshold: true
        )
        let options = LoggingOptions()

        let result = formatter.formatPerformance(performance, options: options)
        guard let result = result else {
            Issue.record("Expected non-nil result")
            return
        }
        #expect(result.contains("0.100s"))
        #expect(result.contains("Action processing"))
    }

    @Test("Performance는 임계값 이하이고 showZeroPerformance가 false면 nil을 반환한다")
    func performanceBelowThreshold() {
        let performance = PerformanceInfo(
            operation: "Action processing",
            operationType: .actionProcessing,
            duration: 0.01,
            threshold: 0.05,
            exceededThreshold: false
        )
        var options = LoggingOptions()
        options.showZeroPerformance = false

        let result = formatter.formatPerformance(performance, options: options)
        #expect(result == nil)
    }

    @Test("Performance는 showZeroPerformance가 true면 항상 문자열을 반환한다")
    func performanceWithShowZeroEnabled() {
        let performance = PerformanceInfo(
            operation: "Action processing",
            operationType: .actionProcessing,
            duration: 0.01,
            threshold: 0.05,
            exceededThreshold: false
        )
        var options = LoggingOptions()
        options.showZeroPerformance = true

        let result = formatter.formatPerformance(performance, options: options)
        #expect(result != nil)
    }

    // MARK: - Error Formatting Tests

    @Test("Error는 올바르게 포맷팅된다")
    func errorFormatting() {
        let error = SendableError(
            message: "Not Found",
            code: 404,
            domain: "HTTPError"
        )

        let result = formatter.formatError(error)
        #expect(result.contains("Not Found"))
        #expect(result.contains("HTTPError"))
        #expect(result.contains("404"))
    }

    // MARK: - State Change Formatting Tests

    @Test("StateChange compact 포맷은 변경된 프로퍼티만 간략하게 표시한다")
    func stateChangeCompactFormat() {
        let oldState = StateSnapshot(
            typeName: "State",
            properties: [
                StateProperty(name: "count", value: "0", typeName: "Int")
            ]
        )
        let newState = StateSnapshot(
            typeName: "State",
            properties: [
                StateProperty(name: "count", value: "1", typeName: "Int")
            ]
        )
        let stateChange = StateChangeInfo(oldState: oldState, newState: newState)

        let result = formatter.formatStateChange(stateChange, format: .compact)
        #expect(result.contains("🟡 count"))
        #expect(result.contains("0"))
        #expect(result.contains("→"))
        #expect(result.contains("1"))
    }

    @Test("StateChange 변경 없으면 적절한 메시지를 반환한다")
    func stateChangeNoChanges() {
        let state = StateSnapshot(
            typeName: "State",
            properties: [
                StateProperty(name: "count", value: "0", typeName: "Int")
            ]
        )
        let stateChange = StateChangeInfo(oldState: state, newState: state)

        let compactResult = formatter.formatStateChange(stateChange, format: .compact)
        #expect(compactResult.contains("no changes"))

        let standardResult = formatter.formatStateChange(stateChange, format: .standard)
        #expect(standardResult.contains("unchanged"))
    }
}

// MARK: - FormatterConfiguration Tests

@Suite("FormatterConfiguration Tests")
struct FormatterConfigurationTests {
    @Test("커스텀 화살표 기호가 적용된다")
    func customArrowSymbol() {
        let config = FormatterConfiguration(stateChangeArrow: "->")
        let formatter = DefaultLogFormatter(configuration: config)

        let oldState = StateSnapshot(
            typeName: "State",
            properties: [StateProperty(name: "count", value: "0", typeName: "Int")]
        )
        let newState = StateSnapshot(
            typeName: "State",
            properties: [StateProperty(name: "count", value: "1", typeName: "Int")]
        )
        let stateChange = StateChangeInfo(oldState: oldState, newState: newState)

        let result = formatter.formatStateChange(stateChange, format: .compact)
        #expect(result.contains("->"))
        #expect(!result.contains("→"))
    }

    @Test("커스텀 들여쓰기가 적용된다")
    func customIndent() {
        let config = FormatterConfiguration(indentString: "    ")
        let formatter = DefaultLogFormatter(configuration: config)

        let oldState = StateSnapshot(
            typeName: "State",
            properties: [StateProperty(name: "count", value: "0", typeName: "Int")]
        )
        let newState = StateSnapshot(
            typeName: "State",
            properties: [StateProperty(name: "count", value: "1", typeName: "Int")]
        )
        let stateChange = StateChangeInfo(oldState: oldState, newState: newState)

        let result = formatter.formatStateChange(stateChange, format: .compact)
        #expect(result.contains("    🟡 count"))
    }

    @Test("커스텀 성능 소수점 자릿수가 적용된다")
    func customPerformanceDecimalPlaces() {
        let config = FormatterConfiguration(performanceDecimalPlaces: 6)
        let formatter = DefaultLogFormatter(configuration: config)

        let performance = PerformanceInfo(
            operation: "Test",
            operationType: .custom,
            duration: 0.123456789,
            threshold: 0.1,
            exceededThreshold: true
        )
        var options = LoggingOptions()
        options.showZeroPerformance = true

        let result = formatter.formatPerformance(performance, options: options)
        guard let result = result else {
            Issue.record("Expected non-nil result")
            return
        }
        #expect(result.contains("0.123457"))
    }

    @Test("maxValueLength가 적용된다")
    func maxValueLengthApplied() {
        let config = FormatterConfiguration(maxValueLength: 10)
        let formatter = DefaultLogFormatter(configuration: config)

        let oldState = StateSnapshot(
            typeName: "State",
            properties: [
                StateProperty(
                    name: "longValue",
                    value: "short",
                    typeName: "String"
                )
            ]
        )
        let newState = StateSnapshot(
            typeName: "State",
            properties: [
                StateProperty(
                    name: "longValue",
                    value: "This is a very long value\nthat spans multiple lines",
                    typeName: "String"
                )
            ]
        )
        let stateChange = StateChangeInfo(oldState: oldState, newState: newState)

        let result = formatter.formatStateChange(stateChange, format: .compact)
        // compact 모드에서는 첫 줄 전체가 출력되고 "..."가 추가됨
        #expect(result.contains("This is a very long value..."))
        #expect(!result.contains("multiple lines"))
    }

    @Test("멀티라인 값은 첫 줄만 표시된다")
    func multiLineValueTruncated() {
        let formatter = DefaultLogFormatter()

        let oldState = StateSnapshot(
            typeName: "State",
            properties: [
                StateProperty(name: "text", value: "single", typeName: "String")
            ]
        )
        let newState = StateSnapshot(
            typeName: "State",
            properties: [
                StateProperty(name: "text", value: "Line 1\nLine 2\nLine 3", typeName: "String")
            ]
        )
        let stateChange = StateChangeInfo(oldState: oldState, newState: newState)

        let result = formatter.formatStateChange(stateChange, format: .compact)
        #expect(result.contains("Line 1..."))
        #expect(!result.contains("Line 2"))
    }

    @Test("unwrapOptional이 false면 Optional 래핑을 유지한다")
    func unwrapOptionalDisabled() {
        let config = FormatterConfiguration(unwrapOptional: false)
        let formatter = DefaultLogFormatter(configuration: config)

        let oldState = StateSnapshot(
            typeName: "State",
            properties: [
                StateProperty(name: "value", value: "Optional(test)", typeName: "String?")
            ]
        )
        let newState = StateSnapshot(
            typeName: "State",
            properties: [
                StateProperty(name: "value", value: "Optional(changed)", typeName: "String?")
            ]
        )
        let stateChange = StateChangeInfo(oldState: oldState, newState: newState)

        let result = formatter.formatStateChange(stateChange, format: .compact)
        #expect(result.contains("Optional("))
    }

    @Test("기본 설정이 올바르게 적용된다")
    func defaultConfiguration() {
        let config = FormatterConfiguration.default

        #expect(config.maxProperties == 3)
        #expect(config.maxValueLength == 50)
        #expect(config.performanceDecimalPlaces == 3)
        #expect(config.stateChangeArrow == "→")
        #expect(config.indentString == "  ")
        #expect(config.unwrapOptional == true)
    }

    @Test("compact 모드에서 첫 줄이 전체 출력된다")
    func compactModeShowsFirstLine() {
        let formatter = DefaultLogFormatter()

        let oldState = StateSnapshot(
            typeName: "State",
            properties: [
                StateProperty(
                    name: "company",
                    value: "nil",
                    typeName: "Company?",
                    isNil: true
                )
            ]
        )
        let newState = StateSnapshot(
            typeName: "State",
            properties: [
                StateProperty(
                    name: "company",
                    value: "Company {\n  \"name\": \"테크 주식회사\"\n}",
                    typeName: "Company"
                )
            ]
        )
        let stateChange = StateChangeInfo(oldState: oldState, newState: newState)

        let result = formatter.formatStateChange(stateChange, format: .compact)
        // 첫 줄 전체가 출력되고 "..."가 추가됨
        #expect(result.contains("Company {"))
        #expect(result.contains("..."))
    }

    @Test("compact 모드에서 단일 줄 값은 전체 출력된다")
    func compactModeSingleLineFullOutput() {
        let formatter = DefaultLogFormatter()

        let oldState = StateSnapshot(
            typeName: "State",
            properties: [
                StateProperty(
                    name: "name",
                    value: "nil",
                    typeName: "String?",
                    isNil: true
                )
            ]
        )
        let newState = StateSnapshot(
            typeName: "State",
            properties: [
                StateProperty(
                    name: "name",
                    value: "\"This is a very long string that should be fully displayed\"",
                    typeName: "String"
                )
            ]
        )
        let stateChange = StateChangeInfo(oldState: oldState, newState: newState)

        let result = formatter.formatStateChange(stateChange, format: .compact)
        // 단일 줄은 전체 출력
        #expect(result.contains("\"This is a very long string that should be fully displayed\""))
        #expect(!result.contains("..."))
    }
}
