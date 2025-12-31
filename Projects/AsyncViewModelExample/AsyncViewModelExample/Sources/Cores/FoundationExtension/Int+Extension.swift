//
//  Int+Extension.swift
//  Foundation+Extension
//
//  Created by jimmy on 2025/12/29.
//

import Foundation

public extension Int {
    /// 숫자를 세 자리마다 콤마가 있는 문자열로 변환합니다.
    func formatted() -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        return formatter.string(from: NSNumber(value: self)) ?? ""
    }
}
