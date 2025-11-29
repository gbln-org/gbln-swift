#!/usr/bin/env swift

import Foundation

// Direct dlopen test
let libPath = ".build/arm64-apple-macosx/debug/libgbln.dylib"
guard let handle = dlopen(libPath, RTLD_NOW) else {
    print("Failed to load library: \(String(cString: dlerror()))")
    exit(1)
}

print("✅ Successfully loaded libgbln.dylib")

// Try to get a function
typealias ParseFunc = @convention(c) (UnsafePointer<CChar>, UnsafeMutablePointer<OpaquePointer?>) -> Int32

if let parsePtr = dlsym(handle, "gbln_parse") {
    print("✅ Found gbln_parse function")
    
    let parse = unsafeBitCast(parsePtr, to: ParseFunc.self)
    
    var outValue: OpaquePointer? = nil
    let testInput = "age<i8>(42)"
    let result = testInput.withCString { cStr in
        parse(cStr, &outValue)
    }
    
    print("Parse result code: \(result)")
    if result == 0 {
        print("✅ Parse succeeded!")
    } else {
        print("❌ Parse failed with code: \(result)")
    }
} else {
    print("❌ Failed to find gbln_parse: \(String(cString: dlerror()))")
}

dlclose(handle)
