#!/bin/bash
# Script to run Swift tests with proper library paths

export DYLD_LIBRARY_PATH="$(pwd)/../../core/ffi/libs/macos-arm64:/opt/homebrew/opt/xz/lib"
export DYLD_FALLBACK_LIBRARY_PATH="$DYLD_LIBRARY_PATH"

# Copy library to build directory
mkdir -p .build/debug
cp ../../core/ffi/libs/macos-arm64/libgbln.dylib .build/debug/

echo "Running Swift tests with library path: $DYLD_LIBRARY_PATH"
swift test -v
