// Copyright (c) 2025 Vivian Burkhard Voss
// SPDX-License-Identifier: Apache-2.0

import XCTest
@testable import GBLN

/// Test suite for GBLN parser functionality.
///
/// Tests cover:
/// - Primitive type parsing (integers, floats, strings, bool, null)
/// - Object parsing (simple, nested, empty)
/// - Array parsing (simple, typed, object-array, empty)
/// - UTF-8 string handling
/// - Error cases
final class ParserTests: XCTestCase {

    // MARK: - Integer Parsing

    func testParseI8() throws {
        let result = try parse("<i8>(42)")
        XCTAssertEqual(result as? Int, 42)
    }

    func testParseI16() throws {
        let result = try parse("<i16>(1000)")
        XCTAssertEqual(result as? Int, 1000)
    }

    func testParseI32() throws {
        let result = try parse("<i32>(100000)")
        XCTAssertEqual(result as? Int, 100000)
    }

    func testParseI64() throws {
        let result = try parse("<i64>(9223372036854775807)")
        XCTAssertEqual(result as? Int, 9223372036854775807)
    }

    func testParseU8() throws {
        let result = try parse("<u8>(255)")
        XCTAssertEqual(result as? Int, 255)
    }

    func testParseU16() throws {
        let result = try parse("<u16>(65535)")
        XCTAssertEqual(result as? Int, 65535)
    }

    func testParseU32() throws {
        let result = try parse("<u32>(4294967295)")
        XCTAssertEqual(result as? Int, 4294967295)
    }

    // MARK: - Float Parsing

    func testParseF32() throws {
        let result = try parse("<f32>(3.14159)")
        let value = try XCTUnwrap(result as? Double)
        XCTAssertEqual(value, 3.14159, accuracy: 0.00001)
    }

    func testParseF64() throws {
        let result = try parse("<f64>(2.718281828459045)")
        let value = try XCTUnwrap(result as? Double)
        XCTAssertEqual(value, 2.718281828459045, accuracy: 0.000000000000001)
    }

    // MARK: - String Parsing

    func testParseString() throws {
        let result = try parse("<s32>(Hello, GBLN!)")
        XCTAssertEqual(result as? String, "Hello, GBLN!")
    }

    func testParseStringWithSpaces() throws {
        let result = try parse("<s64>(Alice Johnson)")
        XCTAssertEqual(result as? String, "Alice Johnson")
    }

    func testParseUTF8String() throws {
        let result = try parse("<s16>(北京)")
        XCTAssertEqual(result as? String, "北京")
    }

    func testParseStringWithEmoji() throws {
        let result = try parse("<s32>(Hello👋)")
        XCTAssertEqual(result as? String, "Hello👋")
    }

    // MARK: - Boolean Parsing

    func testParseBoolTrue() throws {
        let result = try parse("<b>(t)")
        XCTAssertEqual(result as? Bool, true)
    }

    func testParseBoolFalse() throws {
        let result = try parse("<b>(f)")
        XCTAssertEqual(result as? Bool, false)
    }

    func testParseBoolTrueLong() throws {
        let result = try parse("<b>(true)")
        XCTAssertEqual(result as? Bool, true)
    }

    func testParseBoolFalseLong() throws {
        let result = try parse("<b>(false)")
        XCTAssertEqual(result as? Bool, false)
    }

    // MARK: - Null Parsing

    func testParseNull() throws {
        let result = try parse("<n>()")
        XCTAssertTrue(result is NSNull)
    }

    func testParseNullLong() throws {
        let result = try parse("<n>(null)")
        XCTAssertTrue(result is NSNull)
    }

    // MARK: - Object Parsing

    func testParseSimpleObject() throws {
        let gblnString = "user{id<u32>(123)name<s32>(Alice)}"
        let result = try parse(gblnString)

        let dict = try XCTUnwrap(result as? [String: Any])
        let user = try XCTUnwrap(dict["user"] as? [String: Any])

        XCTAssertEqual(user["id"] as? Int, 123)
        XCTAssertEqual(user["name"] as? String, "Alice")
    }

    func testParseNestedObject() throws {
        let gblnString = """
        response{
            status<u16>(200)
            data{
                user{
                    id<u32>(12345)
                    name<s64>(Alice)
                }
            }
        }
        """

        let result = try parse(gblnString)

        let dict = try XCTUnwrap(result as? [String: Any])
        let response = try XCTUnwrap(dict["response"] as? [String: Any])
        let data = try XCTUnwrap(response["data"] as? [String: Any])
        let user = try XCTUnwrap(data["user"] as? [String: Any])

        XCTAssertEqual(response["status"] as? Int, 200)
        XCTAssertEqual(user["id"] as? Int, 12345)
        XCTAssertEqual(user["name"] as? String, "Alice")
    }

    func testParseEmptyObject() throws {
        let result = try parse("empty{}")

        let dict = try XCTUnwrap(result as? [String: Any])
        let empty = try XCTUnwrap(dict["empty"] as? [String: Any])

        XCTAssertTrue(empty.isEmpty)
    }

    // MARK: - Array Parsing

    func testParseSimpleArray() throws {
        let result = try parse("tags<s16>[rust python swift]")

        let dict = try XCTUnwrap(result as? [String: Any])
        let tags = try XCTUnwrap(dict["tags"] as? [Any?])

        XCTAssertEqual(tags.count, 3)
        XCTAssertEqual(tags[0] as? String, "rust")
        XCTAssertEqual(tags[1] as? String, "python")
        XCTAssertEqual(tags[2] as? String, "swift")
    }

    func testParseObjectArray() throws {
        let gblnString = "users[{id<u32>(1)name<s32>(Alice)}{id<u32>(2)name<s32>(Bob)}]"
        let result = try parse(gblnString)

        let dict = try XCTUnwrap(result as? [String: Any])
        let users = try XCTUnwrap(dict["users"] as? [Any?])

        XCTAssertEqual(users.count, 2)

        let user1 = try XCTUnwrap(users[0] as? [String: Any])
        XCTAssertEqual(user1["id"] as? Int, 1)
        XCTAssertEqual(user1["name"] as? String, "Alice")

        let user2 = try XCTUnwrap(users[1] as? [String: Any])
        XCTAssertEqual(user2["id"] as? Int, 2)
        XCTAssertEqual(user2["name"] as? String, "Bob")
    }

    func testParseEmptyArray() throws {
        let result = try parse("empty[]")

        let dict = try XCTUnwrap(result as? [String: Any])
        let empty = try XCTUnwrap(dict["empty"] as? [Any?])

        XCTAssertTrue(empty.isEmpty)
    }

    // MARK: - Comments

    func testParseWithComments() throws {
        let gblnString = """
        :| User configuration
        user{
            id<u32>(123)  :| User ID
            name<s32>(Alice)  :| User name
        }
        """

        let result = try parse(gblnString)

        let dict = try XCTUnwrap(result as? [String: Any])
        let user = try XCTUnwrap(dict["user"] as? [String: Any])

        XCTAssertEqual(user["id"] as? Int, 123)
        XCTAssertEqual(user["name"] as? String, "Alice")
    }

    // MARK: - Error Cases

    func testParseInvalidSyntax() throws {
        let gblnString = "user{id<u32>(123)name<s32>(Alice)"  // Missing }

        XCTAssertThrowsError(try parse(gblnString)) { error in
            XCTAssertTrue(error is GblnError)
            if case .parseError(let msg) = error as? GblnError {
                XCTAssertTrue(msg.contains("error") || msg.contains("Error"))
            } else {
                XCTFail("Expected parseError, got \(error)")
            }
        }
    }

    func testParseIntegerOutOfRange() throws {
        let gblnString = "age<i8>(999)"  // 999 out of range for i8 (-128..127)

        XCTAssertThrowsError(try parse(gblnString)) { error in
            XCTAssertTrue(error is GblnError)
        }
    }

    // MARK: - File Parsing

    func testParseFileSimple() throws {
        let bundle = Bundle.module
        guard let path = bundle.path(forResource: "simple", ofType: "gbln", inDirectory: "Fixtures/valid") else {
            XCTFail("Test fixture not found")
            return
        }

        let result = try parseFile(at: path)

        let dict = try XCTUnwrap(result as? [String: Any])
        XCTAssertEqual(dict["age"] as? Int, 25)
    }

    func testParseFileNested() throws {
        let bundle = Bundle.module
        guard let path = bundle.path(forResource: "nested", ofType: "gbln", inDirectory: "Fixtures/valid") else {
            XCTFail("Test fixture not found")
            return
        }

        let result = try parseFile(at: path)

        let dict = try XCTUnwrap(result as? [String: Any])
        let response = try XCTUnwrap(dict["response"] as? [String: Any])

        XCTAssertEqual(response["status"] as? Int, 200)
        XCTAssertEqual(response["message"] as? String, "Success")
    }
}
