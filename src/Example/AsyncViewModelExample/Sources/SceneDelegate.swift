//
//  SceneDelegate.swift
//  AsyncViewModelExample
//
//  Created by 정준혁 on 2025/12/17
//

import SwiftUI
import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    
    var window: UIWindow?
    
    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = (scene as? UIWindowScene) else { return }
        
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
