// Copyright (c) 2025 Vivian Burkhard Voss
// SPDX-License-Identifier: Apache-2.0

import Foundation

/// Serialise Swift value to GBLN MINI string.
///
/// Converts a Swift value to compact GBLN format (no whitespace).
/// This is the default serialisation mode, optimised for LLM contexts
/// and production use.
///
/// # Supported Types
///
/// - `nil` → `<n>()`
/// - `Bool` → `<b>(t)` or `<b>(f)`
/// - `Int` → `<i8>()`, `<i16>()`, etc. (auto-selected)
/// - `Double` → `<f64>()`
/// - `String` → `<s64>()`, `<s256>()`, etc. (auto-selected)
/// - `[String: Any]` → `{key<type>(value)...}`
/// - `[Any]` → `[<type>(value)...]`
///
/// # Examples
///
/// ```swift
/// // Serialise simple value
/// let gbln = try toString(42)
/// // → "<i8>(42)"
///
/// // Serialise object
/// let user = ["id": 123, "name": "Alice"]
/// let gbln = try toString(user)
/// // → "{id<i8>(123)name<s64>(Alice)}"
///
/// // Serialise array
/// let tags = ["rust", "python", "swift"]
/// let gbln = try toString(tags)
/// // → "[<s64>(rust)<s64>(python)<s64>(swift)]"
/// ```
///
/// - Parameters:
///   - value: Swift value to serialise
///   - mini: Use MINI format (default: true)
/// - Returns: GBLN string (compact format)
/// - Throws: `GblnError.serialiseError` if conversion fails
public func toString(_ value: Any, mini: Bool = true) throws -> String {
    let gblnValue = try swiftToGbln(value)

    if mini {
        return try FFI.toString(gblnValue.pointer)
    } else {
        return try FFI.toStringPretty(gblnValue.pointer)
    }
}

/// Serialise Swift value to pretty-printed GBLN string.
///
/// Converts a Swift value to formatted GBLN with newlines and indentation.
/// Use this for human-readable output, configuration files, and source code.
///
/// # Formatting Rules
///
/// - Objects: Each field on separate line, indented
/// - Arrays: Elements on separate lines if complex
/// - Indentation: 2 spaces per level (configurable in future)
///
/// # Examples
///
/// ```swift
/// let user = [
///     "id": 123,
///     "name": "Alice",
///     "active": true
/// ]
///
/// let gbln = try toStringPretty(user)
/// // →
/// // {
/// //     id<i8>(123)
/// //     name<s64>(Alice)
/// //     active<b>(t)
/// // }
/// ```
///
/// - Parameters:
///   - value: Swift value to serialise
///   - indent: Indentation width (default: 2)
/// - Returns: Pretty-printed GBLN string
/// - Throws: `GblnError.serialiseError` if conversion fails
public func toStringPretty(_ value: Any, indent: Int = 2) throws -> String {
    let gblnValue = try swiftToGbln(value)
    return try FFI.toStringPretty(gblnValue.pointer)
}
