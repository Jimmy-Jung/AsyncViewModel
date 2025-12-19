//
// ReuableViewProtocol.swift
// UI+Extension
//
//  Created by 정준영 on 2025/8/3.
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
