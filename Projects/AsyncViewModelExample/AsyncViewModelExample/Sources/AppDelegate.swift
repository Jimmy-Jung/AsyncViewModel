//
//  AppDelegate.swift
//  AsyncViewModelExample
//
//  Created by jimmy on 2025/12/18.
//

import AsyncViewModel
import TraceKit
import UIKit

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    func application(
        _: UIApplication,
        didFinishLaunchingWithOptions _: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        // AsyncViewModel 전역 로깅 설정
        configureAsyncViewModel()

        return true
    }

    // MARK: UISceneSession Lifecycle

    func application(
        _: UIApplication,
        configurationForConnecting connectingSceneSession: UISceneSession,
        options _: UIScene.ConnectionOptions
    ) -> UISceneConfiguration {
        return UISceneConfiguration(
            name: "Default Configuration",
            sessionRole: connectingSceneSession.role
        )
    }

    func application(
        _: UIApplication,
        didDiscardSceneSessions _: Set<UISceneSession>
    ) {}

    // MARK: - AsyncViewModel Configuration

    private func configureAsyncViewModel() {
        let config = AsyncViewModelConfiguration.shared

        // 1. 전역 로깅 옵션 설정 (모든 ViewModel에 적용됨)
        config.configure(actionFormat: .detailed)
        config.configure(stateFormat: .detailed)
        config.configure(effectFormat: .detailed)

        // 2. Logger 변경 (선택사항, 기본은 OSLogViewModelLogger)
        // config.changeLogger(TraceKitViewModelLogger())

        // 3. Interceptor 등록 (선택사항)
        // config.addInterceptors([
        //     AnalyticsInterceptor(),
        //     DebugInterceptor()
        // ])

        print("✅ AsyncViewModel configured with global logging options")
    }
}

// MARK: - Usage Examples

//
// ## 앱 시작단 전역 설정 (AppDelegate)
//
// let config = AsyncViewModelConfiguration.shared
// config.configure(format: .detailed)
// config.configure(groupEffects: true)
//
// ## 특정 ViewModel에서 별도 설정 (매크로 파라미터)
//
// @AsyncViewModel
// final class MyViewModel: ObservableObject {
//     // 기본: 전역 설정 사용
// }
//
// @AsyncViewModel(logging: .noStateChanges)
// final class FrequentUpdateViewModel: ObservableObject {
//     // State 변경 로그 제외, 나머지는 전역 설정 사용
// }
//
// @AsyncViewModel(format: .compact)
// final class CompactLogViewModel: ObservableObject {
//     // 이 ViewModel만 compact 포맷 사용
// }
//
// @AsyncViewModel(format: .detailed, groupEffects: true)
// final class FullCustomViewModel: ObservableObject {
//     // 모든 옵션을 이 ViewModel에서 직접 설정
// }
//
// ## Logger 설정 (logging 파라미터에 통합됨)
//
// @AsyncViewModel(logging: .enabled(.custom(DebugLogger())))
// final class DebugViewModel: ObservableObject {
//     // 커스텀 Logger 사용
// }
//
// @AsyncViewModel(logging: .enabled(.custom(DebugLogger())), format: .detailed)
// final class DebugWithOptionsViewModel: ObservableObject {
//     // 커스텀 Logger와 포맷 조합
// }
//
// @AsyncViewModel(logging: .minimal(.custom(TraceKitLogger())))
// final class MinimalDebugViewModel: ObservableObject {
//     // minimal 모드에서 커스텀 Logger 사용
// }
