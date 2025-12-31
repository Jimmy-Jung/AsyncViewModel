//
//  ViewModelLoggerBuilderTests.swift
//  AsyncViewModel
//
//  Created by jimmy on 2025/12/29.
//

import Testing
@testable import AsyncViewModelCore

@Suite("ViewModelLoggerBuilder Tests")
@MainActor
struct ViewModelLoggerBuilderTests {
    @Test("build는 로거가 없으면 NoOpLogger를 반환한다")
    func testBuildWithoutLogger() {
        let logger = ViewModelLoggerBuilder().build()
        
        #expect(logger is NoOpLogger)
    }
    
    @Test("build는 추가된 로거를 반환한다")
    func testBuildWithLogger() {
        let logger = ViewModelLoggerBuilder()
            .addLogger(OSLogViewModelLogger())
            .build()
        
        #expect(logger is OSLogViewModelLogger)
    }
    
    @Test("build는 options를 로거에 적용한다")
    func testBuildAppliesOptions() {
        let logger = ViewModelLoggerBuilder()
            .addLogger(OSLogViewModelLogger())
            .withFormat(.compact)
            .withMinimumLevel(.warning)
            .build()
        
        #expect(logger.options.format == .compact)
        #expect(logger.options.minimumLevel == .warning)
    }
    
    @Test("withFormat은 포맷을 설정한다")
    func testWithFormat() {
        let logger = ViewModelLoggerBuilder()
            .addLogger(OSLogViewModelLogger())
            .withFormat(.detailed)
            .build()
        
        #expect(logger.options.format == .detailed)
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
    
    @Test("withStateDiffOnly는 state diff 옵션을 설정한다")
    func testWithStateDiffOnly() {
        let logger = ViewModelLoggerBuilder()
            .addLogger(OSLogViewModelLogger())
            .withStateDiffOnly(false)
            .build()
        
        #expect(logger.options.showStateDiffOnly == false)
    }
    
    @Test("withGroupEffects는 effect 그룹화 옵션을 설정한다")
    func testWithGroupEffects() {
        let logger = ViewModelLoggerBuilder()
            .addLogger(OSLogViewModelLogger())
            .withGroupEffects(false)
            .build()
        
        #expect(logger.options.groupEffects == false)
    }
    
    @Test("withZeroPerformance는 zero performance 옵션을 설정한다")
    func testWithZeroPerformance() {
        let logger = ViewModelLoggerBuilder()
            .addLogger(OSLogViewModelLogger())
            .withZeroPerformance(true)
            .build()
        
        #expect(logger.options.showZeroPerformance == true)
    }
    
    @Test("withMinimumLevel은 최소 로그 레벨을 설정한다")
    func testWithMinimumLevel() {
        let logger = ViewModelLoggerBuilder()
            .addLogger(OSLogViewModelLogger())
            .withMinimumLevel(.error)
            .build()
        
        #expect(logger.options.minimumLevel == .error)
    }
    
    @Test("체이닝은 올바르게 작동한다")
    func testChaining() {
        let logger = ViewModelLoggerBuilder()
            .addLogger(OSLogViewModelLogger())
            .withFormat(.compact)
            .withMinimumLevel(.info)
            .withStateDiffOnly(true)
            .withGroupEffects(true)
            .withZeroPerformance(false)
            .build()
        
        #expect(logger.options.format == .compact)
        #expect(logger.options.minimumLevel == .info)
        #expect(logger.options.showStateDiffOnly == true)
        #expect(logger.options.groupEffects == true)
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
            .withFormat(.detailed)
            .buildAsShared()
        
        #expect(LoggerConfiguration.logger.options.format == .detailed)
        #expect(logger.options.format == .detailed)
    }
    
    @Test("debug 프리셋은 올바른 설정을 제공한다")
    func testDebugPreset() {
        let logger = ViewModelLoggerBuilder.debug().build()
        
        #expect(logger is OSLogViewModelLogger)
        #expect(logger.options.format == .detailed)
        #expect(logger.options.minimumLevel == .verbose)
        #expect(logger.options.showStateDiffOnly == false)
        #expect(logger.options.groupEffects == false)
        #expect(logger.options.showZeroPerformance == true)
    }
    
    @Test("production 프리셋은 올바른 설정을 제공한다")
    func testProductionPreset() {
        let logger = ViewModelLoggerBuilder.production().build()
        
        #expect(logger is OSLogViewModelLogger)
        #expect(logger.options.format == .compact)
        #expect(logger.options.minimumLevel == .warning)
        #expect(logger.options.showStateDiffOnly == true)
        #expect(logger.options.groupEffects == true)
        #expect(logger.options.showZeroPerformance == false)
    }
    
    @Test("disabled 프리셋은 NoOpLogger를 제공한다")
    func testDisabledPreset() {
        let logger = ViewModelLoggerBuilder.disabled().build()
        
        #expect(logger is NoOpLogger)
    }
    
    @Test("마지막에 추가된 로거가 사용된다")
    func testLastLoggerIsUsed() {
        let logger = ViewModelLoggerBuilder()
            .addLogger(OSLogViewModelLogger())
            .addLogger(NoOpLogger())
            .build()
        
        #expect(logger is NoOpLogger)
    }
}
