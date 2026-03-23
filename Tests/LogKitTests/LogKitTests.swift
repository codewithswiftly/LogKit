//
//  LogKit
//
//  Created by RahulMac on 10/03/26.
//

import XCTest
@testable import LogKit

final class LogKitTests: XCTestCase {

    var logger: Logger!
    var memory: MemoryDestination!

    override func setUp() {
        super.setUp()
        memory = MemoryDestination()
        logger = Logger(category: "Test")
        logger.addDestination(memory)
    }

    override func tearDown() {
        memory.clear()
        logger = nil
        memory = nil
        super.tearDown()
    }

    // MARK: - LogLevel

    func test_logLevel_ordering() {
        XCTAssertLessThan(LogLevel.verbose, .debug)
        XCTAssertLessThan(LogLevel.debug,   .info)
        XCTAssertLessThan(LogLevel.info,    .warning)
        XCTAssertLessThan(LogLevel.warning, .error)
    }

    func test_logLevel_labels() {
        XCTAssertEqual(LogLevel.verbose.label, "VERBOSE")
        XCTAssertEqual(LogLevel.debug.label,   "DEBUG")
        XCTAssertEqual(LogLevel.info.label,    "INFO")
        XCTAssertEqual(LogLevel.warning.label, "WARNING")
        XCTAssertEqual(LogLevel.error.label,   "ERROR")
    }

    func test_logLevel_emojis_areNotEmpty() {
        LogLevel.allCases.forEach {
            XCTAssertFalse($0.emoji.isEmpty)
        }
    }

    // MARK: - LogEntry

    func test_logEntry_formattedContainsMessage() {
        let entry = LogEntry(level: .info, message: "Hello", category: "Test", file: "File.swift", function: "test()", line: 42)
        XCTAssertTrue(entry.formatted.contains("Hello"))
    }

    func test_logEntry_formattedContainsLevel() {
        let entry = LogEntry(level: .error, message: "Oops", category: "Test", file: "File.swift", function: "test()", line: 1)
        XCTAssertTrue(entry.formatted.contains("ERROR"))
    }

    func test_logEntry_fileNameStripsPath() {
        let entry = LogEntry(level: .info, message: "msg", category: "Test", file: "/Users/dev/project/HomeView.swift", function: "body", line: 10)
        XCTAssertEqual(entry.fileName, "HomeView.swift")
    }

    func test_logEntry_timestampIsRecent() {
        let entry = LogEntry(level: .info, message: "msg", category: "Test", file: "", function: "", line: 0)
        XCTAssertLessThan(Date().timeIntervalSince(entry.timestamp), 1.0)
    }

    // MARK: - Logger

    func test_logger_storesCategory() {
        XCTAssertEqual(logger.category, "Test")
    }

    func test_logger_logsInfo() {
        let exp = expectation(description: "log received")
        logger.info("Info message")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            XCTAssertEqual(self.memory.entries.count, 1)
            XCTAssertEqual(self.memory.entries.first?.level, .info)
            exp.fulfill()
        }
        wait(for: [exp], timeout: 1.0)
    }

    func test_logger_logsAllLevels() {
        let exp = expectation(description: "all levels logged")
        logger.verbose("v")
        logger.debug("d")
        logger.info("i")
        logger.warning("w")
        logger.error("e")

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            XCTAssertEqual(self.memory.entries.count, 5)
            exp.fulfill()
        }
        wait(for: [exp], timeout: 1.0)
    }

    func test_logger_disabled_doesNotLog() {
        let exp = expectation(description: "no logs")
        logger.isEnabled = false
        logger.info("This should not appear")

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            XCTAssertEqual(self.memory.entries.count, 0)
            exp.fulfill()
        }
        wait(for: [exp], timeout: 1.0)
    }

    func test_logger_minimumLevel_filtersLowerLevels() {
        let exp = expectation(description: "filtered")
        memory.minimumLevel = .warning
        logger.debug("Should be filtered")
        logger.info("Should be filtered")
        logger.warning("Should pass")
        logger.error("Should pass")

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            XCTAssertEqual(self.memory.entries.count, 2)
            exp.fulfill()
        }
        wait(for: [exp], timeout: 1.0)
    }

    // MARK: - MemoryDestination

    func test_memoryDestination_filtersByLevel() {
        let exp = expectation(description: "filtered by level")
        logger.info("Info")
        logger.error("Error")

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            XCTAssertEqual(self.memory.entries(for: .error).count, 1)
            XCTAssertEqual(self.memory.entries(for: .info).count, 1)
            exp.fulfill()
        }
        wait(for: [exp], timeout: 1.0)
    }

    func test_memoryDestination_filtersByCategory() {
        let exp = expectation(description: "filtered by category")
        logger.info("Test log")

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            XCTAssertEqual(self.memory.entries(for: "Test").count, 1)
            XCTAssertEqual(self.memory.entries(for: "Other").count, 0)
            exp.fulfill()
        }
        wait(for: [exp], timeout: 1.0)
    }

    func test_memoryDestination_respectsMaxEntries() {
        let exp = expectation(description: "max entries")
        let smallMemory = MemoryDestination(maxEntries: 3)
        let smallLogger = Logger(category: "Small").addDestination(smallMemory)

        smallLogger.info("1")
        smallLogger.info("2")
        smallLogger.info("3")
        smallLogger.info("4")
        smallLogger.info("5")

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            XCTAssertEqual(smallMemory.entries.count, 3)
            exp.fulfill()
        }
        wait(for: [exp], timeout: 1.0)
    }

    func test_memoryDestination_clear() {
        let exp = expectation(description: "cleared")
        logger.info("Will be cleared")

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.memory.clear()
            XCTAssertEqual(self.memory.entries.count, 0)
            exp.fulfill()
        }
        wait(for: [exp], timeout: 1.0)
    }

    // MARK: - LogFilter

    func test_filter_byLevel() {
        let entries = makeEntries()
        let errors = LogFilter.filter(entries, by: .level(.error))
        XCTAssertTrue(errors.allSatisfy { $0.level == .error })
    }

    func test_filter_byMinimumLevel() {
        let entries = makeEntries()
        let serious = LogFilter.filter(entries, by: .minimumLevel(.warning))
        XCTAssertTrue(serious.allSatisfy { $0.level >= .warning })
    }

    func test_filter_byCategory() {
        let entries = makeEntries()
        let network = LogFilter.filter(entries, by: .category("Networking"))
        XCTAssertTrue(network.allSatisfy { $0.category == "Networking" })
    }

    func test_filter_byKeyword() {
        let entries = makeEntries()
        let results = LogFilter.filter(entries, by: .keyword("timeout"))
        XCTAssertTrue(results.allSatisfy { $0.message.lowercased().contains("timeout") })
    }

    func test_filter_multipleCriteria() {
        let entries = makeEntries()
        let results = LogFilter.filter(entries, by: .level(.error), .category("Networking"))
        XCTAssertTrue(results.allSatisfy { $0.level == .error && $0.category == "Networking" })
    }

    // MARK: - Helpers

    private func makeEntries() -> [LogEntry] {
        [
            LogEntry(level: .info,    message: "Request started",  category: "Networking", file: "", function: "", line: 0),
            LogEntry(level: .error,   message: "Request timeout",  category: "Networking", file: "", function: "", line: 0),
            LogEntry(level: .warning, message: "Cache miss",       category: "Cache",      file: "", function: "", line: 0),
            LogEntry(level: .error,   message: "Auth failed",      category: "Auth",       file: "", function: "", line: 0),
            LogEntry(level: .debug,   message: "UI rendered",      category: "UI",         file: "", function: "", line: 0),
        ]
    }
}
