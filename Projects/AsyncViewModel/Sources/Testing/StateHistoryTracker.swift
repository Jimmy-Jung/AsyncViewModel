//
//  StateHistoryTracker.swift
//  AsyncViewModel
//
//  Created by jimmy on 2025/01/21.
//

import Foundation

// MARK: - State History Tracking

/// 상태 변경 히스토리를 추적하는 클래스
///
/// ViewModel의 상태 변경 이력을 기록하여 테스트에서 상태 전이를 검증할 수 있습니다.
///
/// **사용 예시:**
/// ```swift
/// let tracker = StateHistoryTracker<MyState>()
///
/// // ViewModel의 stateChangeObserver에 연결
/// viewModel.stateChangeObserver = { old, new in
///     tracker.record(old: old, new: new)
/// }
///
/// viewModel.send(.increment)
/// viewModel.send(.increment)
///
/// #expect(tracker.history.count == 2)
/// #expect(tracker.history[0].old.count == 0)
/// #expect(tracker.history[0].new.count == 1)
/// ```
public final class StateHistoryTracker<S: Equatable & Sendable>: @unchecked Sendable {
    /// 상태 변경 기록
    public struct StateChange: Sendable {
        public let old: S
        public let new: S
        public let timestamp: Date

        public init(old: S, new: S, timestamp: Date = Date()) {
            self.old = old
            self.new = new
            self.timestamp = timestamp
        }
    }

    private var _history: [StateChange] = []
    private let lock = NSLock()

    public init() {}

    /// 상태 변경 히스토리
    public var history: [StateChange] {
        lock.lock()
        defer { lock.unlock() }
        return _history
    }

    /// 히스토리 개수
    public var count: Int {
        lock.lock()
        defer { lock.unlock() }
        return _history.count
    }

    /// 히스토리가 비어있는지 확인
    public var isEmpty: Bool {
        lock.lock()
        defer { lock.unlock() }
        return _history.isEmpty
    }

    /// 마지막 상태 변경
    public var last: StateChange? {
        lock.lock()
        defer { lock.unlock() }
        return _history.last
    }

    /// 첫 번째 상태 변경
    public var first: StateChange? {
        lock.lock()
        defer { lock.unlock() }
        return _history.first
    }

    /// 상태 변경을 기록합니다.
    ///
    /// - Parameters:
    ///   - old: 이전 상태
    ///   - new: 새 상태
    public func record(old: S, new: S) {
        lock.lock()
        defer { lock.unlock() }
        _history.append(StateChange(old: old, new: new))
    }

    /// 히스토리를 초기화합니다.
    public func clear() {
        lock.lock()
        defer { lock.unlock() }
        _history.removeAll()
    }

    /// 인덱스로 상태 변경에 접근합니다.
    public subscript(index: Int) -> StateChange? {
        lock.lock()
        defer { lock.unlock() }
        guard index >= 0, index < _history.count else { return nil }
        return _history[index]
    }
}

// MARK: - AsyncTestStore Integration

@available(macOS 10.15, *)
public extension AsyncTestStore {
    /// 상태 히스토리 추적을 활성화하고 트래커를 반환합니다.
    ///
    /// **사용 예시:**
    /// ```swift
    /// let testStore = AsyncTestStore(viewModel: viewModel)
    /// let tracker = testStore.enableStateTracking()
    ///
    /// testStore.send(.increment)
    /// testStore.send(.increment)
    ///
    /// #expect(tracker.count == 2)
    /// ```
    @discardableResult
    func enableStateTracking() -> StateHistoryTracker<ViewModel.State> {
        let tracker = StateHistoryTracker<ViewModel.State>()

        let originalObserver = viewModel.stateChangeObserver
        viewModel.stateChangeObserver = { [weak tracker] old, new in
            tracker?.record(old: old, new: new)
            originalObserver?(old, new)
        }

        return tracker
    }
}
