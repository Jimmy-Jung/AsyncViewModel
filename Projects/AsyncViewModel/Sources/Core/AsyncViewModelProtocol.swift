//
//  AsyncViewModelProtocol.swift
//  AsyncViewModel
//
//  Created by 정준영 on 2025/8/3.
//

import Foundation
import os.log

// MARK: - AsyncViewModelProtocol

/// 개선된 비동기 작업을 처리하는 ViewModel 프로토콜
///
/// 단방향 데이터 흐름을 위한 비동기 방식의 ViewModel입니다.
/// Input -> Action -> Reduce -> State 업데이트 + Effect 흐름으로 데이터가 처리됩니다.
@MainActor
public protocol AsyncViewModelProtocol: ObservableObject {
    associatedtype Input: Sendable
    associatedtype Action: Equatable & Sendable
    associatedtype State: Equatable & Sendable
    associatedtype CancelID: Hashable & Sendable

    var state: State { get set }
    var tasks: [CancelID: Task<Void, Never>] { get set }
    var effectQueue: [AsyncEffect<Action, CancelID>] { get set }
    var isProcessingEffects: Bool { get set }
    var timer: any AsyncTimer { get set }
    var actionObserver: ((Action) -> Void)? { get set }
    var stateChangeObserver: ((State, State) -> Void)? { get set }
    var effectObserver: ((AsyncEffect<Action, CancelID>) -> Void)? { get set }
    var performanceObserver: ((String, TimeInterval) -> Void)? { get set }

    /// ViewModel별 로깅 설정 (매크로가 자동 생성)
    var loggingConfig: ViewModelLoggingConfig { get }

    func send(_ input: Input)
    func transform(_ input: Input) -> [Action]
    func reduce(state: inout State, action: Action) -> [AsyncEffect<Action, CancelID>]
    func handleError(_ error: SendableError)
}

// MARK: - Default Implementation

extension AsyncViewModelProtocol {
    /// 기본 로깅 설정 (매크로가 생성하지 않은 경우)
    public var loggingConfig: ViewModelLoggingConfig {
        .default
    }

    public func send(_ input: Input) {
        let actions = transform(input)
        for action in actions {
            perform(action)
        }
    }

    /// Action을 직접 실행합니다.
    ///
    /// ⚠️ **주의**: 이 메서드는 ViewModel 내부에서만 사용해야 합니다.
    ///
    /// 외부에서 ViewModel과 상호작용할 때는 반드시 `send(_:)` 메서드를 사용하세요.
    /// `perform`은 다음과 같은 내부 용도로만 사용됩니다:
    /// - `handleError`에서 에러 처리 Action 실행
    /// - `reduce`에서 반환된 Effect의 Action 처리
    /// - 테스트 코드에서 직접 Action 주입
    ///
    /// **올바른 사용:**
    /// ```swift
    /// // ✅ 외부에서
    /// viewModel.send(.buttonTapped)
    ///
    /// // ✅ ViewModel 내부에서
    /// func handleError(_ error: SendableError) {
    ///     perform(.errorOccurred(error))
    /// }
    /// ```
    ///
    /// **잘못된 사용:**
    /// ```swift
    /// // ❌ 외부에서 직접 Action 호출
    /// viewModel.perform(.dataLoaded(data))
    /// ```
    ///
    /// - Parameter action: 실행할 Action
    public func perform(_ action: Action) {
        let startTime = CFAbsoluteTimeGetCurrent()

        logAction(action)
        actionObserver?(action)

        let oldState = state
        let effects = reduce(state: &state, action: action)

        logStateChangeIfNeeded(from: oldState, to: state)
        effectQueue.append(contentsOf: effects)
        logEffectsIfNeeded(effects)

        let duration = CFAbsoluteTimeGetCurrent() - startTime
        logPerformance("Action processing", duration: duration)

        Task {
            await processNextEffect()
        }
    }

    /// 처리 순서: Effect는 FIFO(선입선출) 순서로 처리됩니다.
    /// - Effect가 새로운 Effect를 생성하면 큐의 끝에 추가됩니다.
    /// - 이는 너비 우선(breadth-first) 탐색 방식입니다.
    ///
    /// 예시:
    /// ```swift
    /// // Action A가 [B, C]를 생성하고
    /// // Action B가 [D]를 생성하면
    /// // 실행 순서: A → B → C → D
    /// ```
    private func processNextEffect() async {
        guard !isProcessingEffects else { return }
        isProcessingEffects = true

        while !effectQueue.isEmpty {
            let effect = effectQueue.removeFirst()
            await handleEffect(effect)
        }

        isProcessingEffects = false
    }

    private func handleEffect(_ effect: AsyncEffect<Action, CancelID>) async {
        let startTime = CFAbsoluteTimeGetCurrent()

        switch effect {
        case .none:
            break
        case let .action(action):
            processActionEffect(action)
        case let .run(id, operation):
            await processRunEffect(id: id, operation: operation)
        case let .cancel(id):
            processCancelEffect(id: id)
        case let .concurrent(effects):
            await processConcurrentEffect(effects)
        case let .sleepThen(id, duration, action):
            await processSleepThenEffect(id: id, duration: duration, action: action)
        case let .timer(id, interval, action):
            processTimerEffect(id: id, interval: interval, action: action)
        }

        let duration = CFAbsoluteTimeGetCurrent() - startTime
        logPerformance("Effect handling", duration: duration)
    }

    // MARK: - Effect Processing Helpers

    /// 재귀적으로 perform을 호출하지 않고, 현재 처리 루프에 통합하여 평탄화합니다.
    private func processActionEffect(_ action: Action) {
        logAction(action)
        actionObserver?(action)

        let oldState = state
        let newEffects = reduce(state: &state, action: action)

        logStateChangeIfNeeded(from: oldState, to: state)
        effectQueue.append(contentsOf: newEffects)
        logEffectsIfNeeded(newEffects)
    }

    private func processRunEffect(
        id: CancelID?,
        operation: AsyncOperation<Action>
    ) async {
        cancelExistingTask(id: id)

        let task = Task {
            let result = await measureOperation(operation)
            await MainActor.run { [weak self] in
                self?.handleOperationResult(result, shouldTriggerProcessing: true)
            }
        }

        registerTask(task, id: id)
    }

    private func processCancelEffect(id: CancelID) {
        logEffect(.cancel(id: id))
        tasks[id]?.cancel()
        tasks[id] = nil
    }

    /// 처리 전략:
    /// 1. .run 효과들의 operation은 병렬로 실행 (백그라운드 스레드)
    /// 2. 모든 operation 결과를 수집한 후 MainActor에서 순차 처리
    /// 3. 비-.run 효과들(.action, .cancel 등)은 순차 처리
    private func processConcurrentEffect(
        _ effects: [AsyncEffect<Action, CancelID>]
    ) async {
        logEffect(.concurrent(effects))

        let results = await executeParallelOperations(effects)
        await processParallelResults(effects: effects, results: results)
    }

    private func processSleepThenEffect(
        id: CancelID?,
        duration: TimeInterval,
        action: Action
    ) async {
        cancelExistingTask(id: id)

        let task = Task { [timer] in
            do {
                try await timer.sleep(for: duration)
                await MainActor.run { [weak self] in
                    self?.processActionEffect(action)
                    if !self!.isProcessingEffects {
                        Task {
                            await self?.processNextEffect()
                        }
                    }
                }
            } catch {
                // Sleep이 취소된 경우 무시
            }
        }

        registerTask(task, id: id)
    }

    private func processTimerEffect(
        id: CancelID?,
        interval: TimeInterval,
        action: Action
    ) {
        cancelExistingTask(id: id)

        let task = Task { [timer] in
            for await _ in timer.stream(interval: interval) {
                await MainActor.run { [weak self] in
                    self?.processActionEffect(action)
                }
            }
        }

        registerTask(task, id: id)
    }

    // MARK: - Operation Helpers

    private func cancelExistingTask(id: CancelID?) {
        guard let id = id else { return }
        tasks[id]?.cancel()
        tasks[id] = nil
    }

    private func measureOperation(
        _ operation: AsyncOperation<Action>
    ) async -> AsyncOperationResult<Action> {
        let startTime = CFAbsoluteTimeGetCurrent()
        let result = await operation()
        let duration = CFAbsoluteTimeGetCurrent() - startTime
        logPerformance("Effect operation", duration: duration)
        return result
    }

    private func registerTask(_ task: Task<Void, Never>, id: CancelID?) {
        guard let id = id else { return }
        tasks[id] = task

        Task {
            await task.value
            await MainActor.run { [weak self] in
                self?.tasks[id] = nil
            }
        }
    }

    /// - Parameters:
    ///   - result: 비동기 작업의 결과
    ///   - shouldTriggerProcessing: true이면 새 Effect 추가 시 처리를 시작합니다
    private func handleOperationResult(
        _ result: AsyncOperationResult<Action>,
        shouldTriggerProcessing: Bool = false
    ) {
        switch result {
        case let .action(action):
            processActionEffect(action)

            if shouldTriggerProcessing, !isProcessingEffects {
                Task {
                    await processNextEffect()
                }
            }
        case .none:
            break
        case let .error(error):
            logError(error)
            if !error.isCancellationError {
                handleError(error)
            }
        }
    }

    private func logStateChangeIfNeeded(from oldState: State, to newState: State) {
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

    private func logEffectsIfNeeded(_ effects: [AsyncEffect<Action, CancelID>]) {
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

    public func handleError(_: SendableError) {}

    // MARK: - Logging Helpers

    private func logEffects(_ effects: [AsyncEffect<Action, CancelID>]) {
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

    // MARK: - Concurrent Effect Helpers

    private func executeParallelOperations(
        _ effects: [AsyncEffect<Action, CancelID>]
    ) async -> [(index: Int, result: AsyncOperationResult<Action>)] {
        await withTaskGroup(
            of: (index: Int, result: AsyncOperationResult<Action>?).self
        ) { group in
            for (index, effect) in effects.enumerated() {
                if case let .run(_, operation) = effect {
                    group.addTask {
                        let result = await operation()
                        return (index, result)
                    }
                }
            }

            var results: [(index: Int, result: AsyncOperationResult<Action>)] = []
            for await (index, result) in group {
                if let result = result {
                    results.append((index, result))
                }
            }
            return results
        }
    }

    private func processParallelResults(
        effects: [AsyncEffect<Action, CancelID>],
        results: [(index: Int, result: AsyncOperationResult<Action>)]
    ) async {
        for (index, effect) in effects.enumerated() {
            switch effect {
            case let .run(id, _):
                if let operationResult = results.first(where: { $0.index == index })?.result {
                    cancelExistingTask(id: id)
                    handleOperationResult(operationResult)
                }
            default:
                await handleEffect(effect)
            }
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

    private func formatStateForLogging(_ state: State) -> String {
        return formatValueForLogging(state, indentLevel: 0)
    }

    private func formatValueForLogging(_ value: Any, indentLevel: Int) -> String {
        // 깊이 제한 체크
        let effectiveOptions = loggingConfig.options
        if indentLevel >= effectiveOptions.maxDepth {
            return "[...]"
        }

        let indent = String(repeating: "  ", count: indentLevel)
        let nextIndent = String(repeating: "  ", count: indentLevel + 1)

        let mirror = Mirror(reflecting: value)

        switch mirror.displayStyle {
        case .none, .optional, .enum:
            let result = String(describing: value)
            return truncateIfNeeded(result)
        case .collection, .dictionary, .set:
            let result = String(describing: value)
            return truncateIfNeeded(result)
        case .struct, .class:
            var result = "\(mirror.subjectType)("

            let properties = mirror.children.compactMap { child -> String? in
                guard let label = child.label else { return nil }
                let formattedValue = formatValueForLogging(
                    child.value,
                    indentLevel: indentLevel + 1
                )
                return "\(nextIndent)\(label): \(formattedValue)"
            }

            if !properties.isEmpty {
                result += "\n" + properties.joined(separator: ",\n") + "\n\(indent)"
            }
            result += ")"

            return truncateIfNeeded(result)
        case .tuple:
            let result = String(describing: value)
            return truncateIfNeeded(result)
        @unknown default:
            let result = String(describing: value)
            return truncateIfNeeded(result)
        }
    }

    private func truncateIfNeeded(_ value: String) -> String {
        let effectiveOptions = loggingConfig.options
        if value.count > effectiveOptions.maxValueLength {
            return String(value.prefix(effectiveOptions.maxValueLength)) + "..."
        }
        return value
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

    /// deinit에서 호출 가능한 nonisolated 로깅 메서드
    ///
    /// deinit은 actor isolation을 가질 수 없으므로, 이 메서드를 통해 로깅합니다.
    ///
    /// - Parameters:
    ///   - taskCount: 취소할 활성 Task 수
    public nonisolated func logDeinit(taskCount: Int) {
        let viewModelName = String(describing: Self.self)

        Task { @MainActor in
            let config = AsyncViewModelConfiguration.shared
            let logger = config.logger

            let message: String
            if taskCount > 0 {
                message = "deinit - Cancelling \(taskCount) active task(s)"
            } else {
                message = "deinit - No active tasks"
            }

            // ActionInfo 생성 (deinit은 특수 케이스)
            let actionInfo = ActionInfo(
                caseName: "deinit",
                associatedValues: [
                    ValueProperty(
                        name: "taskCount",
                        value: String(taskCount),
                        typeName: "Int"
                    ),
                ],
                fullDescription: message
            )

            logger.logAction(
                actionInfo,
                viewModel: viewModelName,
                file: #file,
                function: "deinit",
                line: #line
            )

            // Interceptor에 이벤트 전달
            let event = LogEvent.action(actionInfo)
            config.dispatch(event, viewModel: viewModelName, file: #file, function: "deinit", line: #line)
        }
    }

    // MARK: - Private Helpers

    /// Action에서 case 이름만 추출 (중첩 타입 제거)
    ///
    /// - Parameter action: Action 값
    /// - Returns: case 이름만 (예: "increment", "fetchData")
    private func extractCaseName(from action: Action) -> String {
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

    /// Action을 ActionInfo로 변환
    private func convertToActionInfo(_ action: Action) -> ActionInfo {
        let caseName = extractCaseName(from: action)
        let fullDescription = String(describing: action)
        let mirror = Mirror(reflecting: action)
        let printer = PrettyPrinter(maxDepth: nil)

        var associatedValues: [ValueProperty] = []

        // enum의 associated values 추출
        for child in mirror.children {
            let name = child.label?.starts(with: ".") == true
                ? ""
                : (child.label ?? "")
            let value = printer.format(child.value)
            let typeName = String(describing: type(of: child.value))

            // 중첩 프로퍼티 추출
            let childMirror = Mirror(reflecting: child.value)
            let children: [ValueProperty]
            switch childMirror.displayStyle {
            case .struct, .class:
                children = extractValueProperties(from: childMirror, printer: printer)
            default:
                children = []
            }

            associatedValues.append(ValueProperty(
                name: name,
                value: value,
                typeName: typeName,
                children: children,
                isNil: isOptionalNil(child.value)
            ))
        }

        return ActionInfo(
            caseName: caseName,
            associatedValues: associatedValues,
            fullDescription: fullDescription
        )
    }

    /// Mirror에서 ValueProperty 배열 추출
    private func extractValueProperties(
        from mirror: Mirror,
        printer: PrettyPrinter
    ) -> [ValueProperty] {
        return mirror.children.compactMap { child -> ValueProperty? in
            guard let label = child.label else { return nil }

            let childMirror = Mirror(reflecting: child.value)
            let typeName = String(describing: type(of: child.value))
            let value = printer.format(child.value)

            let children: [ValueProperty]
            switch childMirror.displayStyle {
            case .struct, .class:
                children = extractValueProperties(from: childMirror, printer: printer)
            default:
                children = []
            }

            return ValueProperty(
                name: label,
                value: value,
                typeName: typeName,
                children: children,
                isNil: isOptionalNil(child.value)
            )
        }
    }

    /// Optional 값이 nil인지 확인
    private func isOptionalNil(_ value: Any) -> Bool {
        let mirror = Mirror(reflecting: value)
        guard mirror.displayStyle == .optional else { return false }
        return mirror.children.isEmpty
    }

    /// AsyncEffect를 EffectInfo로 변환
    private func convertToEffectInfo(_ effect: AsyncEffect<Action, CancelID>) -> EffectInfo {
        let description = String(describing: effect)

        switch effect {
        case .none:
            return EffectInfo(
                effectType: .none,
                id: nil,
                relatedAction: nil,
                description: description
            )

        case let .action(action):
            return EffectInfo(
                effectType: .action,
                id: nil,
                relatedAction: convertToActionInfo(action),
                description: description
            )

        case let .run(id, _):
            let idString = id.map { String(describing: $0) }
            return EffectInfo(
                effectType: .run,
                id: idString,
                relatedAction: nil,
                description: description
            )

        case let .cancel(id):
            return EffectInfo(
                effectType: .cancel,
                id: String(describing: id),
                relatedAction: nil,
                description: description
            )

        case let .concurrent(effects):
            return EffectInfo(
                effectType: .concurrent,
                id: nil,
                relatedAction: nil,
                description: "concurrent(\(effects.count) effects)"
            )

        case let .sleepThen(id, duration, action):
            let idString = id.map { String(describing: $0) }
            return EffectInfo(
                effectType: .sleepThen,
                id: idString,
                relatedAction: convertToActionInfo(action),
                description: "sleepThen(duration: \(duration), action: \(extractCaseName(from: action)))"
            )

        case let .timer(id, interval, action):
            let idString = id.map { String(describing: $0) }
            return EffectInfo(
                effectType: .timer,
                id: idString,
                relatedAction: convertToActionInfo(action),
                description: "timer(interval: \(interval), action: \(extractCaseName(from: action)))"
            )
        }
    }
}
