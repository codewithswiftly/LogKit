//
//  LogLevel.swift
//  LogKit
//
//  Created by Rahul Dasgupta on 02/08/25.
//  © 2026 Rahul Dasgupta. All rights reserved.
//


import Foundation

// MARK: - LogLevel

public enum LogLevel: Int, Comparable, CaseIterable {
    case verbose = 0
    case debug   = 1
    case info    = 2
    case warning = 3
    case error   = 4

    var emoji: String {
        switch self {
        case .verbose: return "💬"
        case .debug:   return "🔧"
        case .info:    return "ℹ️"
        case .warning: return "⚠️"
        case .error:   return "❌"
        }
    }

    var label: String {
        switch self {
        case .verbose: return "VERBOSE"
        case .debug:   return "DEBUG"
        case .info:    return "INFO"
        case .warning: return "WARNING"
        case .error:   return "ERROR"
        }
    }

    public static func < (lhs: LogLevel, rhs: LogLevel) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}
