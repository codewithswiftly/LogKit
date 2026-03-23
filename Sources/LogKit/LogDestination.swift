//
//  LogKit
//
//  Created by RahulMac on 10/03/26.
//

import Foundation

// MARK: - LogDestination

/// A destination receives log entries and decides what to do with them.
/// Conform to this protocol to create custom outputs (file, analytics, remote, etc.)
public protocol LogDestination: AnyObject {
    var minimumLevel: LogLevel { get set }
    func receive(_ entry: LogEntry)
}

// MARK: - ConsoleDestination

/// Prints log entries to the Xcode console.
public final class ConsoleDestination: LogDestination {

    public var minimumLevel: LogLevel

    public init(minimumLevel: LogLevel = .verbose) {
        self.minimumLevel = minimumLevel
    }

    public func receive(_ entry: LogEntry) {
        print(entry.formatted)
    }
}

// MARK: - FileDestination

/// Writes log entries to a text file on disk.
public final class FileDestination: LogDestination {

    public var minimumLevel: LogLevel
    private let fileURL: URL
    private let fileManager = FileManager.default

    /// - Parameter fileURL: The file path to write logs to. Created if it doesn't exist.
    public init(fileURL: URL, minimumLevel: LogLevel = .warning) {
        self.fileURL      = fileURL
        self.minimumLevel = minimumLevel
        createFileIfNeeded()
    }

    public func receive(_ entry: LogEntry) {
        let line = entry.formatted + "\n"
        guard let data = line.data(using: .utf8) else { return }

        if let handle = try? FileHandle(forWritingTo: fileURL) {
            handle.seekToEndOfFile()
            handle.write(data)
            try? handle.close()
        }
    }

    /// Returns all log entries written to the file as a single string.
    public func readLogs() -> String {
        (try? String(contentsOf: fileURL, encoding: .utf8)) ?? ""
    }

    /// Deletes the log file contents.
    public func clearLogs() {
        try? "".write(to: fileURL, atomically: true, encoding: .utf8)
    }

    private func createFileIfNeeded() {
        guard !fileManager.fileExists(atPath: fileURL.path) else { return }
        fileManager.createFile(atPath: fileURL.path, contents: nil)
    }
}

// MARK: - MemoryDestination

/// Stores log entries in memory. Useful for displaying logs inside the app or in tests.
public final class MemoryDestination: LogDestination {

    public var minimumLevel: LogLevel
    public private(set) var entries: [LogEntry] = []
    private let maxEntries: Int

    /// - Parameter maxEntries: Maximum number of entries to keep. Oldest are dropped when exceeded.
    public init(minimumLevel: LogLevel = .verbose, maxEntries: Int = 500) {
        self.minimumLevel = minimumLevel
        self.maxEntries   = maxEntries
    }

    public func receive(_ entry: LogEntry) {
        entries.append(entry)
        if entries.count > maxEntries {
            entries.removeFirst()
        }
    }

    /// Returns only entries matching the given level.
    public func entries(for level: LogLevel) -> [LogEntry] {
        entries.filter { $0.level == level }
    }

    /// Returns only entries matching the given category.
    public func entries(for category: String) -> [LogEntry] {
        entries.filter { $0.category == category }
    }

    /// Clears all stored entries.
    public func clear() {
        entries.removeAll()
    }
}
