//
//  UIViewController+Extension.swift
//  UI+Extension
//
//  Created by 정준영 on 2025/8/3.
//

import SnapKit
import UIKit

extension UIViewController: UIExtension {
    public enum TransitionStyle {
        case changeRootVC
        /// Present without navigation
        case present
        /// Present full screen without navigation
        case presentFull
        /// Present with embedded navigation
        case presentNavigation
        /// Present full screen with embedded navigation
        case presentFullNavigation
        /// Navigation push
        case pushNavigation
    }
}

public extension UIExtension where Self: UIViewController {
    /// Storyboard Transition
    /// - Parameters:
    ///   - storyboard: Storyboard's name
    ///   - viewController: ViewController's Meta Type
    ///   - style: Transition Style
    func transition<T: UIViewController>(storyboard: String, viewController: T.Type, style: TransitionStyle, animated: Bool = true, preprocessViewController: ((_ vc: T) -> Void)? = nil) {
        let sb = UIStoryboard(name: storyboard, bundle: nil)
        guard let vc = sb.instantiateViewController(withIdentifier: viewController.identifier) as? T else {
            fatalError("There is a problem with making an instantiateViewController. The identifier may be incorrect.")
        }
        transition(viewController: vc, style: style, animated: animated, preprocessViewController: preprocessViewController)
    }

    /// ViewController Transition
    /// - Parameters:
    ///   - vc: ViewController Instance
    ///   - style: Transition Style
    func transition<T: UIViewController>(viewController vc: T, style: TransitionStyle, animated: Bool = true, preprocessViewController: ((_ vc: T) -> Void)? = nil) {
        preprocessViewController?(vc)
        switch style {
        case .changeRootVC:
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let window = windowScene.windows.first
            {
                window.rootViewController = vc
            } else {
                fatalError("Unable to find a valid window scene")
            }
        case .present:
            present(vc, animated: animated)
        case .presentFull:
            vc.modalPresentationStyle = .fullScreen
            present(vc, animated: animated)
        case .presentNavigation:
            let nav = UINavigationController(rootViewController: vc)
            present(nav, animated: animated)
        case .presentFullNavigation:
            let nav = UINavigationController(rootViewController: vc)
            nav.modalPresentationStyle = .fullScreen
            present(nav, animated: animated)
        case .pushNavigation:
            if let navController = navigationController {
                navController.pushViewController(vc, animated: animated)
            } else {
                fatalError("Navigation controller is nil, cannot push view controller")
            }
        }
    }
}
