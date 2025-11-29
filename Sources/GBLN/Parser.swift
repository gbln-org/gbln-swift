// Copyright (c) 2025 Vivian Burkhard Voss
// SPDX-License-Identifier: Apache-2.0

import Foundation

/// Parse GBLN string to Swift value.
///
/// Parses a GBLN-formatted string and returns the corresponding Swift value:
/// - Objects → `[String: Any]`
/// - Arrays → `[Any]`
/// - Primitives → `Int`, `Double`, `String`, `Bool`, or `nil`
///
/// # Error Handling
///
/// Throws `GblnError.parseError` with detailed error messages including:
/// - Line and column information
/// - Expected vs. actual values
/// - Helpful suggestions for fixing syntax errors
///
/// # Examples
///
/// ```swift
/// // Parse simple value
/// let value = try parse("<i32>(42)")
/// // → 42 (Int)
///
/// // Parse object
/// let user = try parse("user{id<u32>(123)name<s32>(Alice)}")
/// // → ["user": ["id": 123, "name": "Alice"]]
///
/// // Parse array
/// let tags = try parse("tags<s16>[rust python swift]")
/// // → ["tags": ["rust", "python", "swift"]]
/// ```
///
/// - Parameter gblnString: GBLN-formatted string
/// - Returns: Swift value (Dictionary, Array, or primitive)
/// - Throws: `GblnError.parseError` if parsing fails
public func parse(_ gblnString: String) throws -> Any {
    let valuePtr = try FFI.parse(gblnString)
    let managed = ManagedValue(valuePtr)

    guard let result = try gblnToSwift(managed.pointer) else {
        // GBLN null becomes Swift nil, but we return NSNull for top-level null
        return NSNull()
    }

    return result
}

/// Parse GBLN file to Swift value (synchronous).
///
/// Reads a `.gbln` file and parses its content.
/// For I/O format files (`.io.gbln.xz`), use `readIo()` instead.
///
/// # Examples
///
/// ```swift
/// // Parse source file
/// let config = try parseFile(at: "/path/to/config.gbln")
///
/// // Parse from bundle resource
/// if let path = Bundle.main.path(forResource: "data", ofType: "gbln") {
///     let data = try parseFile(at: path)
/// }
/// ```
///
/// - Parameter path: File path (absolute or relative)
/// - Returns: Swift value (Dictionary, Array, or primitive)
/// - Throws: `GblnError.parseError` if parsing fails, or `GblnError.ioError` if file read fails
public func parseFile(at path: String) throws -> Any {
    do {
        let content = try String(contentsOfFile: path, encoding: .utf8)
        return try parse(content)
    } catch let error as GblnError {
        throw error
    } catch {
        throw GblnError.ioError("Failed to read file '\(path)': \(error.localizedDescription)")
    }
}

/// Parse GBLN file to Swift value (asynchronous).
///
/// Async variant of `parseFile(at:)` that can be called from async contexts.
///
/// # Examples
///
/// ```swift
/// Task {
///     let config = try await parseFileAsync(at: "/path/to/config.gbln")
///     print(config)
/// }
/// ```
///
/// - Parameter path: File path (absolute or relative)
/// - Returns: Swift value (Dictionary, Array, or primitive)
/// - Throws: `GblnError.parseError` if parsing fails, or `GblnError.ioError` if file read fails
public func parseFileAsync(at path: String) async throws -> Any {
    return try parseFile(at: path)
}
