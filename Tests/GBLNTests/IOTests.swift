// Copyright (c) 2025 Vivian Burkhard Voss
// SPDX-License-Identifier: Apache-2.0

import XCTest
@testable import GBLN

/// Test suite for GBLN I/O operations.
///
/// Tests cover:
/// - Writing and reading I/O format files
/// - Compression and decompression
/// - Configuration options
final class IOTests: XCTestCase {

    var tempDir: URL!

    override func setUp() {
        super.setUp()
        tempDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try? FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
    }

    override func tearDown() {
        try? FileManager.default.removeItem(at: tempDir)
        super.tearDown()
    }

    // MARK: - I/O Format Write/Read

    func testWriteReadSimpleValue() throws {
        let original: [String: Any] = ["id": 123, "name": "Alice"]
        let path = tempDir.appendingPathComponent("test.io.gbln.xz").path

        try writeIo(original, to: path)
        let loaded = try readIo(from: path)

        let dict = try XCTUnwrap(loaded as? [String: Any])
        XCTAssertEqual(dict["id"] as? Int, 123)
        XCTAssertEqual(dict["name"] as? String, "Alice")
    }

    func testWriteReadComplexStructure() throws {
        let original: [String: Any] = [
            "user": [
                "id": 12345,
                "name": "Alice Johnson",
                "verified": true,
                "tags": ["admin", "moderator"]
            ]
        ]

        let path = tempDir.appendingPathComponent("test-complex.io.gbln.xz").path

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

    // MARK: - Configuration Options

    func testWriteWithoutCompression() throws {
        let original: [String: Any] = ["id": 123, "name": "Alice"]
        let path = tempDir.appendingPathComponent("test-nocomp.io.gbln").path

        var config = GblnConfig()
        config.compress = false

        try writeIo(original, to: path, config: config)
        let loaded = try readIo(from: path)

        let dict = try XCTUnwrap(loaded as? [String: Any])
        XCTAssertEqual(dict["id"] as? Int, 123)
    }

    func testWriteSourceFormat() throws {
        let original: [String: Any] = ["id": 123, "name": "Alice"]
        let path = tempDir.appendingPathComponent("test-source.gbln").path

        try writeIo(original, to: path, config: .source)
        let loaded = try readIo(from: path)

        let dict = try XCTUnwrap(loaded as? [String: Any])
        XCTAssertEqual(dict["id"] as? Int, 123)
    }

    // MARK: - UTF-8 Handling

    func testWriteReadUTF8() throws {
        let original = ["city": "北京", "greeting": "Hello👋"]
        let path = tempDir.appendingPathComponent("test-utf8.io.gbln.xz").path

        try writeIo(original, to: path)
        let loaded = try readIo(from: path)

        let dict = try XCTUnwrap(loaded as? [String: Any])
        XCTAssertEqual(dict["city"] as? String, "北京")
        XCTAssertEqual(dict["greeting"] as? String, "Hello👋")
    }

    // MARK: - Error Handling

    func testReadNonexistentFile() throws {
        let path = tempDir.appendingPathComponent("nonexistent.io.gbln.xz").path

        XCTAssertThrowsError(try readIo(from: path)) { error in
            XCTAssertTrue(error is GblnError)
            if case .ioError = error as? GblnError {
                // Expected I/O error
            } else {
                XCTFail("Expected ioError, got \(error)")
            }
        }
    }

    // MARK: - Async Operations

    func testAsyncWriteRead() async throws {
        let original: [String: Any] = ["id": 123, "name": "Alice"]
        let path = tempDir.appendingPathComponent("test-async.io.gbln.xz").path

        try await writeIoAsync(original, to: path)
        let loaded = try await readIoAsync(from: path)

        let dict = try XCTUnwrap(loaded as? [String: Any])
        XCTAssertEqual(dict["id"] as? Int, 123)
        XCTAssertEqual(dict["name"] as? String, "Alice")
    }
}
