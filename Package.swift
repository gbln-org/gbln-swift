// swift-tools-version: 5.7
// Copyright (c) 2025 Vivian Burkhard Voss
// SPDX-License-Identifier: Apache-2.0

import PackageDescription

let package = Package(
    name: "GBLN",
    platforms: [
        .macOS(.v12),
        .iOS(.v15),
        .watchOS(.v8),
        .tvOS(.v15)
    ],
    products: [
        .library(
            name: "GBLN",
            targets: ["GBLN"]
        ),
    ],
    targets: [
        // C module for libgbln C FFI
        .target(
            name: "CGBLN",
            dependencies: [],
            path: "Sources/GBLN/CGBLNModule",
            publicHeadersPath: "include",
            cSettings: [
                .headerSearchPath("include")
            ],
            linkerSettings: [
                .linkedLibrary("gbln"),
                .unsafeFlags(["-L../../core/ffi/libs/macos-arm64"])
            ]
        ),

        // Main Swift library
        .target(
            name: "GBLN",
            dependencies: ["CGBLN"],
            path: "Sources/GBLN",
            exclude: ["CGBLNModule"],
            swiftSettings: [
                .define("GBLN_SWIFT_BINDINGS")
            ]
        ),

        // Test target
        .testTarget(
            name: "GBLNTests",
            dependencies: ["GBLN"],
            path: "Tests/GBLNTests",
            resources: [
                .copy("Fixtures")
            ]
        ),
    ]
)
