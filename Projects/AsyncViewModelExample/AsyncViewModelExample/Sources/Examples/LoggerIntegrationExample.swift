//
//  LoggerIntegrationExample.swift
//  AsyncViewModelExample
//
//  Created by jimmy on 2025/12/18.
//

import AsyncViewModel
import Foundation

#if canImport(TraceKit)
    import TraceKit
#endif

/// AsyncViewModel Logger 통합 예시
///
/// 이 예시는 AsyncViewModel에 커스텀 로거를 주입하는 다양한 방법을 보여줍니다.

// MARK: - 1. 기본 사용 (OSLogViewModelLogger)

/// 기본적으로 AsyncViewModel은 OSLogViewModelLogger를 사용합니다.
/// 로거를 주입하지 않으면 전역 기본 로거(OSLogViewModelLogger)가 사용됩니다.
class ExampleViewModel1: ObservableObject, AsyncViewModelProtocol {
    @Published var state = State()
    var tasks: [CancelID: Task<Void, Never>] = [:]
    var effectQueue: [AsyncEffect<Action, CancelID>] = []
    var isProcessingEffects = false
    var timer: any AsyncTimer = SystemTimer()
    var actionObserver: ((Action) -> Void)?

    // 로깅 설정
    var isLoggingEnabled = true
    var logLevel: LogLevel = .debug
    var logger: (any ViewModelLogger)? // nil이면 전역 기본 로거 사용 (기본값: OSLogViewModelLogger)

    var stateChangeObserver: ((State, State) -> Void)?
    var effectObserver: ((AsyncEffect<Action, CancelID>) -> Void)?
    var performanceObserver: ((String, TimeInterval) -> Void)?

    struct State: Equatable, Sendable {}
    enum Action: Equatable, Sendable { case dummy }
    enum CancelID: Hashable, Sendable {}

    func transform(_: Void) -> [Action] { [] }
    func reduce(state _: inout State, action _: Action) -> [AsyncEffect<Action, CancelID>] { [] }
}

// MARK: - 2. os.log 명시적 사용

/// os.log를 명시적으로 설정하려면 OSLogViewModelLogger를 사용합니다.
class ExampleViewModel2: ObservableObject, AsyncViewModelProtocol {
    @Published var state = State()
    var tasks: [CancelID: Task<Void, Never>] = [:]
    var effectQueue: [AsyncEffect<Action, CancelID>] = []
    var isProcessingEffects = false
    var timer: any AsyncTimer = SystemTimer()
    var actionObserver: ((Action) -> Void)?

    // 로깅 설정
    var isLoggingEnabled = true
    var logLevel: LogLevel = .debug
    var logger: (any ViewModelLogger)? = OSLogViewModelLogger(subsystem: "com.myapp")

    var stateChangeObserver: ((State, State) -> Void)?
    var effectObserver: ((AsyncEffect<Action, CancelID>) -> Void)?
    var performanceObserver: ((String, TimeInterval) -> Void)?

    struct State: Equatable, Sendable {}
    enum Action: Equatable, Sendable { case dummy }
    enum CancelID: Hashable, Sendable {}

    func transform(_: Void) -> [Action] { [] }
    func reduce(state _: inout State, action _: Action) -> [AsyncEffect<Action, CancelID>] { [] }
}

// MARK: - 3. 로깅 비활성화

/// 로깅을 완전히 비활성화하려면 NoOpLogger를 사용합니다.
/// 프로덕션 환경이나 성능이 중요한 경우 유용합니다.
class ExampleViewModel3: ObservableObject, AsyncViewModelProtocol {
    @Published var state = State()
    var tasks: [CancelID: Task<Void, Never>] = [:]
    var effectQueue: [AsyncEffect<Action, CancelID>] = []
    var isProcessingEffects = false
    var timer: any AsyncTimer = SystemTimer()
    var actionObserver: ((Action) -> Void)?

    // 로깅 설정
    var isLoggingEnabled = true // NoOpLogger를 사용하면 이 플래그는 무시됨
    var logLevel: LogLevel = .debug
    var logger: (any ViewModelLogger)? = NoOpLogger()

    var stateChangeObserver: ((State, State) -> Void)?
    var effectObserver: ((AsyncEffect<Action, CancelID>) -> Void)?
    var performanceObserver: ((String, TimeInterval) -> Void)?

    struct State: Equatable, Sendable {}
    enum Action: Equatable, Sendable { case dummy }
    enum CancelID: Hashable, Sendable {}

    func transform(_: Void) -> [Action] { [] }
    func reduce(state _: inout State, action _: Action) -> [AsyncEffect<Action, CancelID>] { [] }
}

// MARK: - 4. 커스텀 로거 구현

/// ViewModelLogger 프로토콜을 구현하여 커스텀 로거를 만들 수 있습니다.
@MainActor
struct ConsoleLogger: ViewModelLogger {
    var options: LoggingOptions = .init()

    func logAction(
        _ action: String,
        viewModel: String,
        level: LogLevel,
        file _: String,
        function _: String,
        line _: Int
    ) {
        print("[\(level.description)] \(viewModel) - Action: \(action)")
    }

    func logStateChange(
        from oldState: String,
        to newState: String,
        viewModel: String,
        file _: String,
        function _: String,
        line _: Int
    ) {
        print("[\(viewModel)] State changed:")
        print("  From: \(oldState)")
        print("  To: \(newState)")
    }

    func logEffect(
        _ effect: String,
        viewModel: String,
        file _: String,
        function _: String,
        line _: Int
    ) {
        print("[\(viewModel)] Effect: \(effect)")
    }

    func logEffects(
        _ effects: [String],
        viewModel: String,
        file _: String,
        function _: String,
        line _: Int
    ) {
        print("[\(viewModel)] Effects[\(effects.count)]")
    }

    func logStateDiff(
        changes: [String: (old: String, new: String)],
        viewModel: String,
        file _: String,
        function _: String,
        line _: Int
    ) {
        print("[\(viewModel)] State changed:")
        for (key, values) in changes.sorted(by: { $0.key < $1.key }) {
            print("  - \(key): \(values.old) → \(values.new)")
        }
    }

    func logPerformance(
        operation: String,
        duration: TimeInterval,
        viewModel: String,
        level _: LogLevel,
        file _: String,
        function _: String,
        line _: Int
    ) {
        print("[\(viewModel)] Performance - \(operation): \(String(format: "%.3f", duration))s")
    }

    func logError(
        _ error: SendableError,
        viewModel: String,
        level _: LogLevel,
        file _: String,
        function _: String,
        line _: Int
    ) {
        print("[\(viewModel)] Error: \(error.localizedDescription)")
    }
}

class ExampleViewModel4: ObservableObject, AsyncViewModelProtocol {
    @Published var state = State()
    var tasks: [CancelID: Task<Void, Never>] = [:]
    var effectQueue: [AsyncEffect<Action, CancelID>] = []
    var isProcessingEffects = false
    var timer: any AsyncTimer = SystemTimer()
    var actionObserver: ((Action) -> Void)?

    // 로깅 설정
    var isLoggingEnabled = true
    var logLevel: LogLevel = .debug
    var logger: (any ViewModelLogger)? = ConsoleLogger()

    var stateChangeObserver: ((State, State) -> Void)?
    var effectObserver: ((AsyncEffect<Action, CancelID>) -> Void)?
    var performanceObserver: ((String, TimeInterval) -> Void)?

    struct State: Equatable, Sendable {}
    enum Action: Equatable, Sendable { case dummy }
    enum CancelID: Hashable, Sendable {}

    func transform(_: Void) -> [Action] { [] }
    func reduce(state _: inout State, action _: Action) -> [AsyncEffect<Action, CancelID>] { [] }
}

// MARK: - 5. TraceKit 통합

/// TraceKit은 AsyncViewModel의 기본 의존성으로 포함되어 있습니다.
/// TraceKitViewModelLogger를 사용하여 고급 로깅 기능을 활용할 수 있습니다.
class ExampleViewModel5: ObservableObject, AsyncViewModelProtocol {
    @Published var state = State()
    var tasks: [CancelID: Task<Void, Never>] = [:]
    var effectQueue: [AsyncEffect<Action, CancelID>] = []
    var isProcessingEffects = false
    var timer: any AsyncTimer = SystemTimer()
    var actionObserver: ((Action) -> Void)?

    // 로깅 설정
    var isLoggingEnabled = true
    var logLevel: LogLevel = .debug

    // TraceKit 사용 (전역 기본 로거 사용)
    var logger: (any ViewModelLogger)? // nil이면 전역 로거 사용

    var stateChangeObserver: ((State, State) -> Void)?
    var effectObserver: ((AsyncEffect<Action, CancelID>) -> Void)?
    var performanceObserver: ((String, TimeInterval) -> Void)?

    struct State: Equatable, Sendable {}
    enum Action: Equatable, Sendable { case dummy }
    enum CancelID: Hashable, Sendable {}

    func transform(_: Void) -> [Action] { [] }
    func reduce(state _: inout State, action _: Action) -> [AsyncEffect<Action, CancelID>] { [] }

    // 특정 ViewModel에만 별도 로거를 설정하려면
    init() {
        // 방법 1: 전역 로거 사용 (권장)
        // logger = nil

        // 방법 2: 이 ViewModel만 별도 설정
        // Task { @MainActor in
        //     self.logger = TraceKitViewModelLogger()
        // }
    }
}

// MARK: - 6. 실전 예시: Calculator ViewModel

/// 실제 Calculator ViewModel에 로거를 적용한 예시
///
/// @AsyncViewModel 매크로를 사용하는 ViewModel은 자동으로 logger 프로퍼티를 가집니다.
/// 다음과 같이 사용할 수 있습니다:
///
/// ```swift
/// // 방법 1: 초기화 시 설정 (권장)
/// // ViewModel 클래스에 logger 프로퍼티를 직접 추가하거나,
/// // 초기화 후 즉시 설정
///
/// // 방법 2: 전역 기본 로거 사용 (가장 간단)
/// // LoggerConfiguration.setLogger(TraceKitViewModelLogger())
/// // 이렇게 하면 모든 ViewModel이 자동으로 해당 로거를 사용
///
/// // 방법 3: 프로토콜 확장으로 헬퍼 추가
/// // AsyncViewModelProtocol에 대한 extension으로 공통 기능 추가
/// ```

// MARK: - 사용 예시

/// 앱 초기화 시 로거 설정 예시
@MainActor
class LoggerSetupExample {
    static func setupLogging() {
        // 예시 1: 전역 기본 로거로 콘솔 로거 설정 (가장 권장)
        LoggerConfiguration.setLogger(ConsoleLogger())
        // 이후 모든 ViewModel이 자동으로 ConsoleLogger를 사용

        // 예시 2: 프로덕션 환경에서 로깅 비활성화
        #if RELEASE
            LoggerConfiguration.disableLogging()
        #endif

        // 예시 3: 개발 환경에서 os.log 사용
        #if DEBUG
            LoggerConfiguration.setLogger(OSLogViewModelLogger(subsystem: "com.myapp.calculator"))
        #endif
    }

    #if canImport(TraceKit)
        // TraceKit 통합 예시 (권장)
        static func setupTraceKit() {
            // TraceKit 초기화 (AppDelegate에서 한 번만 수행)
            Task { @TraceKitActor in
                await TraceKitBuilder
                    .debug()
                    .buildAsShared()
            }

            // AsyncViewModel에 전역 로거 설정
            Task { @MainActor in
                let logger = TraceKitViewModelLogger()
                LoggerConfiguration.setLogger(logger)

                // 이제 모든 ViewModel에서 자동으로 TraceKit 사용
            }
        }
    #endif
}
