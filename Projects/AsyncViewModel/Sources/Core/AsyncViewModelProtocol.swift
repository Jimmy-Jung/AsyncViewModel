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
    var effectObserver: ((AsyncEffect<Action, CancelID>) -> Void)? { get set}
    var performanceObserver: ((String, TimeInterval) -> Void)? { get set }

    func send(_ input: Input)
    func transform(_ input: Input) -> [Action]
    func reduce(state: inout State, action: Action) -> [AsyncEffect<Action, CancelID>]
    func handleError(_ error: SendableError)
}

// MARK: - Default Implementation

extension AsyncViewModelProtocol {
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
        logPerformance("Action processing", duration: duration, level: .debug)

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
        logPerformance("Effect handling", duration: duration, level: .debug)
    }

    // MARK: - Effect Processing Helpers

    /// 재귀적으로 perform을 호출하지 않고, 현재 처리 루프에 통합하여 평탄화합니다.
    private func processActionEffect(_ action: Action) {
        logAction(action, level: .debug)
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
        logPerformance("Effect operation", duration: duration, level: .debug)
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
        
        let logger = LoggerConfiguration.logger
        if logger.options.showStateDiffOnly {
            let diff = calculateStateDiff(from: oldState, to: newState)
            if !diff.isEmpty {
                logStateDiff(diff)
            }
        } else {
            logStateChange(from: oldState, to: newState)
        }
        
        stateChangeObserver?(oldState, newState)
    }
    
    private func logEffectsIfNeeded(_ effects: [AsyncEffect<Action, CancelID>]) {
        guard !effects.isEmpty else { return }
        
        let logger = LoggerConfiguration.logger
        if logger.options.groupEffects {
            logEffects(effects)
        } else {
            for effect in effects {
                logEffect(effect)
            }
        }
    }

    public func handleError(_: SendableError) {
    }

    // MARK: - Logging Helpers

    private func calculateStateDiff(
        from oldState: State,
        to newState: State
    ) -> [String: (old: String, new: String)] {
        var changes: [String: (old: String, new: String)] = [:]
        
        let oldMirror = Mirror(reflecting: oldState)
        let newMirror = Mirror(reflecting: newState)
        
        for (oldChild, newChild) in zip(oldMirror.children, newMirror.children) {
            guard let label = oldChild.label else { continue }
            
            let oldValue = String(describing: oldChild.value)
            let newValue = String(describing: newChild.value)
            
            if oldValue != newValue {
                changes[label] = (old: oldValue, new: newValue)
            }
        }
        
        return changes
    }
    
    private func logStateDiff(_ changes: [String: (old: String, new: String)]) {
        let viewModelName = String(describing: Self.self)
        
        LoggerConfiguration.logger.logStateDiff(
            changes: changes,
            viewModel: viewModelName,
            file: #file,
            function: #function,
            line: #line
        )
    }
    
    private func logEffects(_ effects: [AsyncEffect<Action, CancelID>]) {
        let effectDescriptions = effects.map { String(describing: $0) }
        let viewModelName = String(describing: Self.self)
        
        LoggerConfiguration.logger.logEffects(
            effectDescriptions,
            viewModel: viewModelName,
            file: #file,
            function: #function,
            line: #line
        )
        
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
        level: LogLevel = .info,
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) {
        let actionDescription = String(describing: action)
        let viewModelName = String(describing: Self.self)

        LoggerConfiguration.logger.logAction(
            actionDescription,
            viewModel: viewModelName,
            level: level,
            file: file,
            function: function,
            line: line
        )
    }

    public func logStateChange(
        from oldState: State,
        to newState: State,
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) {
        let viewModelName = String(describing: Self.self)
        let oldStateFormatted = formatStateForLogging(oldState)
        let newStateFormatted = formatStateForLogging(newState)

        LoggerConfiguration.logger.logStateChange(
            from: oldStateFormatted,
            to: newStateFormatted,
            viewModel: viewModelName,
            file: file,
            function: function,
            line: line
        )

        stateChangeObserver?(oldState, newState)
    }

    private func formatStateForLogging(_ state: State) -> String {
        return formatValueForLogging(state, indentLevel: 0)
    }

    private func formatValueForLogging(_ value: Any, indentLevel: Int) -> String {
        let indent = String(repeating: "  ", count: indentLevel)
        let nextIndent = String(repeating: "  ", count: indentLevel + 1)

        let mirror = Mirror(reflecting: value)

        switch mirror.displayStyle {
        case .none, .optional, .enum:
            return String(describing: value)
        case .collection, .dictionary, .set:
            return String(describing: value)
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

            return result
        case .tuple:
            return String(describing: value)
        @unknown default:
            return String(describing: value)
        }
    }

    public func logEffect(
        _ effect: AsyncEffect<Action, CancelID>,
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) {
        let viewModelName = String(describing: Self.self)
        let effectDescription = String(describing: effect)

        LoggerConfiguration.logger.logEffect(
            effectDescription,
            viewModel: viewModelName,
            file: file,
            function: function,
            line: line
        )

        effectObserver?(effect)
    }

    public func logPerformance(
        _ operation: String,
        duration: TimeInterval,
        level: LogLevel = .info,
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) {
        let viewModelName = String(describing: Self.self)

        LoggerConfiguration.logger.logPerformance(
            operation: operation,
            duration: duration,
            viewModel: viewModelName,
            level: level,
            file: file,
            function: function,
            line: line
        )

        performanceObserver?(operation, duration)
    }

    public func logError(
        _ error: SendableError,
        level: LogLevel = .error,
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) {
        let viewModelName = String(describing: Self.self)

        LoggerConfiguration.logger.logError(
            error,
            viewModel: viewModelName,
            level: level,
            file: file,
            function: function,
            line: line
        )
    }
    
    /// deinit에서 호출 가능한 nonisolated 로깅 메서드
    ///
    /// deinit은 actor isolation을 가질 수 없으므로, 이 메서드를 통해 로깅합니다.
    ///
    /// - Parameters:
    ///   - taskCount: 취소할 활성 Task 수
    nonisolated public func logDeinit(taskCount: Int) {
        let viewModelName = String(describing: Self.self)
        
        Task { @MainActor in
            if taskCount > 0 {
                LoggerConfiguration.logger.logAction(
                    "🔄 deinit - Cancelling \(taskCount) active task(s)",
                    viewModel: viewModelName,
                    level: .info,
                    file: #file,
                    function: "deinit",
                    line: #line
                )
            } else {
                LoggerConfiguration.logger.logAction(
                    "✅ deinit - No active tasks",
                    viewModel: viewModelName,
                    level: .debug,
                    file: #file,
                    function: "deinit",
                    line: #line
                )
            }
        }
    }
}
