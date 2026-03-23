//
//  LogKit
//
//  Created by RahulMac on 10/03/26.
//

import Foundation

// MARK: - Logger

/// The core logging class. Create one per module or feature, or use `Log.shared` globally.
///
/// Example:
///   let logger = Logger(category: "Networking")
///   logger.info("Request started")
///   logger.error("Connection failed")
public final class Logger {

    // MARK: Properties

    public let category: String
    public var isEnabled: Bool = true

    private var destinations: [LogDestination] = []
    private let queue = DispatchQueue(label: "com.logkit.queue", qos: .utility)

    // MARK: Init

    public init(category: String) {
        self.category = category
    }

    // MARK: - Destinations

    /// Adds an output destination (console, file, memory, etc.)
    @discardableResult
    public func addDestination(_ destination: LogDestination) -> Self {
        destinations.append(destination)
        return self
    }

    /// Removes all destinations.
    public func clearDestinations() {
        destinations.removeAll()
    }

    // MARK: - Logging Methods

    /// Logs a verbose message — fine-grained details, usually only during development.
    public func verbose(
        _ message: String,
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) {
        log(message, level: .verbose, file: file, function: function, line: line)
    }

    /// Logs a debug message — useful during development and debugging.
    public func debug(
        _ message: String,
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) {
        log(message, level: .debug, file: file, function: function, line: line)
    }

    /// Logs an info message — general app flow and state changes.
    public func info(
        _ message: String,
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) {
        log(message, level: .info, file: file, function: function, line: line)
    }

    /// Logs a warning — something unexpected that isn't a failure yet.
    public func warning(
        _ message: String,
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) {
        log(message, level: .warning, file: file, function: function, line: line)
    }

    /// Logs an error — something went wrong and needs attention.
    public func error(
        _ message: String,
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) {
        log(message, level: .error, file: file, function: function, line: line)
    }

    // MARK: - Private

    private func log(
        _ message: String,
        level: LogLevel,
        file: String,
        function: String,
        line: Int
    ) {
        guard isEnabled else { return }

        let entry = LogEntry(
            level: level,
            message: message,
            category: category,
            file: file,
            function: function,
            line: line
        )

        // Pre-filter destinations on the current actor to avoid using Comparable in a nonisolated context
        let filteredDestinations = destinations.filter { level >= $0.minimumLevel }

        queue.async {
            for destination in filteredDestinations {
                destination.receive(entry)
            }
        }
    }
}

// MARK: - Log (Global Shared Logger)

/// A convenience global logger pre-configured with a console destination.
/// Use this for quick logging without setting up a full Logger instance.
///
/// Example:
///   Log.info("App launched")
///   Log.error("Payment failed")
public enum Log {

    public static let shared: Logger = {
        let logger = Logger(category: "App")
        logger.addDestination(ConsoleDestination())
        return logger
    }()

    public static func verbose(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        shared.verbose(message, file: file, function: function, line: line)
    }

    public static func debug(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        shared.debug(message, file: file, function: function, line: line)
    }

    public static func info(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        shared.info(message, file: file, function: function, line: line)
    }

    public static func warning(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        shared.warning(message, file: file, function: function, line: line)
    }

    public static func error(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        shared.error(message, file: file, function: function, line: line)
    }
}
