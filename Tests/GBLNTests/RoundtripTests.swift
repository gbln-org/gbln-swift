// Copyright (c) 2025 Vivian Burkhard Voss
// SPDX-License-Identifier: Apache-2.0

import XCTest
@testable import GBLN

/// Test suite for round-trip conversions (Swift → GBLN → Swift).
///
/// Verifies that data survives serialisation and parsing without loss.
final class RoundtripTests: XCTestCase {

    // MARK: - Simple Types

    func testRoundtripInteger() throws {
        let original = 42

        let gbln = try toString(original)
        let parsed = try parse(gbln)

        XCTAssertEqual(parsed as? Int, original)
    }

    func testRoundtripFloat() throws {
        let original = 3.14159265359

        let gbln = try toString(original)
        let parsed = try parse(gbln)

        let value = try XCTUnwrap(parsed as? Double)
        XCTAssertEqual(value, original, accuracy: 0.0000000001)
    }

    func testRoundtripString() throws {
        let original = "Hello, GBLN World!"

        let gbln = try toString(original)
        let parsed = try parse(gbln)

        XCTAssertEqual(parsed as? String, original)
    }

    func testRoundtripBool() throws {
        let original = true

        let gbln = try toString(original)
        let parsed = try parse(gbln)

        XCTAssertEqual(parsed as? Bool, original)
    }

    // MARK: - Complex Structures

    func testRoundtripSimpleObject() throws {
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

    func testRoundtripNestedObject() throws {
        let original: [String: Any] = [
            "response": [
                "status": 200,
                "data": [
                    "user": [
                        "id": 12345,
                        "name": "Alice Johnson"
                    ]
                ]
            ]
        ]

        let gbln = try toString(original)
        let parsed = try parse(gbln)

        let dict = try XCTUnwrap(parsed as? [String: Any])
        let response = try XCTUnwrap(dict["response"] as? [String: Any])
        let data = try XCTUnwrap(response["data"] as? [String: Any])
        let user = try XCTUnwrap(data["user"] as? [String: Any])

        XCTAssertEqual(response["status"] as? Int, 200)
        XCTAssertEqual(user["id"] as? Int, 12345)
        XCTAssertEqual(user["name"] as? String, "Alice Johnson")
    }

    func testRoundtripArray() throws {
        let original = ["rust", "python", "swift", "kotlin"]

        let gbln = try toString(original)
        let parsed = try parse(gbln)

        let array = try XCTUnwrap(parsed as? [Any?])
        XCTAssertEqual(array.count, original.count)

        for i in 0..<original.count {
            XCTAssertEqual(array[i] as? String, original[i])
        }
    }

    func testRoundtripObjectArray() throws {
        let original: [[String: Any]] = [
            ["id": 1, "name": "Alice"],
            ["id": 2, "name": "Bob"],
            ["id": 3, "name": "Charlie"]
        ]

        let gbln = try toString(original)
        let parsed = try parse(gbln)

        let array = try XCTUnwrap(parsed as? [Any?])
        XCTAssertEqual(array.count, original.count)

        for i in 0..<original.count {
            let obj = try XCTUnwrap(array[i] as? [String: Any])
            XCTAssertEqual(obj["id"] as? Int, original[i]["id"] as? Int)
            XCTAssertEqual(obj["name"] as? String, original[i]["name"] as? String)
        }
    }

    // MARK: - UTF-8 Round-trip

    func testRoundtripUTF8() throws {
        let original: [String: Any] = [
            "city": "北京",
            "greeting": "Hello👋",
            "japanese": "こんにちは",
            "russian": "Привет"
        ]

        let gbln = try toString(original)
        let parsed = try parse(gbln)

        let dict = try XCTUnwrap(parsed as? [String: Any])
        XCTAssertEqual(dict["city"] as? String, "北京")
        XCTAssertEqual(dict["greeting"] as? String, "Hello👋")
        XCTAssertEqual(dict["japanese"] as? String, "こんにちは")
        XCTAssertEqual(dict["russian"] as? String, "Привет")
    }

    // MARK: - I/O Format Round-trip

    func testRoundtripIOFormat() throws {
        let original: [String: Any] = [
            "user": [
                "id": 12345,
                "name": "Alice Johnson",
                "verified": true,
                "tags": ["admin", "moderator"]
            ]
        ]

        let tempDir = FileManager.default.temporaryDirectory
        let path = tempDir.appendingPathComponent("roundtrip-\(UUID().uuidString).io.gbln.xz").path

        defer {
            try? FileManager.default.removeItem(atPath: path)
        }

        try writeIo(original, to: path)
        let loaded = try readIo(from: path)

        let dict = try XCTUnwrap(loaded as? [String: Any])
        let user = try XCTUnwrap(dict["user"] as? [String: Any])

        XCTAssertEqual(user["id"] as? Int, 12345)
        XCTAssertEqual(user["name"] as? String, "Alice Johnson")
        XCTAssertEqual(user["verified"] as? Bool, true)

        let tags = try XCTUnwrap(user["tags"] as? [Any?])
        XCTAssertEqual(tags.count, 2)
        XCTAssertEqual(tags[0] as? String, "admin")
        XCTAssertEqual(tags[1] as? String, "moderator")
    }

    // MARK: - Edge Cases

    func testRoundtripEmptyObject() throws {
        let original: [String: Any] = [:]

        let gbln = try toString(original)
        let parsed = try parse(gbln)

        let dict = try XCTUnwrap(parsed as? [String: Any])
        XCTAssertTrue(dict.isEmpty)
    }

    func testRoundtripEmptyArray() throws {
        let original: [Any] = []

        let gbln = try toString(original)
        let parsed = try parse(gbln)

        let array = try XCTUnwrap(parsed as? [Any?])
        XCTAssertTrue(array.isEmpty)
    }
}
