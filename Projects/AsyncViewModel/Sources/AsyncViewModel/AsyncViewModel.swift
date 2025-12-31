//
//  AsyncViewModel.swift
//  AsyncViewModel
//
//  Created by jimmy on 2025/12/29.
//

// MARK: - AsyncViewModel Module

// AsyncViewModel 통합 모듈
//
// Core 기능과 매크로를 모두 포함하는 단일 모듈입니다.
// 이 모듈 하나만 import하면 AsyncViewModel의 모든 기능을 사용할 수 있습니다.
//
// ## 사용법
//
// ```swift
// import AsyncViewModel
//
// @AsyncViewModel
// @MainActor
// final class MyViewModel: ObservableObject {
//     @Published var state: State = .init()
//
//     func reduce(state: inout State, action: Action) -> [AsyncEffect<Action, CancelID>] {
//         // 상태 변경 및 Effect 반환
//     }
// }
// ```
//
// ## 포함된 기능
//
// ### Core 기능 (AsyncViewModelCore)
// - `AsyncViewModelProtocol`: ViewModel의 핵심 프로토콜
// - `AsyncEffect`: 비동기 작업 표현
// - `AsyncOperation`: Effect 실행 및 관리
// - `AsyncTestStore`: 테스트 지원
// - `SendableError`: Sendable 에러 래퍼
//
// ### 매크로 기능 (AsyncViewModelMacros)
// - `@AsyncViewModel`: 보일러플레이트 자동 생성 매크로
//
// ## 마이그레이션
//
// 기존 코드에서 다음과 같이 변경하세요:
//
// Before:
// ```swift
// import AsyncViewModelKit
// import AsyncViewModelMacros
// ```
//
// After:
// ```swift
// import AsyncViewModel  // 단일 import로 통합!
// ```

// Core 기능 re-export
@_exported import AsyncViewModelCore

// 매크로 re-export
@_exported import AsyncViewModelMacros
