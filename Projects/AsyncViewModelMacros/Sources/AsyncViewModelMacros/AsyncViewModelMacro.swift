//
//  AsyncViewModelMacro.swift
//  AsyncViewModelMacros
//
//  Created by 정준영 on 2025/12/17.
//

import AsyncViewModelCore

// MARK: - AsyncViewModel Macro

/// AsyncViewModel 프로토콜 채택 시 필요한 보일러플레이트 프로퍼티를 자동 생성하는 매크로
///
/// 이 매크로를 사용하면 다음 프로퍼티들이 자동으로 생성됩니다:
/// - `tasks`: 진행 중인 작업을 관리하는 딕셔너리
/// - `effectQueue`: Effect 직렬 처리를 위한 큐
/// - `isProcessingEffects`: Effect 처리 상태
/// - `actionObserver`: 디버깅/테스트를 위한 액션 관찰 훅
/// - `stateChangeObserver`: 상태 변경 관찰 훅
/// - `effectObserver`: Effect 실행 관찰 훅
/// - `performanceObserver`: 성능 메트릭 관찰 훅
/// - `timer`: AsyncTimer 인스턴스 (기본값: SystemTimer())
///
/// ## 생명주기 관리
///
/// ViewModel의 생명주기는 SwiftUI View의 `.onDisappear`에서 명시적으로 관리해야 합니다:
///
/// ```swift
/// struct MyView: View {
///     @StateObject private var viewModel = MyViewModel()
///
///     var body: some View {
///         // ... UI 코드 ...
///         .onDisappear {
///             // 필요한 정리 작업 수행
///             viewModel.send(.cleanup)
///         }
///     }
/// }
/// ```
///
/// ## 사용 예시
///
/// ```swift
/// @AsyncViewModel
/// public final class MyViewModel: ObservableObject {
///     public enum Input: Sendable { ... }
///     public enum Action: Equatable & Sendable { ... }
///     public struct State: Equatable & Sendable { ... }
///     public enum CancelID: Hashable & Sendable { ... }
///
///     @Published public var state: State = State()
///
///     public func transform(_ input: Input) -> [Action] { ... }
///     public func reduce(state: inout State, action: Action) -> [AsyncEffect<Action, CancelID>] { ... }
/// }
/// ```
///
/// 매크로가 자동으로 모든 멤버에 `@MainActor`를 추가하므로, 클래스나 멤버에 별도로 명시할 필요가 없습니다.
///
/// ## 매크로 확장 결과
///
/// 위 코드는 다음과 같이 확장됩니다:
///
/// ```swift
/// @MainActor
/// public final class MyViewModel: ObservableObject {
///     // ... 사용자 정의 코드 ...
///
///     // 매크로가 생성한 프로퍼티들
///     public var tasks: [CancelID: Task<Void, Never>] = [:]
///     public var effectQueue: [AsyncEffect<Action, CancelID>] = []
///     public var isProcessingEffects: Bool = false
///     public var actionObserver: ((Action) -> Void)? = nil
///     public var stateChangeObserver: ((State, State) -> Void)? = nil
///     public var effectObserver: ((AsyncEffect<Action, CancelID>) -> Void)? = nil
///     public var performanceObserver: ((String, TimeInterval) -> Void)? = nil
///     public var timer: any AsyncTimer = SystemTimer()
/// }
///
/// @MainActor
/// extension MyViewModel: AsyncViewModelProtocol {}
/// ```
///
/// ## 로깅 설정
///
/// ViewModel별 로깅을 컴파일 타임에 설정할 수 있습니다:
///
/// ```swift
/// // 기본 설정 (모든 로깅 활성화, shared Logger 사용)
/// @AsyncViewModel
/// final class MyViewModel: ObservableObject { ... }
///
/// // 로깅 완전 비활성화
/// @AsyncViewModel(logging: .disabled)
/// final class NoisyViewModel: ObservableObject { ... }
///
/// // State 변경 로그만 제외 (가장 시끄러운 로그)
/// @AsyncViewModel(logging: .noStateChanges)
/// final class FrequentUpdateViewModel: ObservableObject { ... }
///
/// // 에러만 로깅
/// @AsyncViewModel(logging: .minimal)
/// final class PerformanceCriticalViewModel: ObservableObject { ... }
///
/// // 커스텀 카테고리 설정
/// @AsyncViewModel(logging: .custom(categories: [.action, .error]))
/// final class CustomViewModel: ObservableObject { ... }
///
/// // 커스텀 카테고리 + 커스텀 Logger
/// @AsyncViewModel(logging: .custom(categories: [.action, .error], logger: .custom(DebugLogger())))
/// final class CustomLoggerViewModel: ObservableObject { ... }
///
/// // 특정 카테고리만 활성화
/// @AsyncViewModel(logging: .only(.error, .action))
/// final class SelectiveViewModel: ObservableObject { ... }
///
/// // 특정 카테고리 제외
/// @AsyncViewModel(logging: .excluding(.stateChange, .stateDiff))
/// final class ExcludingViewModel: ObservableObject { ... }
/// ```
///
/// ## Logger 설정 (logging 파라미터에 통합)
///
/// Logger는 ViewModelLoggingMode에 포함되어 있습니다:
///
/// ```swift
/// // 전역 shared Logger 사용 (기본값)
/// @AsyncViewModel(logging: .enabled)
/// final class HomeViewModel: ObservableObject { ... }
///
/// // 해당 ViewModel에서만 커스텀 Logger 사용
/// @AsyncViewModel(logging: .enabled(.custom(DebugLogger())))
/// final class DebugViewModel: ObservableObject { ... }
///
/// // minimal 모드에서 커스텀 Logger 사용
/// @AsyncViewModel(logging: .minimal(.custom(TraceKitLogger())))
/// final class MinimalDebugViewModel: ObservableObject { ... }
/// ```
///
/// ## 로깅 옵션 설정
///
/// ViewModel별로 로깅 옵션을 지정할 수 있습니다 (전역 설정 대신 사용):
///
/// ```swift
/// // 전역 설정 사용 (기본값)
/// @AsyncViewModel
/// final class DefaultViewModel: ObservableObject { ... }
///
/// // 특정 ViewModel만 compact 포맷 사용
/// @AsyncViewModel(format: .compact)
/// final class CompactViewModel: ObservableObject { ... }
///
/// // 특정 ViewModel만 warning 이상 로깅
/// @AsyncViewModel(minimumLevel: .warning)
/// final class QuietViewModel: ObservableObject { ... }
///
/// // 여러 옵션 조합
/// @AsyncViewModel(
///     logging: .enabled,
///     format: .detailed,
///     minimumLevel: .info,
///     stateDiffOnly: true,
///     groupEffects: true
/// )
/// final class CustomOptionsViewModel: ObservableObject { ... }
///
/// // 커스텀 Logger와 옵션 조합
/// @AsyncViewModel(
///     logging: .enabled(.custom(DebugLogger())),
///     format: .detailed
/// )
/// final class FullCustomViewModel: ObservableObject { ... }
/// ```
///
/// 전역 설정은 AppDelegate에서 AsyncViewModelConfiguration을 통해 합니다:
///
/// ```swift
/// // AppDelegate에서 설정
/// let config = AsyncViewModelConfiguration.shared
/// config.configure(format: .detailed)
/// config.configure(minimumLevel: .info)
/// config.changeLogger(TraceKitLogger())
/// config.addInterceptors([AnalyticsInterceptor(), DebugInterceptor()])
/// ```
///
/// ## 주의사항
///
/// - 이 매크로는 `class`에만 적용할 수 있습니다.
/// - 매크로가 자동으로 모든 메서드와 프로퍼티에 `@MainActor`를 추가합니다.
/// - `ObservableObject` 프로토콜을 준수해야 합니다.
/// - `Input`, `Action`, `State`, `CancelID` 타입을 정의해야 합니다.
/// - `@Published var state: State` 프로퍼티를 선언해야 합니다.
/// - `transform(_:)`, `reduce(state:action:)` 메서드를 구현해야 합니다.
@attached(member, names:
    named(tasks),
    named(effectQueue),
    named(isProcessingEffects),
    named(actionObserver),
    named(stateChangeObserver),
    named(effectObserver),
    named(performanceObserver),
    named(timer),
    named(loggingConfig))
@attached(memberAttribute)
@attached(extension, conformances: AsyncViewModelProtocol)
public macro AsyncViewModel(
    logging: ViewModelLoggingMode = .enabled,
    format: LogFormat? = nil,
    stateDiffOnly: Bool? = nil,
    groupEffects: Bool? = nil
) = #externalMacro(
    module: "AsyncViewModelMacrosImpl",
    type: "AsyncViewModelMacroImpl"
)
