//
//  LogKit
//
//  Created by RahulMac on 10/03/26.
//

import Foundation

// MARK: - LogEntry

public struct LogEntry {
    public let id: UUID
    public let level: LogLevel
    public let message: String
    public let category: String
    public let file: String
    public let function: String
    public let line: Int
    public let timestamp: Date

    init(
        level: LogLevel,
        message: String,
        category: String,
        file: String,
        function: String,
        line: Int
    ) {
        self.id        = UUID()
        self.level     = level
        self.message   = message
        self.category  = category
        self.file      = file
        self.function  = function
        self.line      = line
        self.timestamp = Date()
    }

    /// The filename without the full path (e.g. "HomeViewModel.swift")
    public var fileName: String {
        URL(fileURLWithPath: file).lastPathComponent
    }

    /// A formatted string ready for printing to the console.
    public var formatted: String {
        let time = LogEntry.timeFormatter.string(from: timestamp)
        return "\(level.emoji) [\(time)] [\(level.label)] [\(category)] \(fileName):\(line) → \(message)"
    }

    private static let timeFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "HH:mm:ss.SSS"
        return f
    }()
}
