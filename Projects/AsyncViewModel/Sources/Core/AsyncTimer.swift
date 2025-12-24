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
@MainActor
public final class TestTimer: AsyncTimer {
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
    
    /// 가상 시간을 진행시킵니다.
    ///
    /// - Parameter duration: 진행할 시간 (초 단위)
    ///
    /// **동작:**
    /// 1. deadline이 현재 시간보다 작거나 같은 sleep들을 모두 완료
    /// 2. 활성 스트림들의 tick 발생
    public nonisolated func tick(by duration: TimeInterval) async {
        await MainActor.run { [weak self] in
            guard let self = self else { return }
            self.now += duration
            
            // Sleep 완료 처리
            let completedSleeps = self.scheduledSleeps.filter { $0.deadline <= self.now }
            self.scheduledSleeps.removeAll { $0.deadline <= self.now }
            
            for sleep in completedSleeps {
                sleep.continuation.resume()
            }
            
            // Stream tick 발생
            for (id, state) in self.activeStreams {
                let ticksSinceLastTick = Int((self.now - state.lastTick) / state.interval)
                if ticksSinceLastTick > 0 {
                    for _ in 0..<ticksSinceLastTick {
                        state.continuation.yield(Date(timeIntervalSinceReferenceDate: self.now))
                    }
                    self.activeStreams[id]?.lastTick = self.now
                }
            }
        }
    }
    
    /// 모든 대기 중인 sleep을 즉시 완료시킵니다.
    public nonisolated func flush() async {
        await MainActor.run { [weak self] in
            guard let self = self else { return }
            let allSleeps = self.scheduledSleeps
            self.scheduledSleeps.removeAll()
            
            for sleep in allSleeps {
                sleep.continuation.resume()
            }
        }
    }
    
    public nonisolated func sleep(for duration: TimeInterval) async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            Task { @MainActor [weak self] in
                guard let self = self else {
                    continuation.resume()
                    return
                }
                let deadline = self.now + duration
                self.scheduledSleeps.append((deadline, continuation))
            }
        }
    }
    
    public nonisolated func stream(interval: TimeInterval) -> AsyncStream<Date> {
        AsyncStream { continuation in
            Task { @MainActor [weak self] in
                guard let self = self else {
                    continuation.finish()
                    return
                }
                
                let id = UUID()
                let state = StreamState(
                    interval: interval,
                    lastTick: self.now,
                    continuation: continuation
                )
                self.activeStreams[id] = state
                
                continuation.onTermination = { [weak self] _ in
                    Task { @MainActor in
                        self?.activeStreams[id] = nil
                    }
                }
            }
        }
    }
}

