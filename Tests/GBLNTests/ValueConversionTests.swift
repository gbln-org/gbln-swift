// Copyright (c) 2025 Vivian Burkhard Voss
// SPDX-License-Identifier: Apache-2.0

import XCTest
@testable import GBLN

/// Test suite for Swift ↔ GBLN value conversion.
///
/// Tests cover:
/// - Auto-type selection for integers
/// - Auto-type selection for strings
/// - Bidirectional conversion accuracy
final class ValueConversionTests: XCTestCase {

    // MARK: - Integer Auto-Selection

    func testIntegerAutoSelectI8() throws {
        let value = 42
        let gbln = try toString(value)

        // Should select i8 for small integers
        XCTAssertTrue(gbln.contains("<i8>"))
    }

    func testIntegerAutoSelectI16() throws {
        let value = 1000
        let gbln = try toString(value)

        // Should select i16 for values > 127
        XCTAssertTrue(gbln.contains("<i16>"))
    }

    func testIntegerAutoSelectI32() throws {
        let value = 100000
        let gbln = try toString(value)

        // Should select i32 for values > 32767
        XCTAssertTrue(gbln.contains("<i32>"))
    }

    func testIntegerAutoSelectI64() throws {
        let value = 9223372036854775807
        let gbln = try toString(value)

        // Should select i64 for values > 2^31-1
        XCTAssertTrue(gbln.contains("<i64>"))
    }

    // MARK: - String Auto-Selection

    func testStringAutoSelectS64() throws {
        let value = "Short"  // 5 characters
        let gbln = try toString(value)

        // Should select s64 for strings ≤64 chars
        XCTAssertTrue(gbln.contains("<s64>"))
    }

    func testStringAutoSelectS256() throws {
        let value = String(repeating: "a", count: 100)  // 100 characters
        let gbln = try toString(value)

        // Should select s256 for strings >64 and ≤256 chars
        XCTAssertTrue(gbln.contains("<s256>"))
    }

    func testStringAutoSelectS1024() throws {
        let value = String(repeating: "a", count: 500)  // 500 characters
        let gbln = try toString(value)

        // Should select s1024 for strings >256 and ≤1024 chars
        XCTAssertTrue(gbln.contains("<s1024>"))
    }

    func testStringTooLong() throws {
        let value = String(repeating: "a", count: 2000)  // > 1024 characters

        // Should throw error for strings > 1024 chars
        XCTAssertThrowsError(try toString(value)) { error in
            XCTAssertTrue(error is GblnError)
            if case .serialiseError(let msg) = error as? GblnError {
                XCTAssertTrue(msg.contains("too long") || msg.contains("max"))
            }
        }
    }

    // MARK: - UTF-8 Character Counting

    func testUTF8CharacterCount() throws {
        let city = "北京"  // 2 characters (6 bytes in UTF-8)
        let gbln = try toString(city)

        // Should count characters, not bytes
        XCTAssertTrue(gbln.contains("北京"))
    }

    func testEmojiCharacterCount() throws {
        let greeting = "Hello👋"  // 6 characters (1 emoji = 1 character)
        let gbln = try toString(greeting)

        XCTAssertTrue(gbln.contains("Hello👋"))
    }

    // MARK: - Bidirectional Conversion

    func testBidirectionalInteger() throws {
        let original = 42

        let gbln = try toString(original)
        let parsed = try parse(gbln)

        XCTAssertEqual(parsed as? Int, original)
    }

    func testBidirectionalFloat() throws {
        let original = 3.14159

        let gbln = try toString(original)
        let parsed = try parse(gbln)

        let value = try XCTUnwrap(parsed as? Double)
        XCTAssertEqual(value, original, accuracy: 0.00001)
    }

    func testBidirectionalString() throws {
        let original = "Hello, GBLN!"

        let gbln = try toString(original)
        let parsed = try parse(gbln)

        XCTAssertEqual(parsed as? String, original)
    }

    func testBidirectionalBool() throws {
        let original = true

        let gbln = try toString(original)
        let parsed = try parse(gbln)

        XCTAssertEqual(parsed as? Bool, original)
    }

    func testBidirectionalObject() throws {
        let original: [String: Any] = [
            "id": 123,
            "name": "Alice",
            "active": true
        ]

        let gbln = try toString(original)
        let parsed = try parse(gbln)

        let dict = try XCTUnwrap(parsed as? [String: Any])
        XCTAssertEqual(dict["id"] as? Int, 123)
        XCTAssertEqual(dict["name"] as? String, "Alice")
        XCTAssertEqual(dict["active"] as? Bool, true)
    }

    func testBidirectionalArray() throws {
        let original = ["rust", "python", "swift"]

        let gbln = try toString(original)
        let parsed = try parse(gbln)

        let array = try XCTUnwrap(parsed as? [Any?])
        XCTAssertEqual(array.count, 3)
        XCTAssertEqual(array[0] as? String, "rust")
        XCTAssertEqual(array[1] as? String, "python")
        XCTAssertEqual(array[2] as? String, "swift")
    }
}
