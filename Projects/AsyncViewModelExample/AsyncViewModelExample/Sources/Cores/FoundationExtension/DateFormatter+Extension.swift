//
//  DateFormatter+Extension.swift
//  Foundation+Extension
//
//  Created by jimmy on 2025/12/29.
//

import Foundation

// MARK: - DateFormatter

public extension DateFormatter {
    private static let iso8601WithTimeZoneFormatter: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        return formatter
    }()

    private static let yyyyMMddFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy.MM.dd"
        formatter.locale = Locale(identifier: "ko_KR")
        return formatter
    }()

    private static let displayDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy년 MM월 d일 HH:mm"
        formatter.locale = Locale(identifier: "ko_KR")
        return formatter
    }()

    static func iso8601StringToDate(_ string: String) -> Date? {
        return iso8601WithTimeZoneFormatter.date(from: string)
    }

    static func yyyyMMddString(from date: Date) -> String {
        return yyyyMMddFormatter.string(from: date)
    }

    static func displayString(from date: Date) -> String {
        return displayDateFormatter.string(from: date)
    }
}
