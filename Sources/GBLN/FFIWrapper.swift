// Copyright (c) 2025 Vivian Burkhard Voss
// SPDX-License-Identifier: Apache-2.0

import CGBLN
import Foundation

/// Internal wrapper for C FFI functions from libgbln.
///
/// This enum provides Swift-friendly wrappers around the C functions,
/// handling pointer conversions, error checking, and memory management.
///
/// All functions throw `GblnError` on failure instead of returning error codes.
internal enum FFI {

    // MARK: - Error Handling

    /// Get last error message from C FFI.
    ///
    /// - Returns: Error message string, or "Unknown error" if none available
    static func getErrorMessage() -> String {
        guard let msgPtr = gbln_last_error_message() else {
            return "Unknown error"
        }

        defer { gbln_string_free(msgPtr) }

        return String(cString: msgPtr)
    }

    /// Get last error suggestion from C FFI.
    ///
    /// - Returns: Suggestion string, or empty string if none available
    static func getErrorSuggestion() -> String {
        guard let suggPtr = gbln_last_error_suggestion() else {
            return ""
        }

        defer { gbln_string_free(suggPtr) }

        return String(cString: suggPtr)
    }

    // MARK: - Parse

    /// Parse GBLN string to value.
    ///
    /// Calls C function: `gbln_parse(const char* input, GblnValue** out_value)`
    ///
    /// - Parameter input: GBLN-formatted string
    /// - Returns: Opaque pointer to GblnValue (caller owns, must free)
    /// - Throws: `GblnError.parseError` if parsing fails
    static func parse(_ input: String) throws -> OpaquePointer {
        var outValue: OpaquePointer?

        let result = input.withCString { cString in
            gbln_parse(cString, &outValue)
        }

        guard result == Ok else {
            let errorMsg = getErrorMessage()
            let suggestion = getErrorSuggestion()
            let fullMsg = suggestion.isEmpty ? errorMsg : "\(errorMsg)\nSuggestion: \(suggestion)"
            throw GblnError.parseError(fullMsg)
        }

        guard let valuePtr = outValue else {
            throw GblnError.parseError("Parse returned null pointer")
        }

        return valuePtr
    }

    // MARK: - Serialise

    /// Serialise GBLN value to MINI string.
    ///
    /// Calls C function: `gbln_to_string(const GblnValue* value)`
    ///
    /// - Parameter valuePtr: Pointer to GblnValue
    /// - Returns: GBLN string (compact, no whitespace)
    /// - Throws: `GblnError.serialiseError` if serialisation fails
    static func toString(_ valuePtr: OpaquePointer) throws -> String {
        guard let strPtr = gbln_to_string(valuePtr) else {
            throw GblnError.serialiseError("Serialisation returned null pointer")
        }

        defer { gbln_string_free(strPtr) }

        return String(cString: strPtr)
    }

    /// Serialise GBLN value to pretty-printed string.
    ///
    /// Calls C function: `gbln_to_string_pretty(const GblnValue* value)`
    ///
    /// - Parameter valuePtr: Pointer to GblnValue
    /// - Returns: Pretty-printed GBLN string with newlines and indentation
    /// - Throws: `GblnError.serialiseError` if serialisation fails
    static func toStringPretty(_ valuePtr: OpaquePointer) throws -> String {
        guard let strPtr = gbln_to_string_pretty(valuePtr) else {
            throw GblnError.serialiseError("Pretty serialisation returned null pointer")
        }

        defer { gbln_string_free(strPtr) }

        return String(cString: strPtr)
    }

    // MARK: - Memory Management

    /// Free GBLN value.
    ///
    /// Calls C function: `gbln_value_free(GblnValue* value)`
    ///
    /// - Parameter valuePtr: Pointer to GblnValue to free
    static func freeValue(_ valuePtr: OpaquePointer) {
        gbln_value_free(valuePtr)
    }

    // MARK: - Type Introspection

    /// Get value type.
    ///
    /// Calls C function: `gbln_value_type(const GblnValue* value)`
    ///
    /// - Parameter valuePtr: Pointer to GblnValue
    /// - Returns: Value type enum
    static func valueType(_ valuePtr: OpaquePointer) -> GblnValueType {
        return gbln_value_type(valuePtr)
    }

    // MARK: - Value Accessors

    /// Extract i8 value.
    ///
    /// - Parameter valuePtr: Pointer to GblnValue
    /// - Returns: i8 value if type matches
    /// - Throws: `GblnError.parseError` if type mismatch
    static func asI8(_ valuePtr: OpaquePointer) throws -> Int8 {
        var ok: Bool = false
        let value = gbln_value_as_i8(valuePtr, &ok)

        guard ok else {
            throw GblnError.parseError("Value is not i8")
        }

        return value
    }

    /// Extract i16 value.
    static func asI16(_ valuePtr: OpaquePointer) throws -> Int16 {
        var ok: Bool = false
        let value = gbln_value_as_i16(valuePtr, &ok)

        guard ok else {
            throw GblnError.parseError("Value is not i16")
        }

        return value
    }

    /// Extract i32 value.
    static func asI32(_ valuePtr: OpaquePointer) throws -> Int32 {
        var ok: Bool = false
        let value = gbln_value_as_i32(valuePtr, &ok)

        guard ok else {
            throw GblnError.parseError("Value is not i32")
        }

        return value
    }

    /// Extract i64 value.
    static func asI64(_ valuePtr: OpaquePointer) throws -> Int64 {
        var ok: Bool = false
        let value = gbln_value_as_i64(valuePtr, &ok)

        guard ok else {
            throw GblnError.parseError("Value is not i64")
        }

        return value
    }

    /// Extract u8 value.
    static func asU8(_ valuePtr: OpaquePointer) throws -> UInt8 {
        var ok: Bool = false
        let value = gbln_value_as_u8(valuePtr, &ok)

        guard ok else {
            throw GblnError.parseError("Value is not u8")
        }

        return value
    }

    /// Extract u16 value.
    static func asU16(_ valuePtr: OpaquePointer) throws -> UInt16 {
        var ok: Bool = false
        let value = gbln_value_as_u16(valuePtr, &ok)

        guard ok else {
            throw GblnError.parseError("Value is not u16")
        }

        return value
    }

    /// Extract u32 value.
    static func asU32(_ valuePtr: OpaquePointer) throws -> UInt32 {
        var ok: Bool = false
        let value = gbln_value_as_u32(valuePtr, &ok)

        guard ok else {
            throw GblnError.parseError("Value is not u32")
        }

        return value
    }

    /// Extract u64 value.
    static func asU64(_ valuePtr: OpaquePointer) throws -> UInt64 {
        var ok: Bool = false
        let value = gbln_value_as_u64(valuePtr, &ok)

        guard ok else {
            throw GblnError.parseError("Value is not u64")
        }

        return value
    }

    /// Extract f32 value.
    static func asF32(_ valuePtr: OpaquePointer) throws -> Float {
        var ok: Bool = false
        let value = gbln_value_as_f32(valuePtr, &ok)

        guard ok else {
            throw GblnError.parseError("Value is not f32")
        }

        return value
    }

    /// Extract f64 value.
    static func asF64(_ valuePtr: OpaquePointer) throws -> Double {
        var ok: Bool = false
        let value = gbln_value_as_f64(valuePtr, &ok)

        guard ok else {
            throw GblnError.parseError("Value is not f64")
        }

        return value
    }

    /// Extract string value.
    static func asString(_ valuePtr: OpaquePointer) throws -> String {
        var ok: Bool = false
        guard let strPtr = gbln_value_as_string(valuePtr, &ok) else {
            throw GblnError.parseError("Value is not a string")
        }

        defer { gbln_string_free(strPtr) }

        return String(cString: strPtr)
    }

    /// Extract bool value.
    static func asBool(_ valuePtr: OpaquePointer) throws -> Bool {
        var ok: Bool = false
        let value = gbln_value_as_bool(valuePtr, &ok)

        guard ok else {
            throw GblnError.parseError("Value is not bool")
        }

        return value
    }

    /// Check if value is null.
    static func isNull(_ valuePtr: OpaquePointer) -> Bool {
        return gbln_value_is_null(valuePtr)
    }

    // MARK: - Object Operations

    /// Get object field count.
    static func objectLen(_ valuePtr: OpaquePointer) -> Int {
        return Int(gbln_object_len(valuePtr))
    }

    /// Get object field value by key.
    ///
    /// - Parameters:
    ///   - valuePtr: Pointer to object value
    ///   - key: Field key
    /// - Returns: Pointer to field value, or nil if not found
    static func objectGet(_ valuePtr: OpaquePointer, key: String) -> OpaquePointer? {
        return key.withCString { keyCStr in
            gbln_object_get(valuePtr, keyCStr)
        }
    }

    /// Get all object keys.
    ///
    /// - Parameter valuePtr: Pointer to object value
    /// - Returns: Array of key strings
    /// - Throws: `GblnError.parseError` if value is not an object
    static func objectKeys(_ valuePtr: OpaquePointer) throws -> [String] {
        var count: UInt = 0

        guard let keysPtr = gbln_object_keys(valuePtr, &count) else {
            throw GblnError.parseError("Failed to get object keys")
        }

        defer { gbln_keys_free(keysPtr, count) }

        var keys: [String] = []
        for i in 0..<Int(count) {
            if let keyCStr = keysPtr[i] {
                keys.append(String(cString: keyCStr))
            }
        }

        return keys
    }

    // MARK: - Array Operations

    /// Get array length.
    static func arrayLen(_ valuePtr: OpaquePointer) -> Int {
        return Int(gbln_array_len(valuePtr))
    }

    /// Get array element by index.
    ///
    /// - Parameters:
    ///   - valuePtr: Pointer to array value
    ///   - index: Element index
    /// - Returns: Pointer to element value, or nil if out of bounds
    static func arrayGet(_ valuePtr: OpaquePointer, index: Int) -> OpaquePointer? {
        return gbln_array_get(valuePtr, UInt(index))
    }

    // MARK: - I/O Operations

    /// Write value to I/O format file.
    ///
    /// Calls C function: `gbln_write_io(const GblnValue* value, const char* path, const GblnConfig* config)`
    ///
    /// - Parameters:
    ///   - valuePtr: Pointer to GblnValue
    ///   - path: Output file path
    ///   - configPtr: Pointer to GblnConfig (or nil for default)
    /// - Throws: `GblnError.ioError` if write fails
    static func writeIo(_ valuePtr: OpaquePointer, path: String, configPtr: OpaquePointer?) throws {
        let result = path.withCString { pathCStr in
            gbln_write_io(valuePtr, pathCStr, configPtr)
        }

        guard result == Ok else {
            let errorMsg = getErrorMessage()
            throw GblnError.ioError(errorMsg)
        }
    }

    /// Read value from I/O format file.
    ///
    /// Calls C function: `gbln_read_io(const char* path, GblnValue** out_value)`
    ///
    /// - Parameter path: Input file path
    /// - Returns: Opaque pointer to GblnValue (caller owns, must free)
    /// - Throws: `GblnError.ioError` if read fails
    static func readIo(path: String) throws -> OpaquePointer {
        var outValue: OpaquePointer?

        let result = path.withCString { pathCStr in
            gbln_read_io(pathCStr, &outValue)
        }

        guard result == Ok else {
            let errorMsg = getErrorMessage()
            throw GblnError.ioError(errorMsg)
        }

        guard let valuePtr = outValue else {
            throw GblnError.ioError("Read returned null pointer")
        }

        return valuePtr
    }
}
