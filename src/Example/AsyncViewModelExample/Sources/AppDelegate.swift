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
        // TraceKit 설정 및 AsyncViewModel과 통합
        setupTraceKit()

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

    // MARK: - TraceKit Setup

    private func setupTraceKit() {
        // TraceKit 초기화 (OSLog 사용)
        Task { @TraceKitActor in
            await TraceKitBuilder()
                .addOSLog(
                    subsystem: Bundle.main.bundleIdentifier ?? "com.asyncviewmodel.example",
                    minLevel: .verbose,
                    formatter: PrettyTraceFormatter.standard
                )
                .with(configuration: .debug)
                .withDefaultSanitizer()
                .applyLaunchArguments()
                .buildAsShared()

            await TraceKit.async.info("✅ TraceKit initialized successfully (OSLog)")
        }

        // AsyncViewModel에 TraceKit 연결 (초간결 로그 설정)
        Task { @MainActor in
            var logger = TraceKitViewModelLogger()

            // 프로덕션 환경: 최소한의 로그만
            logger.options.format = .compact
            logger.options.useSmartPerformanceThreshold = true // 🆕 스마트 임계값 활성화
            logger.options.showStateDiffOnly = true
            logger.options.groupEffects = true
            logger.options.showZeroPerformance = false
            logger.options.minimumLevel = .info // INFO 이상만 로깅 (DEBUG 숨김)

            LoggerConfiguration.setLogger(logger)

            TraceKit.info("✅ AsyncViewModel TraceKit logger configured (smart mode)")
        }
    }
}
