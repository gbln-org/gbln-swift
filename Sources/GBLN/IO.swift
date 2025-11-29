// Copyright (c) 2025 Vivian Burkhard Voss
// SPDX-License-Identifier: Apache-2.0

import CGBLN
import Foundation

/// Write Swift value to I/O format file (synchronous).
///
/// Serialises a Swift value according to the configuration and writes it to
/// a file. The file format is automatically determined by the config settings:
///
/// # File Formats
///
/// - **`.io.gbln.xz`**: MINI GBLN + XZ compression (default, `compress=true`)
/// - **`.io.gbln`**: MINI GBLN without compression (`compress=false`, `miniMode=true`)
/// - **`.gbln`**: Pretty-printed source format (`miniMode=false`)
///
/// # Examples
///
/// ```swift
/// let user = ["id": 123, "name": "Alice", "active": true]
///
/// // Production I/O format (MINI + XZ)
/// try writeIo(user, to: "data.io.gbln.xz")
///
/// // Custom configuration
/// var config = GblnConfig()
/// config.compress = false
/// try writeIo(user, to: "data.io.gbln", config: config)
///
/// // Source format
/// try writeIo(user, to: "data.gbln", config: .source)
/// ```
///
/// - Parameters:
///   - value: Swift value to write
///   - path: Output file path
///   - config: I/O configuration (default: `GblnConfig.io`)
/// - Throws: `GblnError.ioError` if write fails, or `GblnError.serialiseError` if conversion fails
public func writeIo(_ value: Any, to path: String, config: GblnConfig = .io) throws {
    let gblnValue = try swiftToGbln(value)
    let configPtr = config.toCPointer()

    defer {
        gbln_config_free(configPtr)
    }

    try FFI.writeIo(gblnValue.pointer, path: path, configPtr: configPtr)
}

/// Read Swift value from I/O format file (synchronous).
///
/// Reads a GBLN file and automatically detects compression.
/// Supports all GBLN file formats:
///
/// # File Formats
///
/// - **`.io.gbln.xz`**: MINI GBLN + XZ compression (auto-detected)
/// - **`.io.gbln`**: MINI GBLN without compression
/// - **`.gbln`**: Pretty-printed source format
///
/// # Auto-Detection
///
/// The function automatically detects XZ compression by checking for magic bytes
/// (`FD 37 7A 58 5A 00`) and decompresses if needed.
///
/// # Examples
///
/// ```swift
/// // Read I/O format file (auto-detects compression)
/// let data = try readIo(from: "data.io.gbln.xz")
/// print(data)
///
/// // Read source file
/// let config = try readIo(from: "config.gbln")
///
/// // Read from bundle resource
/// if let path = Bundle.main.path(forResource: "data", ofType: "io.gbln.xz") {
///     let data = try readIo(from: path)
/// }
/// ```
///
/// - Parameter path: Input file path
/// - Returns: Swift value (Dictionary, Array, or primitive)
/// - Throws: `GblnError.ioError` if read fails, or `GblnError.parseError` if invalid GBLN
public func readIo(from path: String) throws -> Any {
    let valuePtr = try FFI.readIo(path: path)
    let managed = ManagedValue(valuePtr)

    guard let result = try gblnToSwift(managed.pointer) else {
        return NSNull()
    }

    return result
}

/// Write Swift value to I/O format file (asynchronous).
///
/// Async variant of `writeIo(_:to:config:)` that can be called from async contexts.
///
/// # Examples
///
/// ```swift
/// Task {
///     let user = ["id": 123, "name": "Alice"]
///     try await writeIoAsync(user, to: "data.io.gbln.xz")
/// }
/// ```
///
/// - Parameters:
///   - value: Swift value to write
///   - path: Output file path
///   - config: I/O configuration (default: `GblnConfig.io`)
/// - Throws: `GblnError.ioError` if write fails, or `GblnError.serialiseError` if conversion fails
public func writeIoAsync(_ value: Any, to path: String, config: GblnConfig = .io) async throws {
    try writeIo(value, to: path, config: config)
}

/// Read Swift value from I/O format file (asynchronous).
///
/// Async variant of `readIo(from:)` that can be called from async contexts.
///
/// # Examples
///
/// ```swift
/// Task {
///     let data = try await readIoAsync(from: "data.io.gbln.xz")
///     print(data)
/// }
/// ```
///
/// - Parameter path: Input file path
/// - Returns: Swift value (Dictionary, Array, or primitive)
/// - Throws: `GblnError.ioError` if read fails, or `GblnError.parseError` if invalid GBLN
public func readIoAsync(from path: String) async throws -> Any {
    return try readIo(from: path)
}
