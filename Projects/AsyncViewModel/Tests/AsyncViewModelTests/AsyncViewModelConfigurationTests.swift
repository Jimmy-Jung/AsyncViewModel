//
//  AsyncViewModelConfigurationTests.swift
//  AsyncViewModelTests
//
//  Created by jimmy on 2025/01/20.
//

@testable import AsyncViewModelCore
import Foundation
import Testing

// MARK: - Mock Interceptor for Tests

@MainActor
final class MockInterceptor: ViewModelInterceptor, @unchecked Sendable {
    var id: String { interceptorId }
    private let interceptorId: String
    var interceptedEvents: [LogEvent] = []

    init(id: String = "mock") {
        interceptorId = id
    }

    func intercept(
        _ event: LogEvent,
        viewModel _: String,
        file _: String,
        function _: String,
        line _: Int
    ) {
        interceptedEvents.append(event)
    }
}

// MARK: - Mock Logger for Tests

@MainActor
final class ConfigTestMockLogger: ViewModelLogger, @unchecked Sendable {
    var options: LoggingOptions = .init()
    let formatter: LogFormatter = DefaultLogFormatter()
    var loggedActions: [ActionInfo] = []

    func logAction(
        _ action: ActionInfo,
        viewModel _: String,
        file _: String,
        function _: String,
        line _: Int
    ) {
        loggedActions.append(action)
    }

    func logStateChange(
        _: StateChangeInfo,
        viewModel _: String,
        file _: String,
        function _: String,
        line _: Int
    ) {}

    func logEffect(
        _: EffectInfo,
        viewModel _: String,
        file _: String,
        function _: String,
        line _: Int
    ) {}

    func logEffects(
        _: [EffectInfo],
        viewModel _: String,
        file _: String,
        function _: String,
        line _: Int
    ) {}

    func logPerformance(
        _: PerformanceInfo,
        viewModel _: String,
        file _: String,
        function _: String,
        line _: Int
    ) {}

    func logError(
        _: SendableError,
        viewModel _: String,
        file _: String,
        function _: String,
        line _: Int
    ) {}
}

// MARK: - AsyncViewModelConfiguration Tests

@MainActor
@Suite("AsyncViewModelConfiguration Tests")
struct AsyncViewModelConfigurationTests {
    init() {
        // 각 테스트 시작 전 기본값으로 재설정
        AsyncViewModelConfiguration.shared.resetLogger()
        AsyncViewModelConfiguration.shared.removeAllInterceptors()
        AsyncViewModelConfiguration.shared.resetLoggingOptions()
    }

    // MARK: - Logger Tests

    @Test("기본 Logger는 OSLogViewModelLogger이다")
    func defaultLoggerIsOSLog() {
        let config = AsyncViewModelConfiguration.shared
        #expect(config.logger is OSLogViewModelLogger)
    }

    @Test("changeLogger로 Logger를 변경할 수 있다")
    func changeLoggerWorks() {
        let config = AsyncViewModelConfiguration.shared
        let mockLogger = ConfigTestMockLogger()

        config.changeLogger(mockLogger)

        #expect(config.logger is ConfigTestMockLogger)

        // 정리
        config.resetLogger()
    }

    @Test("resetLogger로 기본 Logger로 되돌릴 수 있다")
    func resetLoggerWorks() {
        let config = AsyncViewModelConfiguration.shared
        let mockLogger = ConfigTestMockLogger()

        config.changeLogger(mockLogger)
        #expect(config.logger is ConfigTestMockLogger)

        config.resetLogger()
        #expect(config.logger is OSLogViewModelLogger)
    }

    @Test("logger(for:) - .shared는 shared Logger를 반환한다")
    func loggerForSharedReturnsSharedLogger() {
        let config = AsyncViewModelConfiguration.shared
        let mockLogger = ConfigTestMockLogger()
        config.changeLogger(mockLogger)

        let logger = config.logger(for: .shared)

        #expect(logger is ConfigTestMockLogger)

        // 정리
        config.resetLogger()
    }

    @Test("logger(for:) - .custom은 커스텀 Logger를 반환한다")
    func loggerForCustomReturnsCustomLogger() {
        let config = AsyncViewModelConfiguration.shared
        let customLogger = NoOpLogger()

        let logger = config.logger(for: .custom(customLogger))

        #expect(logger is NoOpLogger)
    }

    // MARK: - Interceptor Tests

    @Test("초기 Interceptor 목록은 비어있다")
    func initialInterceptorsAreEmpty() {
        let config = AsyncViewModelConfiguration.shared
        #expect(config.interceptors.isEmpty)
    }

    @Test("addInterceptor로 Interceptor를 추가할 수 있다")
    func addInterceptorWorks() {
        let config = AsyncViewModelConfiguration.shared
        let interceptor = MockInterceptor(id: "test1")

        config.addInterceptor(interceptor)

        #expect(config.interceptors.count == 1)
        #expect(config.interceptors.first?.id == "test1")

        // 정리
        config.removeAllInterceptors()
    }

    @Test("addInterceptors로 여러 Interceptor를 추가할 수 있다")
    func addInterceptorsWorks() {
        let config = AsyncViewModelConfiguration.shared
        let interceptor1 = MockInterceptor(id: "test1")
        let interceptor2 = MockInterceptor(id: "test2")

        config.addInterceptors([interceptor1, interceptor2])

        #expect(config.interceptors.count == 2)

        // 정리
        config.removeAllInterceptors()
    }

    @Test("removeInterceptor(id:)로 특정 Interceptor를 제거할 수 있다")
    func removeInterceptorByIdWorks() {
        let config = AsyncViewModelConfiguration.shared
        let interceptor1 = MockInterceptor(id: "test1")
        let interceptor2 = MockInterceptor(id: "test2")

        config.addInterceptors([interceptor1, interceptor2])
        #expect(config.interceptors.count == 2)

        config.removeInterceptor(id: "test1")

        #expect(config.interceptors.count == 1)
        #expect(config.interceptors.first?.id == "test2")

        // 정리
        config.removeAllInterceptors()
    }

    @Test("removeAllInterceptors로 모든 Interceptor를 제거할 수 있다")
    func removeAllInterceptorsWorks() {
        let config = AsyncViewModelConfiguration.shared
        let interceptor1 = MockInterceptor(id: "test1")
        let interceptor2 = MockInterceptor(id: "test2")

        config.addInterceptors([interceptor1, interceptor2])
        #expect(config.interceptors.count == 2)

        config.removeAllInterceptors()

        #expect(config.interceptors.isEmpty)
    }

    @Test("dispatch는 모든 Interceptor에 이벤트를 전달한다")
    func dispatchSendsEventToAllInterceptors() {
        let config = AsyncViewModelConfiguration.shared
        let interceptor1 = MockInterceptor(id: "test1")
        let interceptor2 = MockInterceptor(id: "test2")

        config.addInterceptors([interceptor1, interceptor2])

        let actionInfo = ActionInfo(caseName: "testAction", associatedValues: [], fullDescription: "testAction")
        let event = LogEvent.action(actionInfo)
        config.dispatch(event, viewModel: "TestVM", file: #file, function: #function, line: #line)

        #expect(interceptor1.interceptedEvents.count == 1)
        #expect(interceptor2.interceptedEvents.count == 1)

        // 정리
        config.removeAllInterceptors()
    }

    // MARK: - Global Logging Options Tests

    @Test("기본 loggingOptions가 올바르게 설정된다")
    func defaultLoggingOptionsAreCorrect() {
        let config = AsyncViewModelConfiguration.shared

        #expect(config.loggingOptions.actionFormat == .standard)
        #expect(config.loggingOptions.stateFormat == .standard)
        #expect(config.loggingOptions.effectFormat == .standard)
    }

    @Test("configure(actionFormat:)로 전역 Action 포맷을 변경할 수 있다")
    func configureActionFormatWorks() {
        let config = AsyncViewModelConfiguration.shared

        config.configure(actionFormat: .detailed)

        #expect(config.loggingOptions.actionFormat == .detailed)

        // 정리
        config.resetLoggingOptions()
    }

    @Test("configure(stateFormat:)로 전역 State 포맷을 변경할 수 있다")
    func configureStateFormatWorks() {
        let config = AsyncViewModelConfiguration.shared

        config.configure(stateFormat: .compact)

        #expect(config.loggingOptions.stateFormat == .compact)

        // 정리
        config.resetLoggingOptions()
    }

    @Test("configure(effectFormat:)로 전역 Effect 포맷을 변경할 수 있다")
    func configureEffectFormatWorks() {
        let config = AsyncViewModelConfiguration.shared

        config.configure(effectFormat: .detailed)

        #expect(config.loggingOptions.effectFormat == .detailed)

        // 정리
        config.resetLoggingOptions()
    }

    @Test("configure(options:)로 전역 옵션 전체를 변경할 수 있다")
    func configureOptionsWorks() {
        let config = AsyncViewModelConfiguration.shared
        let newOptions = LoggingOptions(
            actionFormat: .compact,
            stateFormat: .detailed,
            effectFormat: .compact
        )

        config.configure(options: newOptions)

        #expect(config.loggingOptions.actionFormat == .compact)
        #expect(config.loggingOptions.stateFormat == .detailed)
        #expect(config.loggingOptions.effectFormat == .compact)

        // 정리
        config.resetLoggingOptions()
    }

    @Test("resetLoggingOptions로 기본값으로 되돌릴 수 있다")
    func resetLoggingOptionsWorks() {
        let config = AsyncViewModelConfiguration.shared

        config.configure(actionFormat: .compact)

        config.resetLoggingOptions()

        #expect(config.loggingOptions.actionFormat == .standard)
        #expect(config.loggingOptions.stateFormat == .standard)
        #expect(config.loggingOptions.effectFormat == .standard)
    }
}

// MARK: - ViewModelLoggingConfig Global vs Custom Options Tests

@MainActor
@Suite("ViewModelLoggingConfig Global Options Tests")
struct ViewModelLoggingConfigGlobalOptionsTests {
    init() {
        AsyncViewModelConfiguration.shared.resetLoggingOptions()
    }

    @Test("customOptions가 nil이면 전역 설정을 사용한다")
    func usesGlobalOptionsWhenCustomIsNil() {
        let config = AsyncViewModelConfiguration.shared
        config.configure(actionFormat: .detailed)

        let loggingConfig = ViewModelLoggingConfig(
            mode: .enabled,
            loggerMode: .shared,
            customOptions: nil
        )

        #expect(loggingConfig.options.actionFormat == .detailed)
        #expect(loggingConfig.hasCustomOptions == false)

        // 정리
        config.resetLoggingOptions()
    }

    @Test("customOptions가 있으면 커스텀 설정을 사용한다")
    func usesCustomOptionsWhenProvided() {
        let config = AsyncViewModelConfiguration.shared
        config.configure(actionFormat: .detailed) // 전역은 detailed

        let customOptions = LoggingOptions(actionFormat: .compact) // 커스텀은 compact
        let loggingConfig = ViewModelLoggingConfig(
            mode: .enabled,
            loggerMode: .shared,
            customOptions: customOptions
        )

        #expect(loggingConfig.options.actionFormat == .compact)
        #expect(loggingConfig.hasCustomOptions == true)

        // 정리
        config.resetLoggingOptions()
    }

    @Test("빌더 메서드로 커스텀 옵션을 설정할 수 있다")
    func builderMethodsCreateCustomOptions() {
        let loggingConfig = ViewModelLoggingConfig.default
            .withActionFormat(.compact)

        #expect(loggingConfig.hasCustomOptions == true)
        #expect(loggingConfig.customOptions?.actionFormat == .compact)
    }

    @Test("usingGlobalOptions로 전역 설정 사용으로 되돌릴 수 있다")
    func usingGlobalOptionsRemovesCustom() {
        let loggingConfig = ViewModelLoggingConfig.default
            .withFormat(.compact)
            .usingGlobalOptions()

        #expect(loggingConfig.hasCustomOptions == false)
        #expect(loggingConfig.customOptions == nil)
    }

    @Test("dispatch_duplicate")
    func dispatchSendsEventToAllInterceptorsDuplicate() {
        // 기존 테스트가 불완전하게 남아있어서 빈 테스트로 대체
        let config = AsyncViewModelConfiguration.shared
        let interceptor1 = MockInterceptor(id: "test1")
        let interceptor2 = MockInterceptor(id: "test2")

        config.addInterceptors([interceptor1, interceptor2])

        let actionInfo = ActionInfo(caseName: "testAction", associatedValues: [], fullDescription: "testAction")
        let event = LogEvent.action(actionInfo)
        config.dispatch(event, viewModel: "TestVM", file: #file, function: #function, line: #line)

        #expect(interceptor1.interceptedEvents.count == 1)
        #expect(interceptor2.interceptedEvents.count == 1)

        // 정리
        config.removeAllInterceptors()
    }
}

// MARK: - LoggerMode Tests

@MainActor
@Suite("LoggerMode Tests")
struct LoggerModeTests {
    @Test("LoggerMode.shared 케이스가 존재한다")
    func sharedCaseExists() {
        let mode: LoggerMode = .shared

        switch mode {
        case .shared:
            #expect(true)
        case .custom:
            #expect(Bool(false), "Expected .shared but got .custom")
        }
    }

    @Test("LoggerMode.custom 케이스가 존재한다")
    func customCaseExists() {
        let customLogger = NoOpLogger()
        let mode: LoggerMode = .custom(customLogger)

        switch mode {
        case .shared:
            #expect(Bool(false), "Expected .custom but got .shared")
        case let .custom(logger):
            #expect(logger is NoOpLogger)
        }
    }
}

// MARK: - LogEvent Tests

@MainActor
@Suite("LogEvent Tests")
struct LogEventTests {
    @Test("action 이벤트를 생성할 수 있다")
    func actionEventWorks() {
        let actionInfo = ActionInfo(caseName: "testAction", associatedValues: [], fullDescription: "testAction")
        let event = LogEvent.action(actionInfo)

        if case let .action(action) = event {
            #expect(action.caseName == "testAction")
        } else {
            #expect(Bool(false), "Expected .action event")
        }
    }

    @Test("effect 이벤트를 생성할 수 있다")
    func effectEventWorks() {
        let effectInfo = EffectInfo(effectType: .run, id: "testID", relatedAction: nil, description: "testEffect")
        let event = LogEvent.effect(effectInfo)

        if case let .effect(effect) = event {
            #expect(effect.effectType == .run)
            #expect(effect.id == "testID")
        } else {
            #expect(Bool(false), "Expected .effect event")
        }
    }

    @Test("effects 이벤트를 생성할 수 있다")
    func effectsEventWorks() {
        let effect1 = EffectInfo(effectType: .action, id: nil, relatedAction: nil, description: "effect1")
        let effect2 = EffectInfo(effectType: .run, id: "id2", relatedAction: nil, description: "effect2")
        let event = LogEvent.effects([effect1, effect2])

        if case let .effects(effects) = event {
            #expect(effects.count == 2)
            #expect(effects[0].effectType == .action)
            #expect(effects[1].effectType == .run)
        } else {
            #expect(Bool(false), "Expected .effects event")
        }
    }

    @Test("performance 이벤트를 생성할 수 있다")
    func performanceEventWorks() {
        let perfInfo = PerformanceInfo(
            operation: "testOp",
            operationType: .custom,
            duration: 0.5,
            threshold: 0.1,
            exceededThreshold: true
        )
        let event = LogEvent.performance(perfInfo)

        if case let .performance(performance) = event {
            #expect(performance.operation == "testOp")
            #expect(performance.duration == 0.5)
        } else {
            #expect(Bool(false), "Expected .performance event")
        }
    }

    @Test("error 이벤트를 생성할 수 있다")
    func errorEventWorks() {
        let error = SendableError(message: "test error", domain: "test", typeName: "TestError")
        let event = LogEvent.error(error)

        if case let .error(err) = event {
            #expect(err.domain == "test")
        } else {
            #expect(Bool(false), "Expected .error event")
        }
    }
}

// MARK: - ViewModelLoggingConfig Builder Tests

@MainActor
@Suite("ViewModelLoggingConfig Builder Tests")
struct ViewModelLoggingConfigBuilderTests {
    @Test("기본 설정이 올바르게 생성된다")
    func defaultConfigWorks() {
        let config = ViewModelLoggingConfig.default

        #expect(config.isEnabled)
        // .enabled는 이제 associated value를 가지므로 isEnabled로 확인
    }

    @Test("withActionFormat 빌더 메서드가 작동한다")
    func withActionFormatWorks() {
        let config = ViewModelLoggingConfig.default
            .withActionFormat(.detailed)

        #expect(config.options.actionFormat == .detailed)
    }

    @Test("withStateFormat 빌더 메서드가 작동한다")
    func withStateFormatWorks() {
        let config = ViewModelLoggingConfig.default
            .withStateFormat(.compact)

        #expect(config.options.stateFormat == .compact)
    }

    @Test("withEffectFormat 빌더 메서드가 작동한다")
    func withEffectFormatWorks() {
        let config = ViewModelLoggingConfig.default
            .withEffectFormat(.detailed)

        #expect(config.options.effectFormat == .detailed)
    }

    @Test("Logger가 별도 파라미터로 작동한다")
    func loggerAsSeparateParameterWorks() {
        let customLogger = NoOpLogger()
        let config = ViewModelLoggingConfig(mode: .enabled, loggerMode: .custom(customLogger))

        if case let .custom(logger) = config.loggerMode {
            #expect(logger is NoOpLogger)
        } else {
            #expect(Bool(false), "Expected .custom logger mode")
        }
    }

    @Test("체이닝이 올바르게 작동한다")
    func chainingWorks() {
        let config = ViewModelLoggingConfig.default
            .withActionFormat(.compact)
            .withStateFormat(.detailed)
            .withEffectFormat(.compact)

        #expect(config.options.actionFormat == .compact)
        #expect(config.options.stateFormat == .detailed)
        #expect(config.options.effectFormat == .compact)
    }
}

// MARK: - Macro Parameter Options Tests

@MainActor
@Suite("Macro Parameter Options Tests")
struct MacroParameterOptionsTests {
    init() {
        AsyncViewModelConfiguration.shared.resetLoggingOptions()
    }

    @Test("매크로에서 커스텀 옵션 설정 시 customOptions가 생성된다")
    func macroCustomOptionsCreatesCustomOptions() {
        // 매크로가 생성하는 코드를 시뮬레이션
        let customOptions = LoggingOptions(actionFormat: .compact)
        let config = ViewModelLoggingConfig(
            mode: .enabled,
            loggerMode: .shared,
            customOptions: customOptions
        )

        #expect(config.hasCustomOptions == true)
        #expect(config.customOptions?.actionFormat == .compact)
    }

    @Test("매크로에서 옵션 미설정 시 전역 설정이 사용된다")
    func macroNoOptionsUsesGlobal() {
        AsyncViewModelConfiguration.shared.configure(actionFormat: .detailed)

        // 매크로가 생성하는 코드 (옵션 미설정)
        let config = ViewModelLoggingConfig(
            mode: .enabled,
            loggerMode: .shared,
            customOptions: nil
        )

        #expect(config.hasCustomOptions == false)
        #expect(config.options.actionFormat == .detailed) // 전역 설정

        AsyncViewModelConfiguration.shared.resetLoggingOptions()
    }

    @Test("매크로 actionFormat 파라미터로 포맷을 설정할 수 있다")
    func macroActionFormatParameterWorks() {
        // @AsyncViewModel(format: .action(.compact)) 가 생성하는 코드
        let customOptions = LoggingOptions(actionFormat: .compact)
        let config = ViewModelLoggingConfig(
            mode: .enabled,
            loggerMode: .shared,
            customOptions: customOptions
        )

        #expect(config.options.actionFormat == LogFormat.compact)
    }

    @Test("매크로에서 여러 옵션을 조합할 수 있다")
    func macroCombinedOptionsWork() {
        // @AsyncViewModel(format: .perCategory(action: .compact, effect: .detailed))
        let customOptions = LoggingOptions(
            actionFormat: .compact,
            effectFormat: .detailed
        )
        let config = ViewModelLoggingConfig(
            mode: .enabled,
            loggerMode: .shared,
            customOptions: customOptions
        )

        #expect(config.options.actionFormat == LogFormat.compact)
        #expect(config.options.effectFormat == LogFormat.detailed)
    }
}

// MARK: - LoggingMode Tests

@MainActor
@Suite("LoggingMode Tests")
struct LoggingModeNewTests {
    @Test("enabled 모드는 모든 카테고리를 활성화한다")
    func enabledEnablesAllCategories() {
        let mode: LoggingMode = .enabled

        #expect(mode.isEnabled)
        #expect(mode.isCategoryEnabled(.action))
        #expect(mode.isCategoryEnabled(.stateChange))
        #expect(mode.isCategoryEnabled(.effect))
        #expect(mode.isCategoryEnabled(.performance))
        #expect(mode.isCategoryEnabled(.error))
    }

    @Test("disabled 모드는 모든 카테고리를 비활성화한다")
    func disabledDisablesAllCategories() {
        let mode: LoggingMode = .disabled

        #expect(!mode.isEnabled)
        #expect(!mode.isCategoryEnabled(.action))
        #expect(!mode.isCategoryEnabled(.stateChange))
        #expect(!mode.isCategoryEnabled(.error))
    }

    @Test("minimal 모드는 에러만 활성화한다")
    func minimalOnlyEnablesError() {
        let mode: LoggingMode = .minimal

        #expect(mode.isEnabled)
        #expect(!mode.isCategoryEnabled(.action))
        #expect(!mode.isCategoryEnabled(.stateChange))
        #expect(mode.isCategoryEnabled(.error))
    }

    @Test("only 모드는 지정한 카테고리만 활성화한다")
    func onlyEnablesSpecificCategories() {
        let mode: LoggingMode = .only(.action, .error)

        #expect(mode.isEnabled)
        #expect(mode.isCategoryEnabled(.action))
        #expect(mode.isCategoryEnabled(.error))
        #expect(!mode.isCategoryEnabled(.stateChange))
        #expect(!mode.isCategoryEnabled(.effect))
    }

    @Test("excluding 모드는 지정한 카테고리만 비활성화한다")
    func excludingDisablesSpecificCategories() {
        let mode: LoggingMode = .excluding(.stateChange)

        #expect(mode.isEnabled)
        #expect(mode.isCategoryEnabled(.action))
        #expect(mode.isCategoryEnabled(.error))
        #expect(!mode.isCategoryEnabled(.stateChange))
        #expect(mode.isCategoryEnabled(.effect))
    }

    @Test("noStateChanges 프리셋이 stateChange를 제외한다")
    func noStateChangesPreset() {
        let mode: LoggingMode = .noStateChanges

        #expect(mode.isEnabled)
        #expect(mode.isCategoryEnabled(.action))
        #expect(!mode.isCategoryEnabled(.stateChange))
        #expect(mode.isCategoryEnabled(.error))
    }

    @Test("performanceOnly 프리셋이 performance와 error만 활성화한다")
    func performanceOnlyPreset() {
        let mode: LoggingMode = .performanceOnly

        #expect(mode.isEnabled)
        #expect(!mode.isCategoryEnabled(.action))
        #expect(!mode.isCategoryEnabled(.stateChange))
        #expect(mode.isCategoryEnabled(.performance))
        #expect(mode.isCategoryEnabled(.error))
    }
}

// MARK: - LogFormatConfig Tests

@MainActor
@Suite("LogFormatConfig Tests")
struct LogFormatConfigTests {
    @Test("compact은 모든 카테고리에 compact 적용")
    func compactAppliesCompactToAll() {
        let formatConfig: LogFormatConfig = .compact
        let options = formatConfig.toLoggingOptions()

        #expect(options.actionFormat == .compact)
        #expect(options.stateFormat == .compact)
        #expect(options.effectFormat == .compact)
    }

    @Test("standard는 모든 카테고리에 standard 적용")
    func standardAppliesStandardToAll() {
        let formatConfig: LogFormatConfig = .standard
        let options = formatConfig.toLoggingOptions()

        #expect(options.actionFormat == .standard)
        #expect(options.stateFormat == .standard)
        #expect(options.effectFormat == .standard)
    }

    @Test("detailed은 모든 카테고리에 detailed 적용")
    func detailedAppliesDetailedToAll() {
        let formatConfig: LogFormatConfig = .detailed
        let options = formatConfig.toLoggingOptions()

        #expect(options.actionFormat == .detailed)
        #expect(options.stateFormat == .detailed)
        #expect(options.effectFormat == .detailed)
    }

    @Test("perCategory는 개별 포맷을 적용한다")
    func perCategoryAppliesIndividualFormats() {
        let formatConfig: LogFormatConfig = .perCategory(
            action: .compact,
            state: .detailed,
            effect: .standard
        )
        let options = formatConfig.toLoggingOptions()

        #expect(options.actionFormat == .compact)
        #expect(options.stateFormat == .detailed)
        #expect(options.effectFormat == .standard)
    }

    @Test("action 팩토리 메서드가 action만 변경한다")
    func actionFactoryChangesOnlyAction() {
        let formatConfig: LogFormatConfig = .action(.compact)
        let options = formatConfig.toLoggingOptions()

        #expect(options.actionFormat == .compact)
        #expect(options.stateFormat == .standard)
        #expect(options.effectFormat == .standard)
    }

    @Test("state 팩토리 메서드가 state만 변경한다")
    func stateFactoryChangesOnlyState() {
        let formatConfig: LogFormatConfig = .state(.detailed)
        let options = formatConfig.toLoggingOptions()

        #expect(options.actionFormat == .standard)
        #expect(options.stateFormat == .detailed)
        #expect(options.effectFormat == .standard)
    }

    @Test("effect 팩토리 메서드가 effect만 변경한다")
    func effectFactoryChangesOnlyEffect() {
        let formatConfig: LogFormatConfig = .effect(.compact)
        let options = formatConfig.toLoggingOptions()

        #expect(options.actionFormat == .standard)
        #expect(options.stateFormat == .standard)
        #expect(options.effectFormat == .compact)
    }
}
