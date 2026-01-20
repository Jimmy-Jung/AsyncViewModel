//
//  ViewModelInterceptor.swift
//  AsyncViewModel
//
//  Created by jimmy on 2025/01/20.
//

import Foundation

// MARK: - ViewModelInterceptor

/// 로그 이벤트를 가로채서 처리하는 프로토콜
///
/// Interceptor는 Logger와 별개로 동작하며, 로그 이벤트를 가로채서
/// 분석, 모니터링, 디버깅 등 다양한 용도로 활용할 수 있습니다.
///
/// ## 사용 예시
///
/// ```swift
/// struct AnalyticsInterceptor: ViewModelInterceptor {
///     var id: String { "analytics" }
///
///     func intercept(_ event: LogEvent, viewModel: String, ...) {
///         if case .action(let action, _) = event {
///             Analytics.track("vm_action", ["viewModel": viewModel, "action": action])
///         }
///     }
/// }
/// ```
@MainActor
public protocol ViewModelInterceptor: Sendable {
    /// Interceptor 식별자
    ///
    /// 중복 등록 방지 및 특정 Interceptor 제거 시 사용됩니다.
    var id: String { get }

    /// 로그 이벤트를 가로채서 처리합니다.
    ///
    /// - Parameters:
    ///   - event: 로그 이벤트
    ///   - viewModel: ViewModel 이름
    ///   - file: 파일 경로
    ///   - function: 함수 이름
    ///   - line: 라인 번호
    func intercept(
        _ event: LogEvent,
        viewModel: String,
        file: String,
        function: String,
        line: Int
    )
}
