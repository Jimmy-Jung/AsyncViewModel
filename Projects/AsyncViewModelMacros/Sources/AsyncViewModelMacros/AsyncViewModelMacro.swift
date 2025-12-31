//
//  AsyncViewModelMacro.swift
//  AsyncViewModelMacros
//
//  Created by jimmy on 2025/12/29.
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
/// 전역 로거를 통해 모든 ViewModel의 로깅을 제어합니다:
///
/// ```swift
/// // AppDelegate에서 설정
/// var logger = TraceKitViewModelLogger()
/// logger.options.format = .compact
/// LoggerConfiguration.setLogger(logger)
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
    named(timer))
@attached(memberAttribute)
@attached(extension, conformances: AsyncViewModelProtocol)
public macro AsyncViewModel() = #externalMacro(
    module: "AsyncViewModelMacrosImpl",
    type: "AsyncViewModelMacroImpl"
)
