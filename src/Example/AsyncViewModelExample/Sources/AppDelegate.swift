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
        Task {
            await initializeTraceKit()
            configureAsyncViewModelLogger()
        }
    }

    @TraceKitActor
    private func initializeTraceKit() async {
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

    private func configureAsyncViewModelLogger() {
        ViewModelLoggerBuilder()
            .addLogger(TraceKitViewModelLogger())
            .withFormat(.compact)
            .withMinimumLevel(.info)
            .withStateDiffOnly(true)
            .withGroupEffects(true)
            .buildAsShared()

        TraceKit.info("✅ AsyncViewModel logger configured with builder pattern")
    }
}
