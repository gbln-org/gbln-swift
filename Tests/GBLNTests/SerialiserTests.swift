// Copyright (c) 2025 Vivian Burkhard Voss
// SPDX-License-Identifier: Apache-2.0

import XCTest
@testable import GBLN

/// Test suite for GBLN serialiser functionality.
///
/// Tests cover:
/// - Primitive type serialisation
/// - Object serialisation
/// - Array serialisation
/// - MINI vs. pretty-printed output
final class SerialiserTests: XCTestCase {

    // MARK: - Primitive Serialisation

    func testSerialiseInteger() throws {
        let gbln = try toString(42)
        XCTAssertTrue(gbln.contains("(42)"))
    }

    func testSerialiseFloat() throws {
        let gbln = try toString(3.14159)
        XCTAssertTrue(gbln.contains("3.14159"))
    }

    func testSerialiseString() throws {
        let gbln = try toString("Hello")
        XCTAssertTrue(gbln.contains("Hello"))
    }

    func testSerialiseBoolTrue() throws {
        let gbln = try toString(true)
        XCTAssertTrue(gbln.contains("<b>") && gbln.contains("(t)"))
    }

    func testSerialiseBoolFalse() throws {
        let gbln = try toString(false)
        XCTAssertTrue(gbln.contains("<b>") && gbln.contains("(f)"))
    }

    // MARK: - Object Serialisation

    func testSerialiseSimpleObject() throws {
        let user: [String: Any] = [
            "id": 123,
            "name": "Alice"
        ]

        let gbln = try toString(user)

        XCTAssertTrue(gbln.contains("id"))
        XCTAssertTrue(gbln.contains("123"))
        XCTAssertTrue(gbln.contains("name"))
        XCTAssertTrue(gbln.contains("Alice"))
    }

    func testSerialiseNestedObject() throws {
        let data: [String: Any] = [
            "user": [
                "id": 123,
                "name": "Alice"
            ]
        ]

        let gbln = try toString(data)

        XCTAssertTrue(gbln.contains("user"))
        XCTAssertTrue(gbln.contains("id"))
        XCTAssertTrue(gbln.contains("123"))
        XCTAssertTrue(gbln.contains("name"))
        XCTAssertTrue(gbln.contains("Alice"))
    }

    func testSerialiseEmptyObject() throws {
        let empty: [String: Any] = [:]

        let gbln = try toString(empty)

        XCTAssertTrue(gbln.contains("{}"))
    }

    // MARK: - Array Serialisation

    func testSerialiseSimpleArray() throws {
        let tags = ["rust", "python", "swift"]

        let gbln = try toString(tags)

        XCTAssertTrue(gbln.contains("rust"))
        XCTAssertTrue(gbln.contains("python"))
        XCTAssertTrue(gbln.contains("swift"))
        XCTAssertTrue(gbln.contains("[") && gbln.contains("]"))
    }

    func testSerialiseObjectArray() throws {
        let users: [[String: Any]] = [
            ["id": 1, "name": "Alice"],
            ["id": 2, "name": "Bob"]
        ]

        let gbln = try toString(users)

        XCTAssertTrue(gbln.contains("id"))
        XCTAssertTrue(gbln.contains("Alice"))
        XCTAssertTrue(gbln.contains("Bob"))
        XCTAssertTrue(gbln.contains("[") && gbln.contains("]"))
    }

    func testSerialiseEmptyArray() throws {
        let empty: [Any] = []

        let gbln = try toString(empty)

        XCTAssertTrue(gbln.contains("[]"))
    }

    // MARK: - MINI vs. Pretty

    func testSerialiseMiniFormat() throws {
        let user: [String: Any] = [
            "id": 123,
            "name": "Alice"
        ]

        let gbln = try toString(user, mini: true)

        // MINI format should not have extra whitespace
        XCTAssertFalse(gbln.contains("\n"))
    }

    func testSerialisePrettyFormat() throws {
        let user: [String: Any] = [
            "id": 123,
            "name": "Alice"
        ]

        let gbln = try toStringPretty(user)

        // Pretty format should have newlines
        XCTAssertTrue(gbln.contains("\n"))
    }

    // MARK: - UTF-8 Strings

    func testSerialiseUTF8String() throws {
        let city = "北京"

        let gbln = try toString(city)

        XCTAssertTrue(gbln.contains("北京"))
    }

    func testSerialiseStringWithEmoji() throws {
        let greeting = "Hello👋"

        let gbln = try toString(greeting)

        XCTAssertTrue(gbln.contains("Hello👋"))
    }

    // MARK: - Complex Structures

    func testSerialiseComplexStructure() throws {
        let data: [String: Any] = [
            "response": [
                "status": 200,
                "message": "Success",
                "data": [
                    "user": [
                        "id": 12345,
                        "name": "Alice Johnson",
                        "verified": true,
                        "tags": ["admin", "moderator"]
                    ]
                ]
            ]
        ]

        let gbln = try toString(data)

        XCTAssertTrue(gbln.contains("response"))
        XCTAssertTrue(gbln.contains("200"))
        XCTAssertTrue(gbln.contains("Success"))
        XCTAssertTrue(gbln.contains("user"))
        XCTAssertTrue(gbln.contains("12345"))
        XCTAssertTrue(gbln.contains("Alice Johnson"))
        XCTAssertTrue(gbln.contains("admin"))
        XCTAssertTrue(gbln.contains("moderator"))
    }
}
