// Copyright (c) 2025 Vivian Burkhard Voss
// SPDX-License-Identifier: Apache-2.0

import CGBLN
import Foundation

/// Managed wrapper for GblnValue with automatic memory cleanup.
///
/// This class wraps an opaque pointer to a C GblnValue and ensures
/// it's properly freed when the Swift object is deallocated.
internal class ManagedValue {
    private let ptr: OpaquePointer

    /// Create managed value from opaque pointer.
    ///
    /// The pointer ownership is transferred to this instance.
    ///
    /// - Parameter ptr: Opaque pointer to GblnValue
    init(_ ptr: OpaquePointer) {
        self.ptr = ptr
    }

    /// Get the underlying opaque pointer.
    var pointer: OpaquePointer {
        ptr
    }

    /// Automatically free the value when deallocated.
    deinit {
        FFI.freeValue(ptr)
    }
}

// MARK: - Swift to GBLN Conversion

/// Convert Swift value to GBLN value.
///
/// Supports the following Swift types:
/// - `nil` → GBLN Null
/// - `Bool` → GBLN Bool
/// - `Int` → GBLN integer (auto-selects i8/i16/i32/i64)
/// - `Double` → GBLN f64
/// - `Float` → GBLN f32
/// - `String` → GBLN Str (auto-selects s64/s256/s1024)
/// - `[String: Any]` → GBLN Object
/// - `[Any]` → GBLN Array
///
/// - Parameter value: Swift value to convert
/// - Returns: Managed GBLN value
/// - Throws: `GblnError.serialiseError` if conversion fails
internal func swiftToGbln(_ value: Any?) throws -> ManagedValue {
    // Handle nil
    if value == nil {
        let ptr = gbln_value_new_null()
        return ManagedValue(ptr!)
    }

    // Handle Bool
    if let bool = value as? Bool {
        let ptr = gbln_value_new_bool(bool)
        return ManagedValue(ptr!)
    }

    // Handle Int (auto-detect type based on range)
    if let int = value as? Int {
        let ptr = autoSelectIntegerType(int)
        return ManagedValue(ptr)
    }

    // Handle Float
    if let float = value as? Float {
        let ptr = gbln_value_new_f32(float)
        return ManagedValue(ptr!)
    }

    // Handle Double
    if let double = value as? Double {
        let ptr = gbln_value_new_f64(double)
        return ManagedValue(ptr!)
    }

    // Handle String (auto-detect size based on character count)
    if let string = value as? String {
        let ptr = try autoSelectStringType(string)
        return ManagedValue(ptr)
    }

    // Handle Dictionary → Object
    if let dict = value as? [String: Any] {
        let ptr = try convertDictToObject(dict)
        return ManagedValue(ptr)
    }

    // Handle Array
    if let array = value as? [Any] {
        let ptr = try convertArrayToGbln(array)
        return ManagedValue(ptr)
    }

    // Unsupported type
    throw GblnError.serialiseError("Unsupported Swift type: \(type(of: value))")
}

/// Auto-select integer type based on value range.
///
/// Selects the smallest GBLN integer type that can hold the value:
/// - -128..127 → i8
/// - -32768..32767 → i16
/// - -2147483648..2147483647 → i32
/// - Otherwise → i64
///
/// - Parameter value: Integer value
/// - Returns: Opaque pointer to GBLN integer value
private func autoSelectIntegerType(_ value: Int) -> OpaquePointer {
    if value >= -128 && value <= 127 {
        return gbln_value_new_i8(Int8(value))!
    } else if value >= -32768 && value <= 32767 {
        return gbln_value_new_i16(Int16(value))!
    } else if value >= -2147483648 && value <= 2147483647 {
        return gbln_value_new_i32(Int32(value))!
    } else {
        return gbln_value_new_i64(Int64(value))!
    }
}

/// Auto-select string type based on character count.
///
/// Selects GBLN string type based on UTF-8 character count:
/// - ≤64 chars → s64
/// - ≤256 chars → s256
/// - ≤1024 chars → s1024
/// - >1024 → ERROR
///
/// - Parameter value: String value
/// - Returns: Opaque pointer to GBLN string value
/// - Throws: `GblnError.serialiseError` if string too long
private func autoSelectStringType(_ value: String) throws -> OpaquePointer {
    let charCount = value.count  // UTF-8 character count

    let maxLen: UInt
    if charCount <= 64 {
        maxLen = 64
    } else if charCount <= 256 {
        maxLen = 256
    } else if charCount <= 1024 {
        maxLen = 1024
    } else {
        throw GblnError.serialiseError("String too long: \(charCount) characters (max 1024)")
    }

    guard let ptr = value.withCString({ cStr in
        gbln_value_new_str(cStr, maxLen)
    }) else {
        throw GblnError.serialiseError("Failed to create string value")
    }

    return ptr
}

/// Convert Swift Dictionary to GBLN Object.
///
/// - Parameter dict: Swift dictionary with string keys
/// - Returns: Opaque pointer to GBLN object value
/// - Throws: `GblnError.serialiseError` if conversion fails
private func convertDictToObject(_ dict: [String: Any]) throws -> OpaquePointer {
    guard let objPtr = gbln_value_new_object() else {
        throw GblnError.serialiseError("Failed to create object")
    }

    for (key, val) in dict {
        let gblnVal = try swiftToGbln(val)

        let result = key.withCString { keyCStr in
            gbln_object_insert(objPtr, keyCStr, gblnVal.pointer)
        }

        if result != Ok {
            // On error, free both the object and the value we just created
            gbln_value_free(objPtr)
            throw GblnError.serialiseError("Failed to insert key '\(key)' into object")
        }
    }

    return objPtr
}

/// Convert Swift Array to GBLN Array.
///
/// - Parameter array: Swift array
/// - Returns: Opaque pointer to GBLN array value
/// - Throws: `GblnError.serialiseError` if conversion fails
private func convertArrayToGbln(_ array: [Any]) throws -> OpaquePointer {
    guard let arrPtr = gbln_value_new_array() else {
        throw GblnError.serialiseError("Failed to create array")
    }

    for item in array {
        let gblnItem = try swiftToGbln(item)

        let result = gbln_array_push(arrPtr, gblnItem.pointer)

        if result != Ok {
            // On error, free both the array and the item we just created
            gbln_value_free(arrPtr)
            throw GblnError.serialiseError("Failed to push item to array")
        }
    }

    return arrPtr
}

// MARK: - GBLN to Swift Conversion

/// Convert GBLN value to Swift value.
///
/// Returns the appropriate Swift type based on GBLN type:
/// - GBLN Null → `nil`
/// - GBLN Bool → `Bool`
/// - GBLN integers → `Int`
/// - GBLN floats → `Double`
/// - GBLN Str → `String`
/// - GBLN Object → `[String: Any]`
/// - GBLN Array → `[Any]`
///
/// - Parameter ptr: Opaque pointer to GBLN value
/// - Returns: Swift value, or `nil` for GBLN Null
/// - Throws: `GblnError.parseError` if conversion fails
internal func gblnToSwift(_ ptr: OpaquePointer) throws -> Any? {
    let valueType = FFI.valueType(ptr)

    switch valueType {
    case Null:
        return nil

    case Bool:
        return try FFI.asBool(ptr)

    case I8:
        return Int(try FFI.asI8(ptr))

    case I16:
        return Int(try FFI.asI16(ptr))

    case I32:
        return Int(try FFI.asI32(ptr))

    case I64:
        return Int(try FFI.asI64(ptr))

    case U8:
        return Int(try FFI.asU8(ptr))

    case U16:
        return Int(try FFI.asU16(ptr))

    case U32:
        return Int(try FFI.asU32(ptr))

    case U64:
        return Int(try FFI.asU64(ptr))

    case F32:
        return Double(try FFI.asF32(ptr))

    case F64:
        return try FFI.asF64(ptr)

    case Str:
        return try FFI.asString(ptr)

    case Object:
        return try convertObjectToDict(ptr)

    case Array:
        return try convertArrayToSwift(ptr)

    default:
        throw GblnError.parseError("Unknown GBLN value type: \(valueType.rawValue)")
    }
}

/// Convert GBLN Object to Swift Dictionary.
///
/// - Parameter ptr: Opaque pointer to GBLN object value
/// - Returns: Swift dictionary
/// - Throws: `GblnError.parseError` if conversion fails
private func convertObjectToDict(_ ptr: OpaquePointer) throws -> [String: Any] {
    var dict: [String: Any] = [:]

    let keys = try FFI.objectKeys(ptr)

    for key in keys {
        guard let fieldPtr = FFI.objectGet(ptr, key: key) else {
            continue
        }

        dict[key] = try gblnToSwift(fieldPtr)
    }

    return dict
}

/// Convert GBLN Array to Swift Array.
///
/// - Parameter ptr: Opaque pointer to GBLN array value
/// - Returns: Swift array
/// - Throws: `GblnError.parseError` if conversion fails
private func convertArrayToSwift(_ ptr: OpaquePointer) throws -> [Any?] {
    var array: [Any?] = []

    let count = FFI.arrayLen(ptr)

    for i in 0..<count {
        guard let itemPtr = FFI.arrayGet(ptr, index: i) else {
            continue
        }

        array.append(try gblnToSwift(itemPtr))
    }

    return array
}
