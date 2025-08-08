//
//  UIScrollView+Extension.swift
//  UI+Extension
//
//  Created by 정준영 on 2025/8/3.
//

import UIKit

public extension UIScrollView {
    enum ScrollDirection {
        case top
        case center
        case bottom
    }
}

public extension UIExtension where Self: UIScrollView {
    func scroll(to direction: ScrollDirection) {
        DispatchQueue.main.async {
            switch direction {
            case .top:
                self.scrollToTop()
            case .center:
                self.scrollToCenter()
            case .bottom:
                self.scrollToBottom()
            }
        }
    }

    private func scrollToTop() {
        setContentOffset(.zero, animated: true)
    }

    private func scrollToCenter() {
        let centerOffset = CGPoint(x: 0, y: (contentSize.height - bounds.size.height) / 2)
        setContentOffset(centerOffset, animated: true)
    }

    private func scrollToBottom() {
        let bottomOffset = CGPoint(x: 0, y: contentSize.height - bounds.size.height + contentInset.bottom)
        if bottomOffset.y > 0 {
            setContentOffset(bottomOffset, animated: true)
        }
    }
}
