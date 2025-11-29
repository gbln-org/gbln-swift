// Copyright (c) 2025 Vivian Burkhard Voss
// SPDX-License-Identifier: Apache-2.0

import CGBLN
import Foundation

/// Configuration for GBLN I/O operations.
///
/// Controls how GBLN values are serialised to files:
/// - **MINI mode**: Compact format without whitespace (optimised for LLMs)
/// - **Compression**: XZ compression for smaller file sizes
/// - **Indentation**: Number of spaces for pretty-printing
/// - **Comments**: Whether to strip comments during serialisation
///
/// # Examples
///
/// ```swift
/// // Production I/O format (default)
/// let ioConfig = GblnConfig.io
/// // → MINI GBLN + XZ compression
///
/// // Human-readable source format
/// let sourceConfig = GblnConfig.source
/// // → Pretty-printed, no compression
///
/// // Custom configuration
/// var custom = GblnConfig()
/// custom.miniMode = false
/// custom.compress = false
/// custom.indent = 4
/// ```
public struct GblnConfig {
    /// Use MINI GBLN format (no whitespace between elements).
    ///
    /// - `true`: Compact format for production/LLM use
    /// - `false`: Pretty-printed with newlines and indentation
    public var miniMode: Bool

    /// Enable XZ compression when writing files.
    ///
    /// Compressed files use `.io.gbln.xz` extension.
    public var compress: Bool

    /// XZ compression level (0-9).
    ///
    /// - `0`: No compression (fastest)
    /// - `6`: Default balance (recommended)
    /// - `9`: Maximum compression (slowest)
    public var compressionLevel: UInt8

    /// Indentation width for pretty-printing.
    ///
    /// Number of spaces per indentation level.
    /// Only applies when `miniMode = false`.
    public var indent: Int

    /// Strip comments from output.
    ///
    /// - `true`: Remove all `:| ...` comments
    /// - `false`: Preserve comments in output
    public var stripComments: Bool

    /// Default I/O format configuration.
    ///
    /// Optimised for production use and LLM contexts:
    /// - MINI GBLN (compact)
    /// - XZ compression enabled
    /// - Compression level 6
    /// - Comments stripped
    public static let io = GblnConfig(
        miniMode: true,
        compress: true,
        compressionLevel: 6,
        indent: 2,
        stripComments: true
    )

    /// Default source format configuration.
    ///
    /// Optimised for human-readable source files:
    /// - Pretty-printed with newlines
    /// - No compression
    /// - 2-space indentation
    /// - Comments preserved
    public static let source = GblnConfig(
        miniMode: false,
        compress: false,
        compressionLevel: 6,
        indent: 2,
        stripComments: false
    )

    /// Create configuration with default I/O settings.
    ///
    /// Equivalent to `GblnConfig.io`.
    public init() {
        self.miniMode = true
        self.compress = true
        self.compressionLevel = 6
        self.indent = 2
        self.stripComments = true
    }

    /// Create configuration with custom settings.
    ///
    /// - Parameters:
    ///   - miniMode: Use MINI GBLN format (default: true)
    ///   - compress: Enable XZ compression (default: true)
    ///   - compressionLevel: XZ level 0-9 (default: 6)
    ///   - indent: Indentation width (default: 2)
    ///   - stripComments: Remove comments (default: true)
    public init(
        miniMode: Bool = true,
        compress: Bool = true,
        compressionLevel: UInt8 = 6,
        indent: Int = 2,
        stripComments: Bool = true
    ) {
        self.miniMode = miniMode
        self.compress = compress
        self.compressionLevel = compressionLevel
        self.indent = indent
        self.stripComments = stripComments
    }
}

// MARK: - Internal C FFI Conversion

internal extension GblnConfig {
    /// Convert to C GblnConfig pointer.
    ///
    /// Creates a C-compatible configuration struct for passing to FFI functions.
    ///
    /// - Returns: Opaque pointer to C GblnConfig (caller must free with `gbln_config_free`)
    func toCPointer() -> OpaquePointer {
        return gbln_config_new(
            miniMode,
            compress,
            compressionLevel,
            UInt(indent),
            stripComments
        )!
    }
}
