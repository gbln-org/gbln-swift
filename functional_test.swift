#!/usr/bin/env swift
// Functional integration test for GBLN Swift bindings
// This bypasses SPM's test runner to avoid dyld issues

import Foundation

print("🧪 GBLN Swift Bindings - Functional Test Suite")
print(String(repeating: "=", count: 60))

// Setup library path
let libPath = ".build/arm64-apple-macosx/debug/libgbln.dylib"
guard let handle = dlopen(libPath, RTLD_NOW) else {
    print("❌ FATAL: Failed to load library: \(String(cString: dlerror()))")
    exit(1)
}
defer { dlclose(handle) }

print("✅ Library loaded successfully")

// Define C function signatures
typealias ParseFunc = @convention(c) (UnsafePointer<CChar>, UnsafeMutablePointer<OpaquePointer?>) -> Int32
typealias ToStringFunc = @convention(c) (OpaquePointer) -> UnsafeMutablePointer<CChar>?
typealias StringFreeFunc = @convention(c) (UnsafeMutablePointer<CChar>) -> Void
typealias ValueFreeFunc = @convention(c) (OpaquePointer) -> Void

guard let parsePtr = dlsym(handle, "gbln_parse"),
      let toStringPtr = dlsym(handle, "gbln_to_string"),
      let stringFreePtr = dlsym(handle, "gbln_string_free"),
      let valueFreePtr = dlsym(handle, "gbln_value_free") else {
    print("❌ FATAL: Failed to load required functions")
    exit(1)
}

let parse = unsafeBitCast(parsePtr, to: ParseFunc.self)
let toString = unsafeBitCast(toStringPtr, to: ToStringFunc.self)
let stringFree = unsafeBitCast(stringFreePtr, to: StringFreeFunc.self)
let valueFree = unsafeBitCast(valueFreePtr, to: ValueFreeFunc.self)

print("✅ All FFI functions found")

// Test counter
var totalTests = 0
var passedTests = 0

func test(_ name: String, _ block: () -> Bool) {
    totalTests += 1
    print("\n🔍 Test \(totalTests): \(name)")
    if block() {
        passedTests += 1
        print("   ✅ PASS")
    } else {
        print("   ❌ FAIL")
    }
}

// Test 1: Parse simple integer
test("Parse simple integer") {
    var outValue: OpaquePointer? = nil
    let result = "age<i8>(42)".withCString { parse($0, &outValue) }
    if result == 0, let value = outValue {
        defer { valueFree(value) }
        return true
    }
    return false
}

// Test 2: Parse and serialize (roundtrip)
test("Parse and serialize roundtrip") {
    var outValue: OpaquePointer? = nil
    let input = "name<s32>(Alice)"
    let parseResult = input.withCString { parse($0, &outValue) }
    
    guard parseResult == 0, let value = outValue else { return false }
    defer { valueFree(value) }
    
    guard let strPtr = toString(value) else { return false }
    defer { stringFree(strPtr) }
    
    let output = String(cString: strPtr)
    print("   Input:  \(input)")
    print("   Output: \(output)")
    
    return output.contains("Alice") && output.contains("s")
}

// Test 3: Parse object
test("Parse object structure") {
    var outValue: OpaquePointer? = nil
    let input = "user{id<u32>(123)name<s64>(Bob)}"
    let result = input.withCString { parse($0, &outValue) }
    
    if result == 0, let value = outValue {
        defer { valueFree(value) }
        
        if let strPtr = toString(value) {
            defer { stringFree(strPtr) }
            let output = String(cString: strPtr)
            return output.contains("123") && output.contains("Bob")
        }
    }
    return false
}

// Test 4: Parse array
test("Parse array structure") {
    var outValue: OpaquePointer? = nil
    let input = "tags<s16>[rust python swift]"
    let result = input.withCString { parse($0, &outValue) }
    
    if result == 0, let value = outValue {
        defer { valueFree(value) }
        
        if let strPtr = toString(value) {
            defer { stringFree(strPtr) }
            let output = String(cString: strPtr)
            return output.contains("rust") && output.contains("python") && output.contains("swift")
        }
    }
    return false
}

// Test 5: Parse UTF-8 strings
test("Parse UTF-8 strings") {
    var outValue: OpaquePointer? = nil
    let input = "city<s16>(北京)"
    let result = input.withCString { parse($0, &outValue) }
    
    if result == 0, let value = outValue {
        defer { valueFree(value) }
        
        if let strPtr = toString(value) {
            defer { stringFree(strPtr) }
            let output = String(cString: strPtr)
            return output.contains("北京")
        }
    }
    return false
}

// Test 6: Parse nested objects
test("Parse nested objects") {
    var outValue: OpaquePointer? = nil
    let input = "response{status<u16>(200)data{user{id<u32>(99)}}}"
    let result = input.withCString { parse($0, &outValue) }
    
    if result == 0, let value = outValue {
        defer { valueFree(value) }
        
        if let strPtr = toString(value) {
            defer { stringFree(strPtr) }
            let output = String(cString: strPtr)
            return output.contains("200") && output.contains("99")
        }
    }
    return false
}

// Test 7: Parse all integer types
test("Parse various integer types") {
    let tests = [
        "val<i8>(-128)",
        "val<i16>(32000)",
        "val<u8>(255)",
        "val<u32>(4000000)"
    ]
    
    for input in tests {
        var outValue: OpaquePointer? = nil
        let result = input.withCString { parse($0, &outValue) }
        guard result == 0, let value = outValue else { return false }
        valueFree(value)
    }
    return true
}

// Test 8: Parse float types
test("Parse float types") {
    let tests = [
        "pi<f32>(3.14159)",
        "e<f64>(2.718281828)"
    ]
    
    for input in tests {
        var outValue: OpaquePointer? = nil
        let result = input.withCString { parse($0, &outValue) }
        guard result == 0, let value = outValue else { return false }
        valueFree(value)
    }
    return true
}

// Test 9: Parse boolean
test("Parse boolean values") {
    let tests = [
        "active<b>(t)",
        "disabled<b>(f)",
        "enabled<b>(true)",
        "hidden<b>(false)"
    ]
    
    for input in tests {
        var outValue: OpaquePointer? = nil
        let result = input.withCString { parse($0, &outValue) }
        guard result == 0, let value = outValue else { return false }
        valueFree(value)
    }
    return true
}

// Test 10: Error handling - invalid input
test("Error handling for invalid input") {
    var outValue: OpaquePointer? = nil
    let input = "invalid{syntax"  // Missing closing brace
    let result = input.withCString { parse($0, &outValue) }
    
    // Should fail (result != 0)
    return result != 0
}

// Final summary
print("\n" + String(repeating: "=", count: 60))
print("📊 Test Summary")
print(String(repeating: "=", count: 60))
print("Total tests: \(totalTests)")
print("Passed:      \(passedTests) ✅")
print("Failed:      \(totalTests - passedTests) ❌")
print("Success rate: \(passedTests * 100 / totalTests)%")

if passedTests == totalTests {
    print("\n🎉 ALL TESTS PASSED!")
    exit(0)
} else {
    print("\n❌ SOME TESTS FAILED")
    exit(1)
}
