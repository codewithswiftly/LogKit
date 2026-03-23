//
//  LogKit
//
//  Created by RahulMac on 10/03/26.
//

import Foundation

// MARK: - LogFilter

/// Filters a collection of LogEntry values by level, category, or keyword.
///
/// Example:
///   let errors = LogFilter.filter(entries, by: .level(.error))
///   let networkLogs = LogFilter.filter(entries, by: .category("Networking"))
///   let combined = LogFilter.filter(entries, by: .level(.warning), .category("Auth"))
public enum LogFilter {

    public enum Criteria {
        case level(LogLevel)
        case minimumLevel(LogLevel)
        case category(String)
        case keyword(String)
        case dateRange(from: Date, to: Date)
    }

    /// Returns entries matching all provided criteria.
    public static func filter(_ entries: [LogEntry], by criteria: Criteria...) -> [LogEntry] {
        entries.filter { entry in
            criteria.allSatisfy { matches(entry: entry, criteria: $0) }
        }
    }

    /// Returns entries matching a single criteria.
    public static func filter(_ entries: [LogEntry], by criteria: Criteria) -> [LogEntry] {
        entries.filter { matches(entry: $0, criteria: criteria) }
    }

    // MARK: - Private

    private static func matches(entry: LogEntry, criteria: Criteria) -> Bool {
        switch criteria {
        case .level(let level):
            return entry.level == level

        case .minimumLevel(let level):
            return entry.level >= level

        case .category(let category):
            return entry.category.lowercased() == category.lowercased()

        case .keyword(let keyword):
            return entry.message.localizedCaseInsensitiveContains(keyword)

        case .dateRange(let from, let to):
            return entry.timestamp >= from && entry.timestamp <= to
        }
    }
}
