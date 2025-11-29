# GBLN Swift Bindings

[![Swift Package Manager](https://img.shields.io/badge/SPM-compatible-brightgreen)](https://swift.org/package-manager/)
[![iOS](https://img.shields.io/badge/iOS-15%2B-lightgrey)](https://www.apple.com/ios/)
[![macOS](https://img.shields.io/badge/macOS-12%2B-lightgrey)](https://www.apple.com/macos/)
[![watchOS](https://img.shields.io/badge/watchOS-8%2B-lightgrey)](https://www.apple.com/watchos/)
[![tvOS](https://img.shields.io/badge/tvOS-15%2B-lightgrey)](https://www.apple.com/tvos/)
[![Linux](https://img.shields.io/badge/Linux-x64%20%7C%20ARM64-blue)](https://www.kernel.org/)
[![License](https://img.shields.io/badge/License-Apache%202.0-blue.svg)](LICENSE)

Swift bindings for GBLN (Goblin Bounded Lean Notation) - the first **LLM-native serialisation format** designed for type safety and token efficiency.

## Features

- ✅ **Type-safe**: Inline type hints with parse-time validation
- ✅ **Memory-efficient**: 86% fewer tokens than JSON for AI contexts
- ✅ **Human-readable**: Text-based format with clear syntax
- ✅ **Git-friendly**: Meaningful diffs, ordered keys preserved
- ✅ **Cross-platform**: iOS, macOS, watchOS, tvOS, Linux
- ✅ **Swift-native**: Idiomatic Swift API with `throws`, `async/await`
- ✅ **Zero dependencies**: Standalone package

## Installation

### Swift Package Manager

Add GBLN to your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/gbln-org/gbln-swift.git", from: "1.0.0")
]
```

Or in Xcode:
1. File → Add Packages...
2. Enter: `https://github.com/gbln-org/gbln-swift.git`
3. Select version: `1.0.0` or later

## Quick Start

```swift
import GBLN

// Parse GBLN string
let user = try parse("user{id<u32>(123)name<s64>(Alice)active<b>(t)}")
// → ["user": ["id": 123, "name": "Alice", "active": true]]

// Serialise Swift value
let data = ["id": 123, "name": "Alice", "active": true]
let gbln = try toString(data)
// → "{id<i8>(123)name<s64>(Alice)active<b>(t)}"

// I/O format (MINI + XZ compression)
try writeIo(data, to: "data.io.gbln.xz")
let loaded = try readIo(from: "data.io.gbln.xz")
```

## GBLN Syntax

### Single Value

```gbln
age<i8>(25)
```

### Object (Multi-Value)

```gbln
user{
    id<u32>(12345)
    name<s64>(Alice)
    age<i8>(25)
    active<b>(t)
}
```

### Array (Homogeneous)

```gbln
tags<s16>[rust python swift]
```

### Comments

```gbln
:| This is a comment
user{
    id<u32>(123)  :| User ID
}
```

## Type System

| Category | Types | Example |
|----------|-------|---------|
| **Signed Int** | i8, i16, i32, i64 | `age<i8>(25)` |
| **Unsigned Int** | u8, u16, u32, u64 | `id<u32>(12345)` |
| **Float** | f32, f64 | `price<f32>(19.99)` |
| **String** | s2, s4, s8, s16, s32, s64, s128, s256, s512, s1024 | `name<s64>(Alice)` |
| **Boolean** | b | `active<b>(t)` or `active<b>(true)` |
| **Null** | n | `optional<n>()` or `optional<n>(null)` |

## API Reference

### Parsing

```swift
/// Parse GBLN string
func parse(_ gblnString: String) throws -> Any

/// Parse GBLN file
func parseFile(at path: String) throws -> Any

/// Parse GBLN file (async)
func parseFileAsync(at path: String) async throws -> Any
```

### Serialisation

```swift
/// Serialise to MINI GBLN (compact)
func toString(_ value: Any, mini: Bool = true) throws -> String

/// Serialise to pretty-printed GBLN
func toStringPretty(_ value: Any, indent: Int = 2) throws -> String
```

### I/O Operations

```swift
/// Write I/O format file
func writeIo(_ value: Any, to path: String, config: GblnConfig = .io) throws

/// Read I/O format file
func readIo(from path: String) throws -> Any

/// Async variants
func writeIoAsync(_ value: Any, to path: String, config: GblnConfig = .io) async throws
func readIoAsync(from path: String) async throws -> Any
```

### Configuration

```swift
struct GblnConfig {
    var miniMode: Bool          // Use MINI GBLN (default: true)
    var compress: Bool          // Enable XZ compression (default: true)
    var compressionLevel: UInt8 // XZ level 0-9 (default: 6)
    var indent: Int             // Indentation width (default: 2)
    var stripComments: Bool     // Remove comments (default: true)
    
    static let io: GblnConfig      // Production I/O format
    static let source: GblnConfig  // Human-readable source
}
```

### Error Handling

```swift
enum GblnError: Error {
    case parseError(String)
    case validationError(String)
    case ioError(String)
    case serialiseError(String)
}
```

## Examples

### Configuration File

```swift
import GBLN

struct AppConfig {
    let host: String
    let port: Int
    let workers: Int
    let debug: Bool
}

// Parse GBLN config file
let configPath = Bundle.main.path(forResource: "config", ofType: "gbln")!
let data = try parseFile(at: configPath)

let dict = data as! [String: Any]
let app = dict["app"] as! [String: Any]

let config = AppConfig(
    host: app["host"] as! String,
    port: app["port"] as! Int,
    workers: app["workers"] as! Int,
    debug: app["debug"] as! Bool
)
```

**config.gbln:**

```gbln
:| Application configuration
app{
    host<s64>(localhost)
    port<u16>(8080)
    workers<u8>(4)
    debug<b>(f)
}
```

### API Response

```swift
import GBLN

// Parse API response
let gblnResponse = """
response{
    status<u16>(200)
    message<s64>(Success)
    data{
        users[
            {id<u32>(1)name<s32>(Alice)}
            {id<u32>(2)name<s32>(Bob)}
        ]
    }
}
"""

let result = try parse(gblnResponse)
let dict = result as! [String: Any]
let response = dict["response"] as! [String: Any]
let data = response["data"] as! [String: Any]
let users = data["users"] as! [Any]

for user in users {
    let u = user as! [String: Any]
    print("\(u["id"]!): \(u["name"]!)")
}
```

### I/O Format for Large Data

```swift
import GBLN

// Write large dataset to compressed file
let employees: [[String: Any]] = [
    ["id": 1, "name": "Alice", "department": "Engineering"],
    ["id": 2, "name": "Bob", "department": "Sales"],
    // ... 1000 employees
]

try writeIo(employees, to: "employees.io.gbln.xz")

// File size: ~30 KB (vs. 156 KB for JSON)
// Token count: ~8,300 (vs. 52,000 for JSON - 84% reduction)

// Load compressed file
let loaded = try readIo(from: "employees.io.gbln.xz")
```

### Async/Await Usage

```swift
import GBLN

func loadUserData(id: Int) async throws -> [String: Any] {
    let path = "users/\(id).io.gbln.xz"
    let data = try await readIoAsync(from: path)
    return data as! [String: Any]
}

func saveUserData(id: Int, data: [String: Any]) async throws {
    let path = "users/\(id).io.gbln.xz"
    try await writeIoAsync(data, to: path)
}

// Usage
Task {
    let user = try await loadUserData(id: 123)
    print(user["name"]!)
    
    var updatedUser = user
    updatedUser["last_login"] = Date().timeIntervalSince1970
    
    try await saveUserData(id: 123, data: updatedUser)
}
```

## Platform Support

### Apple Platforms

- iOS 15+ (ARM64)
- macOS 12+ (x86_64, ARM64)
- watchOS 8+ (ARM64)
- tvOS 15+ (ARM64)

### Linux

- Ubuntu 20.04+ (x86_64, ARM64)
- Fedora 34+ (x86_64, ARM64)
- Debian 11+ (x86_64, ARM64)

### FreeBSD

- FreeBSD 13+ (x86_64, ARM64)

## Performance

### Parsing Speed

- Target: ~65ms for 1000 records
- Trade-off: 30-50% slower than JSON, but type-safe

### File Size

| Format | Size (1000 records) |
|--------|---------------------|
| JSON | 156 KB |
| Protocol Buffers | 42 KB |
| **GBLN** | **30 KB** ✨ |

### Token Efficiency (for LLMs)

| Format | Tokens (1000 records) |
|--------|-----------------------|
| JSON | 52,000 |
| **GBLN MINI** | **8,300** (84% reduction) |

## Building from Source

### Prerequisites

1. **Rust toolchain** (1.70+):
   ```bash
   curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
   ```

2. **Swift** (5.7+):
   - macOS: Included with Xcode 15+
   - Linux: Install from https://swift.org/download/

### Build Steps

```bash
# Clone repository
git clone https://github.com/gbln-org/gbln-swift.git
cd gbln-swift

# Build Swift package
swift build

# Run tests
swift test
```

## Contributing

Contributions are welcome! Please read [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.

## License

Apache 2.0 - See [LICENSE](LICENSE) for details.

## Resources

- **Specification**: [docs/01-specification.md](https://github.com/gbln-org/gbln/blob/main/docs/01-specification.md)
- **Website**: https://gbln.dev
- **GitHub**: https://github.com/gbln-org/gbln
- **Rust Core**: https://github.com/gbln-org/gbln-rust
- **C FFI**: https://github.com/gbln-org/gbln-ffi

## Acknowledgements

Built with [libgbln](https://github.com/gbln-org/gbln-rust) C FFI layer.

---

*GBLN - Type-safe data that speaks clearly* 🦇
