// Copyright (c) 2025 Vivian Burkhard Voss
// SPDX-License-Identifier: Apache-2.0

import Foundation

/// GBLN (Goblin Bounded Lean Notation) - Type-safe, LLM-optimised serialisation format.
///
/// GBLN is the first LLM-native serialisation format designed for:
/// - **Type safety**: Inline type hints with parse-time validation
/// - **Memory efficiency**: 86% fewer tokens than JSON for AI contexts
/// - **Human readability**: Text-based format with clear syntax
/// - **Git-friendly**: Meaningful diffs, ordered keys preserved
///
/// # Quick Start
///
/// ```swift
/// import GBLN
///
/// // Parse GBLN string
/// let user = try parse("user{id<u32>(123)name<s64>(Alice)}")
/// // → ["user": ["id": 123, "name": "Alice"]]
///
/// // Serialise Swift value
/// let gbln = try toString(["id": 123, "name": "Alice"])
/// // → "{id<i8>(123)name<s64>(Alice)}"
///
/// // I/O format (MINI + XZ compression)
/// try writeIo(userData, to: "data.io.gbln.xz")
/// let data = try readIo(from: "data.io.gbln.xz")
/// ```
///
/// # Type System
///
/// GBLN provides bounded types with parse-time validation:
///
/// - **Integers**: `i8`, `i16`, `i32`, `i64`, `u8`, `u16`, `u32`, `u64`
/// - **Floats**: `f32`, `f64`
/// - **Strings**: `s2`, `s4`, `s8`, `s16`, `s32`, `s64`, `s128`, `s256`, `s512`, `s1024`
/// - **Boolean**: `b`
/// - **Null**: `n`
///
/// # Syntax Examples
///
/// ```gbln
/// :| Single value
/// age<i8>(25)
///
/// :| Object
/// user{
///     id<u32>(12345)
///     name<s64>(Alice)
///     active<b>(t)
/// }
///
/// :| Array
/// tags<s16>[rust python swift]
/// ```
///
/// # Public API
///
/// - `parse(_:)` - Parse GBLN string to Swift value
/// - `parseFile(at:)` - Parse GBLN file to Swift value
/// - `parseFileAsync(at:)` - Async file parsing
/// - `toString(_:mini:)` - Serialise Swift value to GBLN
/// - `toStringPretty(_:indent:)` - Pretty-print GBLN
/// - `writeIo(_:to:config:)` - Write I/O format file
/// - `readIo(from:)` - Read I/O format file
/// - `writeIoAsync(_:to:config:)` - Async I/O write
/// - `readIoAsync(from:)` - Async I/O read
///
/// # Configuration
///
/// - `GblnConfig` - I/O format configuration (MINI mode, compression, etc.)
/// - `GblnError` - Error types for parsing, validation, I/O, and serialisation
///
/// # References
///
/// - GitHub: https://github.com/gbln-org/gbln
/// - Documentation: https://gbln.dev
/// - Specification: https://github.com/gbln-org/gbln/blob/main/docs/01-specification.md
public struct GBLN {
    /// GBLN library version.
    public static let version = "1.0.0"

    /// GBLN specification version.
    public static let specVersion = "1.0.0"
}
