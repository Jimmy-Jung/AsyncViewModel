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

    /// 현재 상태
    var state: State { get set }

    /// 진행 중인 작업을 관리하는 딕셔너리
    var tasks: [CancelID: Task<Void, Never>] { get set }

    /// Effect 직렬 처리를 위한 큐
    var effectQueue: [AsyncEffect<Action, CancelID>] { get set }

    /// Effect 처리 상태
    var isProcessingEffects: Bool { get set }

    /// 디버깅/테스트를 위한 액션 관찰 훅
    var actionObserver: ((Action) -> Void)? { get set }

    // MARK: - Logging Properties

    /// 로깅 활성화/비활성화 플래그
    var isLoggingEnabled: Bool { get set }

    /// 현재 로깅 레벨
    var logLevel: LogLevel { get set }

    /// 상태 변경 관찰 훅
    var stateChangeObserver: ((State, State) -> Void)? { get set }

    /// Effect 실행 관찰 훅
    var effectObserver: ((AsyncEffect<Action, CancelID>) -> Void)? { get set }

    /// 성능 메트릭 관찰 훅
    var performanceObserver: ((String, TimeInterval) -> Void)? { get set }

    /// 입력 이벤트를 전송하여 처리를 시작합니다.
    func send(_ input: Input)

    /// 입력을 Action으로 변환합니다. (동기)
    func transform(_ input: Input) -> [Action]

    /// 순수 함수로 상태를 변경하고 부수 효과를 반환합니다.
    func reduce(state: inout State, action: Action) -> [AsyncEffect<
        Action, CancelID
    >]

    /// 에러 처리를 위한 메서드
    func handleError(_ error: SendableError)
}

// MARK: - Default Implementation

extension AsyncViewModelProtocol {
    /// 입력을 처리하는 개선된 메서드
    public func send(_ input: Input) {
        let actions = transform(input)

        for action in actions {
            perform(action)
        }
    }

    /// 액션을 직접 처리하는 메서드
    public func perform(_ action: Action) {
        let startTime = CFAbsoluteTimeGetCurrent()

        // 액션 로깅
        logAction(action)
        actionObserver?(action)

        // 상태 변경 전 상태 저장
        let oldState = state

        // 상태 변경 및 Effect 생성
        let effects = reduce(state: &state, action: action)

        // 상태 변경 로깅
        if oldState != state {
            logStateChange(from: oldState, to: state)
        }

        // Effect 큐에 추가
        effectQueue.append(contentsOf: effects)

        // Effect 로깅
        for effect in effects {
            logEffect(effect)
        }

        // 성능 측정 및 로깅
        let duration = CFAbsoluteTimeGetCurrent() - startTime
        logPerformance("Action processing", duration: duration, level: .debug)

        Task {
            await processNextEffect()
        }
    }

    /// Effect 큐를 순차적으로 처리합니다.
    ///
    /// **처리 순서**: Effect는 FIFO(선입선출) 순서로 처리됩니다.
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
        case .action(let action):
            processActionEffect(action)
        case .run(let id, let operation):
            await processRunEffect(id: id, operation: operation)
        case .cancel(let id):
            processCancelEffect(id: id)
        case .concurrent(let effects):
            await processConcurrentEffect(effects)
        }

        let duration = CFAbsoluteTimeGetCurrent() - startTime
        logPerformance("Effect handling", duration: duration, level: .debug)
    }

    // MARK: - Effect Processing Helpers

    /// 액션 Effect를 처리합니다.
    ///
    /// 재귀적으로 perform을 호출하지 않고, 현재 처리 루프에 통합하여 평탄화합니다.
    private func processActionEffect(_ action: Action) {
        logAction(action, level: .debug)
        actionObserver?(action)

        let oldState = state
        let newEffects = reduce(state: &state, action: action)

        if oldState != state {
            logStateChange(from: oldState, to: state)
        }

        effectQueue.append(contentsOf: newEffects)
        logEffects(newEffects)
    }

    /// 비동기 작업 Effect를 처리합니다.
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

    /// 취소 Effect를 처리합니다.
    private func processCancelEffect(id: CancelID) {
        logEffect(.cancel(id: id))
        tasks[id]?.cancel()
        tasks[id] = nil
    }

    /// 병렬 Effect를 처리합니다.
    ///
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

    // MARK: - Operation Helpers

    /// 기존 작업이 있다면 취소하고 제거합니다.
    private func cancelExistingTask(id: CancelID?) {
        guard let id = id else { return }
        tasks[id]?.cancel()
        tasks[id] = nil
    }

    /// 작업을 실행하고 성능을 측정합니다.
    private func measureOperation(
        _ operation: AsyncOperation<Action>
    ) async -> AsyncOperationResult<Action> {
        let startTime = CFAbsoluteTimeGetCurrent()
        let result = await operation()
        let duration = CFAbsoluteTimeGetCurrent() - startTime
        logPerformance("Effect operation", duration: duration, level: .debug)
        return result
    }

    /// Task를 등록하고 완료 시 정리합니다.
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

    /// 작업 결과를 처리합니다.
    ///
    /// - Parameters:
    ///   - result: 비동기 작업의 결과
    ///   - shouldTriggerProcessing: true이면 새 Effect 추가 시 처리를 시작합니다
    private func handleOperationResult(
        _ result: AsyncOperationResult<Action>,
        shouldTriggerProcessing: Bool = false
    ) {
        switch result {
        case .action(let action):
            processActionEffect(action)

            if shouldTriggerProcessing && !isProcessingEffects {
                Task {
                    await processNextEffect()
                }
            }
        case .none:
            break
        case .error(let error):
            logError(error)
            if !error.isCancellationError {
                handleError(error)
            }
        }
    }

    /// Effect 배열을 로깅합니다.
    private func logEffects(_ effects: [AsyncEffect<Action, CancelID>]) {
        for effect in effects {
            logEffect(effect)
        }
    }

    // MARK: - Concurrent Effect Helpers

    /// .run 효과들을 병렬로 실행하고 결과를 수집합니다.
    private func executeParallelOperations(
        _ effects: [AsyncEffect<Action, CancelID>]
    ) async -> [(index: Int, result: AsyncOperationResult<Action>)] {
        await withTaskGroup(
            of: (index: Int, result: AsyncOperationResult<Action>?).self
        ) { group in
            for (index, effect) in effects.enumerated() {
                if case .run(_, let operation) = effect {
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

    /// 병렬 실행 결과를 순차적으로 처리합니다.
    private func processParallelResults(
        effects: [AsyncEffect<Action, CancelID>],
        results: [(index: Int, result: AsyncOperationResult<Action>)]
    ) async {
        for (index, effect) in effects.enumerated() {
            switch effect {
            case .run(let id, _):
                if let operationResult = results.first(where: { $0.index == index })?.result {
                    cancelExistingTask(id: id)
                    handleOperationResult(operationResult)
                }
            default:
                await handleEffect(effect)
            }
        }
    }

    /// 에러 처리를 위한 기본 구현
    public func handleError(_ error: SendableError) {
        // 기본적으로는 아무것도 하지 않음
        // 에러 로깅은 handleEffect에서 이미 처리됨
        // 구체적인 ViewModel에서 필요에 따라 오버라이드하여 구현
    }

    // MARK: - Logging Helpers

    /// 액션 로깅
    public func logAction(_ action: Action, level: LogLevel = .info) {
        guard isLoggingEnabled, level.rawValue >= logLevel.rawValue else {
            return
        }

        let logger = Logger(
            subsystem: "com.jimmy.AsyncViewModel",
            category: String(describing: Self.self)
        )
        let message = "Action: \(String(describing: action))"

        switch level {
        case .debug:
            logger.debug("\(message, privacy: .public)")
        case .info:
            logger.info("\(message, privacy: .public)")
        case .warning:
            logger.warning("\(message, privacy: .public)")
        case .error:
            logger.error("\(message, privacy: .public)")
        }
    }

    /// 상태 변경 로깅
    public func logStateChange(from oldState: State, to newState: State) {
        guard isLoggingEnabled, logLevel.rawValue <= LogLevel.info.rawValue
        else { return }

        let logger = Logger(
            subsystem: "com.jimmy.AsyncViewModel",
            category: String(describing: Self.self)
        )

        // JSON 형태로 포맷팅하여 읽기 편하게 출력
        let oldStateFormatted = formatStateForLogging(oldState)
        let newStateFormatted = formatStateForLogging(newState)

        logger.info(
            "State changed from:\n\(oldStateFormatted, privacy: .public)"
        )
        logger.info("State changed to:\n\(newStateFormatted, privacy: .public)")

        // 상태 변경 관찰자 호출
        stateChangeObserver?(oldState, newState)
    }

    /// 상태를 로깅용으로 포맷팅하는 헬퍼 메서드
    private func formatStateForLogging(_ state: State) -> String {
        return formatValueForLogging(state, indentLevel: 0)
    }

    /// 값을 재귀적으로 로깅용으로 포맷팅하는 헬퍼 메서드
    private func formatValueForLogging(_ value: Any, indentLevel: Int) -> String
    {
        let indent = String(repeating: "  ", count: indentLevel)
        let nextIndent = String(repeating: "  ", count: indentLevel + 1)

        let mirror = Mirror(reflecting: value)

        // 기본 타입들은 바로 문자열로 변환
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
                result +=
                    "\n" + properties.joined(separator: ",\n") + "\n\(indent)"
            }
            result += ")"

            return result
        case .tuple:
            return String(describing: value)
        @unknown default:
            return String(describing: value)
        }
    }

    /// Effect 실행 로깅
    public func logEffect(_ effect: AsyncEffect<Action, CancelID>) {
        guard isLoggingEnabled, logLevel.rawValue <= LogLevel.debug.rawValue
        else { return }

        let logger = Logger(
            subsystem: "com.jimmy.AsyncViewModel",
            category: String(describing: Self.self)
        )
        logger.debug("Effect: \(String(describing: effect), privacy: .public)")

        // Effect 관찰자 호출
        effectObserver?(effect)
    }

    /// 성능 메트릭 로깅
    public func logPerformance(
        _ operation: String,
        duration: TimeInterval,
        level: LogLevel = .info
    ) {
        guard isLoggingEnabled, level.rawValue >= logLevel.rawValue else {
            return
        }

        let logger = Logger(
            subsystem: "com.jimmy.AsyncViewModel",
            category: String(describing: Self.self)
        )
        let message =
            "Performance - \(operation): \(String(format: "%.3f", duration))s"

        switch level {
        case .debug:
            logger.debug("\(message, privacy: .public)")
        case .info:
            logger.info("\(message, privacy: .public)")
        case .warning:
            logger.warning("\(message, privacy: .public)")
        case .error:
            logger.error("\(message, privacy: .public)")
        }

        // 성능 관찰자 호출
        performanceObserver?(operation, duration)
    }

    /// 에러 로깅
    public func logError(_ error: SendableError, level: LogLevel = .error) {
        guard isLoggingEnabled, level.rawValue >= logLevel.rawValue else {
            return
        }

        let logger = Logger(
            subsystem: "com.jimmy.AsyncViewModel",
            category: String(describing: Self.self)
        )
        let message =
            "Error: \(error.localizedDescription) [\(error.domain):\(error.code)]"

        switch level {
        case .debug:
            logger.debug("\(message, privacy: .public)")
        case .info:
            logger.info("\(message, privacy: .public)")
        case .warning:
            logger.warning("\(message, privacy: .public)")
        case .error:
            logger.error("\(message, privacy: .public)")
        }
    }
}
