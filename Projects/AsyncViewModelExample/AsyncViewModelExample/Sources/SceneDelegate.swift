//
//  SceneDelegate.swift
//  AsyncViewModelExample
//
//  Created by jimmy on 2025/12/29.
//

import SwiftUI
import TraceKit
import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    var window: UIWindow?

    func scene(_ scene: UIScene, willConnectTo _: UISceneSession, options _: UIScene.ConnectionOptions) {
        guard let windowScene = (scene as? UIWindowScene) else { return }

        // Scene이 연결될 때 로그
        TraceKit.info("Scene connected", category: "Lifecycle")

        let window = UIWindow(windowScene: windowScene)

        // SwiftUI 메인 메뉴 표시
        let mainMenuView = MainMenuView()
        let hostingController = UIHostingController(rootView: mainMenuView)
        let navigationController = UINavigationController(rootViewController: hostingController)

        window.rootViewController = navigationController
        self.window = window
        window.makeKeyAndVisible()
    }
}
