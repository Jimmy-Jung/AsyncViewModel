//
// ReuableViewProtocol.swift
// UI+Extension
//
//  Created by jimmy on 2025/12/29.
//

import UIKit

public protocol ReusableViewProtocol {
    static var identifier: String { get }
    var identifier: String { get }
}

public extension ReusableViewProtocol {
    static var identifier: String { return String(describing: self) }
    var identifier: String { return Self.identifier }
}

extension UIViewController: ReusableViewProtocol {}
extension UIView: ReusableViewProtocol {}
