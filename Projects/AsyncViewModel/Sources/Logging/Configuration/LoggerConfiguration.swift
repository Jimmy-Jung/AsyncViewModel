//
//  LoggerConfiguration.swift
//  AsyncViewModel
//
//  Created by jimmy on 2025/12/29.
//

import Foundation

@MainActor
public enum LoggerConfiguration {
    private static var _logger: any ViewModelLogger = OSLogViewModelLogger()

    public static var logger: any ViewModelLogger {
        _logger
    }

    public static func setLogger(_ logger: any ViewModelLogger) {
        _logger = logger
    }

    public static func disableLogging() {
        _logger = NoOpLogger()
    }

    public static func resetToDefault() {
        _logger = OSLogViewModelLogger()
    }
}
