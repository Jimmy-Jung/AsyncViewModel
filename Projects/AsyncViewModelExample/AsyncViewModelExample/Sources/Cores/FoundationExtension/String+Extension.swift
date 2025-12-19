//
//  String+Extension.swift
//  Foundation+Extension
//
//  Created by 정준영 on 2025/8/3.
//

import Foundation

public extension String {
    /// ISO8601 형식의 날짜 문자열을 "yyyy.MM.dd" 형식으로 변환합니다.
    func toFormattedDate() -> String? {
        guard let date = DateFormatter.iso8601StringToDate(self) else {
            return nil
        }
        return DateFormatter.displayString(from: date)
    }
}
