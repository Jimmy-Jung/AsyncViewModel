//
//  AsyncTimerTests.swift
//  AsyncViewModelTests
//
//  Created by jimmy on 2025/12/29.
//

import Testing
import Foundation
@testable import AsyncViewModelCore

// MARK: - TestTimer Tests

@Suite("TestTimer 테스트")
@MainActor
struct TestTimerTests {
    @Test("초기 시간은 0이다")
    func initialTime() {
        let timer = TestTimer()
        #expect(timer.currentTime == 0)
    }
    
    @Test("tick으로 시간을 진행시킬 수 있다")
    func tickTime() async {
        let timer = TestTimer()
        await timer.tick(by: 1.0)
        #expect(timer.currentTime == 1.0)
        
        await timer.tick(by: 2.5)
        #expect(timer.currentTime == 3.5)
    }
    
    @Test("sleep은 tick 호출 전까지 대기한다")
    func sleepWaitsForTick() async throws {
        let timer = TestTimer()
        var completed = false
        
        Task {
            try await timer.sleep(for: 1.0)
            completed = true
        }
        
        // sleep은 아직 완료되지 않음
        try await Task.sleep(nanoseconds: 10_000_000) // 실제 시간 약간 대기
        #expect(completed == false)
        
        // 시간 진행
        await timer.tick(by: 1.0)
        
        // sleep 완료 대기
        try await Task.sleep(nanoseconds: 10_000_000)
        #expect(completed == true)
    }
    
    @Test("여러 sleep을 동시에 처리할 수 있다")
    func multipleSleeps() async throws {
        let timer = TestTimer()
        var completed1 = false
        var completed2 = false
        var completed3 = false
        
        Task {
            try await timer.sleep(for: 1.0)
            completed1 = true
        }
        
        Task {
            try await timer.sleep(for: 2.0)
            completed2 = true
        }
        
        Task {
            try await timer.sleep(for: 3.0)
            completed3 = true
        }
        
        // Task들이 sleep을 등록할 시간 대기
        try await Task.sleep(nanoseconds: 50_000_000)
        
        // 1초 진행
        await timer.tick(by: 1.0)
        try await Task.sleep(nanoseconds: 10_000_000)
        #expect(completed1 == true)
        #expect(completed2 == false)
        #expect(completed3 == false)
        
        // 1초 더 진행 (총 2초)
        await timer.tick(by: 1.0)
        try await Task.sleep(nanoseconds: 10_000_000)
        #expect(completed2 == true)
        #expect(completed3 == false)
        
        // 1초 더 진행 (총 3초)
        await timer.tick(by: 1.0)
        try await Task.sleep(nanoseconds: 10_000_000)
        #expect(completed3 == true)
    }
    
    @Test("flush는 모든 sleep을 즉시 완료시킨다")
    func flushCompletesAllSleeps() async throws {
        let timer = TestTimer()
        var completed1 = false
        var completed2 = false
        
        Task {
            try await timer.sleep(for: 100.0)
            completed1 = true
        }
        
        Task {
            try await timer.sleep(for: 200.0)
            completed2 = true
        }
        
        // Task들이 sleep을 등록할 시간 대기
        try await Task.sleep(nanoseconds: 50_000_000)
        
        // flush 호출
        await timer.flush()
        
        // 모든 sleep 즉시 완료
        try await Task.sleep(nanoseconds: 10_000_000)
        #expect(completed1 == true)
        #expect(completed2 == true)
    }
    
    @Test("stream은 interval마다 값을 방출한다")
    func streamEmitsAtInterval() async throws {
        let timer = TestTimer()
        var ticks: [Date] = []
        
        Task {
            for await date in timer.stream(interval: 1.0) {
                ticks.append(date)
                if ticks.count >= 3 {
                    break
                }
            }
        }
        
        try await Task.sleep(nanoseconds: 10_000_000)
        #expect(ticks.count == 0)
        
        // 1초 진행
        await timer.tick(by: 1.0)
        try await Task.sleep(nanoseconds: 10_000_000)
        #expect(ticks.count == 1)
        
        // 1초 더 진행
        await timer.tick(by: 1.0)
        try await Task.sleep(nanoseconds: 10_000_000)
        #expect(ticks.count == 2)
        
        // 1초 더 진행
        await timer.tick(by: 1.0)
        try await Task.sleep(nanoseconds: 10_000_000)
        #expect(ticks.count == 3)
    }
}


