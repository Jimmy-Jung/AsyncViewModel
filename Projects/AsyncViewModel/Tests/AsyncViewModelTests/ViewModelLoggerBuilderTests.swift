//
//  ViewModelLoggerBuilderTests.swift
//  AsyncViewModel
//
//  Created by jimmy on 2025/12/19.
//

@testable import AsyncViewModelCore
import Testing

@Suite("ViewModelLoggerBuilder Tests")
@MainActor
struct ViewModelLoggerBuilderTests {
    @Test("build는 로거가 없으면 NoOpLogger를 반환한다")
    func buildWithoutLogger() {
        let logger = ViewModelLoggerBuilder().build()

        #expect(logger is NoOpLogger)
    }

    @Test("build는 추가된 로거를 반환한다")
    func buildWithLogger() {
        let logger = ViewModelLoggerBuilder()
            .addLogger(OSLogViewModelLogger())
            .build()

        #expect(logger is OSLogViewModelLogger)
    }

    @Test("build는 options를 로거에 적용한다")
    func buildAppliesOptions() {
        let logger = ViewModelLoggerBuilder()
            .addLogger(OSLogViewModelLogger())
            .withActionFormat(.compact)
            .build()

        #expect(logger.options.actionFormat == .compact)
    }

    @Test("withActionFormat은 Action 포맷을 설정한다")
    func testWithActionFormat() {
        let logger = ViewModelLoggerBuilder()
            .addLogger(OSLogViewModelLogger())
            .withActionFormat(.detailed)
            .build()

        #expect(logger.options.actionFormat == .detailed)
    }

    @Test("withPerformanceThreshold는 임계값을 설정한다")
    func testWithPerformanceThreshold() {
        let threshold = PerformanceThreshold(type: .actionProcessing, customThreshold: 0.1)
        let logger = ViewModelLoggerBuilder()
            .addLogger(OSLogViewModelLogger())
            .withPerformanceThreshold(threshold)
            .build()

        #expect(logger.options.performanceThreshold?.threshold == 0.1)
    }

    @Test("withZeroPerformance는 zero performance 옵션을 설정한다")
    func testWithZeroPerformance() {
        let logger = ViewModelLoggerBuilder()
            .addLogger(OSLogViewModelLogger())
            .withZeroPerformance(true)
            .build()

        #expect(logger.options.showZeroPerformance == true)
    }

    @Test("체이닝은 올바르게 작동한다")
    func chaining() {
        let logger = ViewModelLoggerBuilder()
            .addLogger(OSLogViewModelLogger())
            .withActionFormat(.compact)
            .withEffectFormat(.detailed)
            .withZeroPerformance(false)
            .build()

        #expect(logger.options.actionFormat == .compact)
        #expect(logger.options.effectFormat == .detailed)
        #expect(logger.options.showZeroPerformance == false)
    }

    @Test("buildAsShared는 전역 로거를 설정한다")
    func testBuildAsShared() {
        let originalLogger = LoggerConfiguration.logger
        defer {
            LoggerConfiguration.setLogger(originalLogger)
        }

        let logger = ViewModelLoggerBuilder()
            .addLogger(OSLogViewModelLogger())
            .withActionFormat(.detailed)
            .buildAsShared()

        #expect(LoggerConfiguration.logger.options.actionFormat == .detailed)
        #expect(logger.options.actionFormat == .detailed)
    }

    @Test("debug 프리셋은 올바른 설정을 제공한다")
    func debugPreset() {
        let logger = ViewModelLoggerBuilder.debug().build()

        #expect(logger is OSLogViewModelLogger)
        #expect(logger.options.actionFormat == .detailed)
        #expect(logger.options.effectFormat == .detailed)
        #expect(logger.options.showZeroPerformance == true)
    }

    @Test("production 프리셋은 올바른 설정을 제공한다")
    func productionPreset() {
        let logger = ViewModelLoggerBuilder.production().build()

        #expect(logger is OSLogViewModelLogger)
        #expect(logger.options.actionFormat == .compact)
        #expect(logger.options.effectFormat == .compact)
        #expect(logger.options.showZeroPerformance == false)
    }

    @Test("disabled 프리셋은 NoOpLogger를 제공한다")
    func disabledPreset() {
        let logger = ViewModelLoggerBuilder.disabled().build()

        #expect(logger is NoOpLogger)
    }

    @Test("마지막에 추가된 로거가 사용된다")
    func lastLoggerIsUsed() {
        let logger = ViewModelLoggerBuilder()
            .addLogger(OSLogViewModelLogger())
            .addLogger(NoOpLogger())
            .build()

        #expect(logger is NoOpLogger)
    }
}
