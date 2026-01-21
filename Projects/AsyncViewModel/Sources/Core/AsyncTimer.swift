//
//  AsyncTimer.swift
//  AsyncViewModel
//
//  Created by AI Assistant on 2025/12/24.
//

import Foundation

/// 시간 기반 비동기 작업을 추상화하는 프로토콜
///
/// TCA의 Clock 패턴과 유사하게 시간 의존성을 주입 가능하도록 설계되었습니다.
///
/// **사용 예시:**
/// ```swift
/// @AsyncViewModel
/// final class MyViewModel: ObservableObject {
///     // 운영 환경: SystemTimer 사용 (기본값)
///     var timer: any AsyncTimer = SystemTimer()
///
///     // 테스트 환경: TestTimer 주입
///     // let timer: any AsyncTimer = TestTimer()
/// }
/// ```
public protocol AsyncTimer: Sendable {
    /// 지정된 시간만큼 대기합니다.
    ///
    /// - Parameter duration: 대기할 시간 (초 단위)
    /// - Throws: 취소 시 CancellationError
    func sleep(for duration: TimeInterval) async throws

    /// 지정된 간격으로 반복되는 타이머 스트림을 생성합니다.
    ///
    /// - Parameter interval: 반복 간격 (초 단위)
    /// - Returns: 타이머 틱마다 현재 시각을 방출하는 AsyncStream
    func stream(interval: TimeInterval) -> AsyncStream<Date>
}

// MARK: - SystemTimer

/// 실제 시스템 시간을 사용하는 타이머 (운영 환경용)
///
/// **사용 예시:**
/// ```swift
/// let timer = SystemTimer()
/// try await timer.sleep(for: 1.0) // 실제로 1초 대기
/// ```
public struct SystemTimer: AsyncTimer {
    public init() {}

    public func sleep(for duration: TimeInterval) async throws {
        try await Task.sleep(nanoseconds: UInt64(duration * 1_000_000_000))
    }

    public func stream(interval: TimeInterval) -> AsyncStream<Date> {
        AsyncStream { continuation in
            let task = Task {
                while !Task.isCancelled {
                    continuation.yield(Date())
                    try? await Task.sleep(nanoseconds: UInt64(interval * 1_000_000_000))
                }
                continuation.finish()
            }

            continuation.onTermination = { _ in
                task.cancel()
            }
        }
    }
}

// MARK: - TestTimer

/// 테스트용 타이머 (가상 시간 제어 가능)
///
/// 각 인스턴스가 독립적인 actor로 동작하여 병렬 테스트 실행 시에도 간섭이 없습니다.
///
/// **사용 예시:**
/// ```swift
/// @Test
/// func testDelayedAction() async throws {
///     let timer = TestTimer()
///     let viewModel = MyViewModel(timer: timer)
///
///     viewModel.send(.startTimer)
///
///     // 시간을 가상으로 진행
///     await timer.advance(by: 1.0)
///
///     #expect(viewModel.state.timerFired == true)
/// }
/// ```
public actor TestTimer: AsyncTimer {
    private var now: TimeInterval = 0
    private var scheduledSleeps: [(deadline: TimeInterval, continuation: CheckedContinuation<Void, Error>)] = []
    private var activeStreams: [UUID: StreamState] = [:]

    private struct StreamState {
        let interval: TimeInterval
        var lastTick: TimeInterval
        let continuation: AsyncStream<Date>.Continuation
    }

    public init() {}

    /// 현재 가상 시간
    public var currentTime: TimeInterval {
        now
    }

    /// 가상 시간을 진행시킵니다 (즉시 반환).
    ///
    /// - Parameter duration: 진행할 시간 (초 단위)
    ///
    /// **동작:**
    /// 1. 가상 시간을 진행
    /// 2. deadline이 현재 시간보다 작거나 같은 sleep들을 모두 재개
    /// 3. 활성 스트림들의 tick 발생
    ///
    /// **주의:** 이 메서드는 동기적으로 반환됩니다. 재개된 Task들이 실제로 실행되려면
    /// `run()`을 호출하거나 `tick(by:)`를 사용하세요.
    ///
    /// **사용 예시:**
    /// ```swift
    /// timer.advance(by: 1.0)  // 시간만 진행
    /// await timer.run()       // 모든 작업 실행
    /// ```
    public func advance(by duration: TimeInterval) {
        now += duration

        // Sleep 완료 처리
        let completedSleeps = scheduledSleeps.filter { $0.deadline <= now }
        scheduledSleeps.removeAll { $0.deadline <= now }

        for sleep in completedSleeps {
            sleep.continuation.resume()
        }

        // Stream tick 발생
        for (id, state) in activeStreams {
            let ticksSinceLastTick = Int((now - state.lastTick) / state.interval)
            if ticksSinceLastTick > 0 {
                for _ in 0 ..< ticksSinceLastTick {
                    state.continuation.yield(Date(timeIntervalSinceReferenceDate: now))
                }
                activeStreams[id]?.lastTick = now
            }
        }
    }

    /// 대기 중인 모든 작업을 실행합니다.
    ///
    /// 재개된 continuation들이 실제로 실행되고, 그로 인해 발생하는 모든 후속 작업이
    /// 완료될 때까지 대기합니다.
    ///
    /// **사용 예시:**
    /// ```swift
    /// timer.advance(by: 1.0)
    /// await timer.run()  // 모든 결과 작업이 완료될 때까지 대기
    /// ```
    public func run() async {
        // 스트림 처리를 위한 충분한 실행 기회 제공
        // continuation.yield() → for await → 값 처리 → 상태 업데이트까지 완료
        let minYields = 10 // 더 많은 yield로 안정성 향상

        // 안정 상태에 도달할 때까지 반복
        var previousSleepCount = scheduledSleeps.count
        var stableIterations = 0
        let maxIterations = 100 // 무한 루프 방지

        for iteration in 0 ..< maxIterations {
            await Task.yield()

            // 최소 실행 횟수를 보장한 후에만 안정성 체크
            if iteration >= minYields {
                // 상태가 변하지 않으면 안정화됨
                if scheduledSleeps.count == previousSleepCount {
                    stableIterations += 1
                    // 5회 연속 안정 시 완전히 안정화된 것으로 간주 (더 보수적)
                    if stableIterations >= 5 {
                        break
                    }
                } else {
                    // 새로운 작업이 예약되면 카운터 리셋
                    stableIterations = 0
                    previousSleepCount = scheduledSleeps.count
                }
            } else {
                // 최소 실행 중에도 상태 추적은 계속
                previousSleepCount = scheduledSleeps.count
            }
        }
    }

    /// 가상 시간을 진행시키고 모든 작업을 실행합니다.
    ///
    /// `advance(by:)` + `run()`의 편의 메서드입니다.
    ///
    /// **사용 예시:**
    /// ```swift
    /// await timer.tick(by: 1.0)  // 시간 진행 + 모든 작업 실행
    /// ```
    public func tick(by duration: TimeInterval) async {
        advance(by: duration)
        await run()
    }

    /// 모든 대기 중인 sleep을 즉시 완료시키고 작업을 실행합니다.
    public func flush() async {
        let allSleeps = scheduledSleeps
        scheduledSleeps.removeAll()

        for sleep in allSleeps {
            sleep.continuation.resume()
        }

        await run()
    }

    public func sleep(for duration: TimeInterval) async throws {
        // Actor에서 동기적으로 등록하여 race condition 방지
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            let deadline = now + duration
            scheduledSleeps.append((deadline, continuation))
        }
    }

    public nonisolated func stream(interval: TimeInterval) -> AsyncStream<Date> {
        AsyncStream { continuation in
            Task { [weak self] in
                guard let self else {
                    continuation.finish()
                    return
                }

                let id = UUID()
                let state = StreamState(
                    interval: interval,
                    lastTick: await self.now,
                    continuation: continuation
                )
                await self.registerStream(id: id, state: state)

                continuation.onTermination = { [weak self] _ in
                    Task {
                        await self?.unregisterStream(id: id)
                    }
                }
            }
        }
    }

    private func registerStream(id: UUID, state: StreamState) {
        activeStreams[id] = state
    }

    private func unregisterStream(id: UUID) {
        activeStreams[id] = nil
    }
}
