//
//  AsyncViewModelProtocol+Logging.swift
//  AsyncViewModel
//
//  Created by jimmy on 2025/01/21.
//

import Foundation

// MARK: - Logging

extension AsyncViewModelProtocol {
    // MARK: - Internal Logging Helpers

    func logStateChangeIfNeeded(from oldState: State, to newState: State) {
        guard oldState != newState else { return }

        // 개별 설정 체크
        guard loggingConfig.isEnabled else {
            stateChangeObserver?(oldState, newState)
            return
        }

        // loggingConfig.options는 커스텀 설정이 있으면 커스텀, 없으면 전역 설정 반환
        let shouldLogStateChange = loggingConfig.isCategoryEnabled(.stateChange)

        if shouldLogStateChange {
            logStateChange(from: oldState, to: newState)
        }

        stateChangeObserver?(oldState, newState)
    }

    func logEffectsIfNeeded(_ effects: [AsyncEffect<Action, CancelID>]) {
        guard !effects.isEmpty else { return }

        // 개별 설정 체크
        guard loggingConfig.isEnabled,
              loggingConfig.isCategoryEnabled(.effect)
        else {
            return
        }

        // loggingConfig.options는 커스텀 설정이 있으면 커스텀, 없으면 전역 설정 반환
        let effectiveOptions = loggingConfig.options

        // effectFormat에 따라 자동으로 그룹화 여부 결정
        // compact/standard: 그룹화하여 요약 표시
        // detailed: 개별적으로 상세 표시
        switch effectiveOptions.effectFormat {
        case .compact, .standard:
            logEffects(effects)
        case .detailed:
            for effect in effects {
                logEffect(effect)
            }
        }
    }

    func logEffects(_ effects: [AsyncEffect<Action, CancelID>]) {
        let effectInfos = effects.map { convertToEffectInfo($0) }
        let viewModelName = String(describing: Self.self)
        let config = AsyncViewModelConfiguration.shared
        let effectiveOptions = loggingConfig.options
        var logger = config.logger(for: loggingConfig.loggerMode)
        logger.options = effectiveOptions

        logger.logEffects(
            effectInfos,
            viewModel: viewModelName,
            file: #file,
            function: #function,
            line: #line
        )

        // Interceptor에 이벤트 전달
        let event = LogEvent.effects(effectInfos)
        config.dispatch(event, viewModel: viewModelName, file: #file, function: #function, line: #line)

        for effect in effects {
            effectObserver?(effect)
        }
    }

    // MARK: - Public Logging Methods

    public func logAction(
        _ action: Action,
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) {
        // 개별 설정 체크
        let effectiveOptions = loggingConfig.options
        guard loggingConfig.isEnabled,
              loggingConfig.isCategoryEnabled(.action)
        else {
            return
        }

        let config = AsyncViewModelConfiguration.shared
        var logger = config.logger(for: loggingConfig.loggerMode)
        logger.options = effectiveOptions
        let viewModelName = String(describing: Self.self)

        // Action을 ActionInfo로 변환
        let actionInfo = convertToActionInfo(action)

        logger.logAction(
            actionInfo,
            viewModel: viewModelName,
            file: file,
            function: function,
            line: line
        )

        // Interceptor에 이벤트 전달
        let event = LogEvent.action(actionInfo)
        config.dispatch(event, viewModel: viewModelName, file: file, function: function, line: line)
    }

    public func logStateChange(
        from oldState: State,
        to newState: State,
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) {
        let config = AsyncViewModelConfiguration.shared
        let effectiveOptions = loggingConfig.options
        var logger = config.logger(for: loggingConfig.loggerMode)
        logger.options = effectiveOptions
        let viewModelName = String(describing: Self.self)

        // StateSnapshot 생성 (원본 데이터 전체 보관, 포맷터에서 깊이 제한 적용)
        let oldSnapshot = StateSnapshot(from: oldState)
        let newSnapshot = StateSnapshot(from: newState)
        let stateChange = StateChangeInfo(oldState: oldSnapshot, newState: newSnapshot)

        logger.logStateChange(
            stateChange,
            viewModel: viewModelName,
            file: file,
            function: function,
            line: line
        )

        // Interceptor에 이벤트 전달
        let event = LogEvent.stateChange(stateChange)
        config.dispatch(event, viewModel: viewModelName, file: file, function: function, line: line)

        stateChangeObserver?(oldState, newState)
    }

    public func logEffect(
        _ effect: AsyncEffect<Action, CancelID>,
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) {
        // 개별 설정 체크
        guard loggingConfig.isEnabled,
              loggingConfig.isCategoryEnabled(.effect)
        else {
            effectObserver?(effect)
            return
        }

        let config = AsyncViewModelConfiguration.shared
        let effectiveOptions = loggingConfig.options
        var logger = config.logger(for: loggingConfig.loggerMode)
        logger.options = effectiveOptions
        let viewModelName = String(describing: Self.self)

        // Effect를 EffectInfo로 변환
        let effectInfo = convertToEffectInfo(effect)

        logger.logEffect(
            effectInfo,
            viewModel: viewModelName,
            file: file,
            function: function,
            line: line
        )

        // Interceptor에 이벤트 전달
        let event = LogEvent.effect(effectInfo)
        config.dispatch(event, viewModel: viewModelName, file: file, function: function, line: line)

        effectObserver?(effect)
    }

    public func logPerformance(
        _ operation: String,
        duration: TimeInterval,
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) {
        // 개별 설정 체크
        guard loggingConfig.isEnabled,
              loggingConfig.isCategoryEnabled(.performance)
        else {
            performanceObserver?(operation, duration)
            return
        }

        let config = AsyncViewModelConfiguration.shared
        let effectiveOptions = loggingConfig.options
        var logger = config.logger(for: loggingConfig.loggerMode)
        logger.options = effectiveOptions
        let viewModelName = String(describing: Self.self)

        // PerformanceInfo 생성
        let operationType = PerformanceThreshold.infer(from: operation)
        let threshold: TimeInterval
        if let performanceThreshold = effectiveOptions.performanceThreshold {
            threshold = performanceThreshold.threshold
        } else {
            threshold = operationType.recommendedThreshold
        }
        let exceededThreshold = duration >= threshold

        let performanceInfo = PerformanceInfo(
            operation: operation,
            operationType: operationType,
            duration: duration,
            threshold: threshold,
            exceededThreshold: exceededThreshold
        )

        logger.logPerformance(
            performanceInfo,
            viewModel: viewModelName,
            file: file,
            function: function,
            line: line
        )

        // Interceptor에 이벤트 전달
        let event = LogEvent.performance(performanceInfo)
        config.dispatch(event, viewModel: viewModelName, file: file, function: function, line: line)

        performanceObserver?(operation, duration)
    }

    public func logError(
        _ error: SendableError,
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) {
        // 개별 설정 체크 (에러는 항상 로깅 가능하도록 허용)
        guard loggingConfig.isEnabled,
              loggingConfig.isCategoryEnabled(.error)
        else {
            return
        }

        let config = AsyncViewModelConfiguration.shared
        let effectiveOptions = loggingConfig.options
        var logger = config.logger(for: loggingConfig.loggerMode)
        logger.options = effectiveOptions
        let viewModelName = String(describing: Self.self)

        logger.logError(
            error,
            viewModel: viewModelName,
            file: file,
            function: function,
            line: line
        )

        // Interceptor에 이벤트 전달
        let event = LogEvent.error(error)
        config.dispatch(event, viewModel: viewModelName, file: file, function: function, line: line)
    }

    // MARK: - Converters

    func convertToActionInfo(_ action: Action) -> ActionInfo {
        ActionInfoConverter().convert(action)
    }

    func convertToEffectInfo(_ effect: AsyncEffect<Action, CancelID>) -> EffectInfo {
        EffectInfoConverter<Action, CancelID>().convert(effect)
    }
}
