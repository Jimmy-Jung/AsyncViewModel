//
//  UIView+Extension.swift
//  UI+Extension
//
//  Created by 정준영 on 2025/8/3.
//

import UIKit

public protocol UIExtension {}

extension UIView: UIExtension {}

public extension UIExtension where Self: UIView {
    @discardableResult
    func cornerRadius(_ radius: CGFloat) -> Self {
        self.layer.cornerRadius = radius
        return self
    }

    @discardableResult
    func isUserInteractionEnabled(_ bool: Bool) -> Self {
        self.isUserInteractionEnabled = bool
        return self
    }

    @discardableResult
    func backgroundColor(_ color: UIColor) -> Self {
        self.backgroundColor = color
        return self
    }

    @discardableResult
    func clipsToBounds(_ bool: Bool) -> Self {
        self.clipsToBounds = bool
        return self
    }

    @discardableResult
    func contentMode(_ contentMode: UIView.ContentMode) -> Self {
        self.contentMode = contentMode
        return self
    }

    @discardableResult
    func isHidden(_ bool: Bool) -> Self {
        self.isHidden = bool
        return self
    }

    @discardableResult
    func addSubView(_ view: UIView) -> Self {
        self.addSubview(view)
        return self
    }

    @discardableResult
    func addSubviews(_ views: UIView...) -> Self {
        views.forEach { addSubview($0) }
        return self
    }

    @discardableResult
    func setBorder(color: UIColor, width: CGFloat) -> Self {
        self.layer.borderColor = color.cgColor
        self.layer.borderWidth = width
        return self
    }

    @discardableResult
    func setBorderRadius(_ radius: CGFloat) -> Self {
        self.layer.cornerRadius = radius
        self.layer.masksToBounds = true
        return self
    }

    @discardableResult
    func alpha(_ alpha: CGFloat) -> Self {
        self.alpha = alpha
        return self
    }

    @discardableResult
    func tag(_ value: Int) -> Self {
        self.tag = value
        return self
    }

    @discardableResult
    func accessibilityIdentifier(_ identifier: String) -> Self {
        self.accessibilityIdentifier = identifier
        return self
    }
}
