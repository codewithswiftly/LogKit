# LogKit

**Structured, filterable logging for iOS and macOS — built in pure Swift.**

![Swift](https://img.shields.io/badge/Swift-5.9+-F05138?style=flat&logo=swift)
![iOS](https://img.shields.io/badge/iOS-15%2B-007AFF?style=flat&logo=apple)
![macOS](https://img.shields.io/badge/macOS-12%2B-000000?style=flat&logo=apple)
![SPM](https://img.shields.io/badge/SPM-compatible-34C759?style=flat)
![License](https://img.shields.io/badge/license-MIT-blue?style=flat)

---

## What is LogKit?

LogKit replaces scattered `print()` calls with a structured logging system. Every log has a level, category, file, function, line number, and timestamp — so you always know where a message came from and why.

```swift
// Instead of this
print("User logged in")

// Use this
Log.info("User logged in")
// 💬 [14:32:01.245] [INFO] [App] HomeViewModel.swift:42 → User logged in
```

---

## Installation

In Xcode go to **File → Add Package Dependencies** and paste:

```
https://github.com/codewithswiftly/LogKit.git
```

Or in `Package.swift`:

```swift
.package(url: "https://github.com/codewithswiftly/LogKit.git", from: "1.0.0")
```

---

## Quick Start

### Global logger (simplest)

```swift
import LogKit

Log.verbose("Entering fetchUser()")
Log.debug("Cache hit for user ID 42")
Log.info("User logged in successfully")
Log.warning("Token expiring in 5 minutes")
Log.error("Network request failed: \(error.localizedDescription)")
```

### Per-feature logger (recommended)

```swift
// Create one logger per feature/module
let networkLogger  = Logger(category: "Networking").addDestination(ConsoleDestination())
let authLogger     = Logger(category: "Auth").addDestination(ConsoleDestination())
let paymentLogger  = Logger(category: "Payments").addDestination(ConsoleDestination())

networkLogger.info("Request started: GET /users")
authLogger.warning("Invalid token, refreshing...")
paymentLogger.error("Payment declined: \(error)")
```

---

## Log Levels

| Level | Emoji | Use for |
|---|---|---|
| `.verbose` | 💬 | Fine-grained flow, function entry/exit |
| `.debug` | 🔧 | Values, state during development |
| `.info` | ℹ️ | General app events and milestones |
| `.warning` | ⚠️ | Unexpected but recoverable situations |
| `.error` | ❌ | Failures that need attention |

---

## Destinations

Destinations control where logs go. Add as many as you need to a single logger.

### ConsoleDestination
Prints to the Xcode debug console.

```swift
let logger = Logger(category: "App")
    .addDestination(ConsoleDestination(minimumLevel: .debug))
```

### FileDestination
Writes logs to a file on disk — great for crash reporting or QA builds.

```swift
let logFile = FileManager.default
    .urls(for: .documentDirectory, in: .userDomainMask)[0]
    .appendingPathComponent("app.log")

let logger = Logger(category: "App")
    .addDestination(FileDestination(fileURL: logFile, minimumLevel: .warning))

// Read or clear the log file
let destination = FileDestination(fileURL: logFile)
print(destination.readLogs())
destination.clearLogs()
```

### MemoryDestination
Stores logs in memory — useful for showing an in-app log viewer or in tests.

```swift
let memory = MemoryDestination(maxEntries: 200)
let logger = Logger(category: "App").addDestination(memory)

// Access stored entries
let allLogs     = memory.entries
let onlyErrors  = memory.entries(for: .error)
let networkLogs = memory.entries(for: "Networking")
memory.clear()
```

### Multiple Destinations

```swift
let logger = Logger(category: "App")
    .addDestination(ConsoleDestination(minimumLevel: .debug))    // All logs to console
    .addDestination(FileDestination(fileURL: logFile, minimumLevel: .warning))  // Only warnings+ to file
```

---

## Filtering Logs

Use `LogFilter` to search and filter entries stored in `MemoryDestination`.

```swift
let entries = memory.entries

// By exact level
let errors = LogFilter.filter(entries, by: .level(.error))

// By minimum level (warning and above)
let serious = LogFilter.filter(entries, by: .minimumLevel(.warning))

// By category
let networkLogs = LogFilter.filter(entries, by: .category("Networking"))

// By keyword search
let timeouts = LogFilter.filter(entries, by: .keyword("timeout"))

// By date range
let recent = LogFilter.filter(entries, by: .dateRange(from: oneHourAgo, to: now))

// Multiple criteria combined (AND logic)
let networkErrors = LogFilter.filter(entries, by: .level(.error), .category("Networking"))
```

---

## Disabling Logging

```swift
// Disable a specific logger
logger.isEnabled = false

// Or set a higher minimum level to reduce noise in production
let console = ConsoleDestination(minimumLevel: .warning)
```

---

## Real World Example — Networking Layer

```swift
class NetworkManager {

    private let logger = Logger(category: "Networking")
        .addDestination(ConsoleDestination())

    func fetchUser(id: Int) async throws -> User {
        logger.info("Fetching user \(id)")

        do {
            let user: User = try await client.request(UserAPI.profile(id: id))
            logger.debug("Received user: \(user.name)")
            return user
        } catch {
            logger.error("Failed to fetch user \(id): \(error.localizedDescription)")
            throw error
        }
    }
}
```

---

## Project Structure

```
LogKit/
├── Sources/LogKit/
│   ├── LogLevel.swift         # Levels: verbose, debug, info, warning, error
│   ├── LogEntry.swift         # Data model for a single log line
│   ├── LogDestination.swift   # Protocol + Console, File, Memory destinations
│   ├── Logger.swift           # Logger class + Log global shorthand
│   └── LogFilter.swift        # Filter entries by level, category, keyword
└── Tests/LogKitTests/
    └── LogKitTests.swift
```

---

## Requirements

- iOS 15+ / macOS 12+
- Swift 5.9+
- Xcode 15+
- Zero dependencies

---

## License

MIT © 2026 Rahul Das Gupta
