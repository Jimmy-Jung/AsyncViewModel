//
//  AsyncViewModelProtocol+Effects.swift
//  AsyncViewModel
//
//  Created by jimmy on 2025/01/21.
//

import Foundation

// MARK: - Effect Processing

extension AsyncViewModelProtocol {
    // MARK: - Effect Queue Processing

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
    func processNextEffect() async {
        guard !isProcessingEffects else { return }
        isProcessingEffects = true

        while !effectQueue.isEmpty {
            let effect = effectQueue.removeFirst()
            await handleEffect(effect)
        }

        isProcessingEffects = false
    }

    func handleEffect(_ effect: AsyncEffect<Action, CancelID>) async {
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

    // MARK: - Effect Type Handlers

    /// 재귀적으로 perform을 호출하지 않고, 현재 처리 루프에 통합하여 평탄화합니다.
    func processActionEffect(_ action: Action) {
        logAction(action)
        actionObserver?(action)

        let oldState = state
        let newEffects = reduce(state: &state, action: action)

        logStateChangeIfNeeded(from: oldState, to: state)
        effectQueue.append(contentsOf: newEffects)
        logEffectsIfNeeded(newEffects)
    }

    func processRunEffect(
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

    func processCancelEffect(id: CancelID) {
        logEffect(.cancel(id: id))
        tasks[id]?.cancel()
        tasks[id] = nil
    }

    /// 처리 전략:
    /// 1. .run 효과들의 operation은 병렬로 실행 (백그라운드 스레드)
    /// 2. 모든 operation 결과를 수집한 후 MainActor에서 순차 처리
    /// 3. 비-.run 효과들(.action, .cancel 등)은 순차 처리
    func processConcurrentEffect(
        _ effects: [AsyncEffect<Action, CancelID>]
    ) async {
        logEffect(.concurrent(effects))

        let results = await executeParallelOperations(effects)
        await processParallelResults(effects: effects, results: results)
    }

    func processSleepThenEffect(
        id: CancelID?,
        duration: TimeInterval,
        action: Action
    ) async {
        cancelExistingTask(id: id)

        let task = Task { [timer] in
            do {
                try await timer.sleep(for: duration)

                // TestTimer의 경우, Task가 취소되어도 continuation이 resume될 수 있음
                // 따라서 sleep 후에도 취소 여부를 확인
                guard !Task.isCancelled else { return }

                await MainActor.run { [weak self] in
                    self?.processActionEffect(action)
                    if self?.isProcessingEffects == false {
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

    func processTimerEffect(
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

    // MARK: - Task Management

    func cancelExistingTask(id: CancelID?) {
        guard let id = id else { return }
        tasks[id]?.cancel()
        tasks[id] = nil
    }

    func measureOperation(
        _ operation: AsyncOperation<Action>
    ) async -> AsyncOperationResult<Action> {
        let startTime = CFAbsoluteTimeGetCurrent()
        let result = await operation()
        let duration = CFAbsoluteTimeGetCurrent() - startTime
        logPerformance("Effect operation", duration: duration)
        return result
    }

    func registerTask(_ task: Task<Void, Never>, id: CancelID?) {
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
    func handleOperationResult(
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

    // MARK: - Concurrent Effect Helpers

    func executeParallelOperations(
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

    func processParallelResults(
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
}
