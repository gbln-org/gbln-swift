// Copyright (c) 2025 Vivian Burkhard Voss
// SPDX-License-Identifier: Apache-2.0

import Foundation

/// Errors that can occur during GBLN operations.
///
/// All GBLN functions that can fail throw a `GblnError` with a descriptive
/// error message from the underlying C FFI layer.
public enum GblnError: Error, LocalizedError {
    /// Parsing failed with the given error message.
    ///
    /// This error occurs when the GBLN input string contains syntax errors,
    /// invalid type hints, or values that don't match their declared types.
    ///
    /// Example errors:
    /// - Unexpected character at line 5, column 12
    /// - Integer 999 out of range for type i8 (valid: -128 to 127)
    /// - String "VeryLongName" exceeds s8 limit (8 characters)
    case parseError(String)

    /// Validation failed with the given error message.
    ///
    /// This error occurs when a value violates GBLN's validation rules during
    /// parsing or serialisation (e.g., duplicate object keys).
    case validationError(String)

    /// I/O operation failed with the given error message.
    ///
    /// This error occurs when reading or writing GBLN files fails due to
    /// file system errors, permission issues, or compression errors.
    case ioError(String)

    /// Serialisation failed with the given error message.
    ///
    /// This error occurs when converting Swift values to GBLN format fails,
    /// typically due to unsupported types or invalid value ranges.
    case serialiseError(String)

    /// Localised description for error display.
    public var errorDescription: String? {
        switch self {
        case .parseError(let msg):
            return "Parse error: \(msg)"
        case .validationError(let msg):
            return "Validation error: \(msg)"
        case .ioError(let msg):
            return "I/O error: \(msg)"
        case .serialiseError(let msg):
            return "Serialisation error: \(msg)"
        }
    }
}
