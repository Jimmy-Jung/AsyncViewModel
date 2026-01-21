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
        configureTraceKit()
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

    // MARK: - TraceKit Configuration

    private func configureTraceKit() {
        Task { @TraceKitActor in
            await TraceKitBuilder()
                .addOSLog(
                    subsystem: "com.jimmy.AsyncViewModel",
                    minLevel: .verbose
                )
                .with(configuration: .debug)
                .withDefaultSanitizer()
                .applyLaunchArguments()
                .buildAsShared()

            TraceKit.info("✅ TraceKit initialized with OSLog")
        }
    }

    // MARK: - AsyncViewModel Configuration

    private func configureAsyncViewModel() {
        let config = AsyncViewModelConfiguration.shared

        config.configure(actionFormat: .detailed)
        config.configure(stateFormat: .detailed)
        config.configure(effectFormat: .detailed)

        config.changeLogger(TraceKitViewModelLogger())

        TraceKit.info("✅ AsyncViewModel configured with TraceKit logging")
    }
}
