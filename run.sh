#!/usr/bin/env bash

set -e

# 0. Check if build/.build_hash exists
# 1. Calculate hashes of all dart files in any lib/ folder + pubspec.yaml files
# 2. Compare hashes to previous hashes (if previous hashes exist)
# 3. If hashes are different or we had no hash file, compile rkdb
# 4. If hashes are the same, use existing binary

# Create build directory if it doesn't exist
mkdir -p build

# Function to calculate hash of all relevant files
calculate_hash() {
    # Find all Dart files in lib/ directories and pubspec.yaml files
    find . -name "*.dart" -path "*/lib/*" -o -name "pubspec.yaml" | sort | xargs sha256sum | sha256sum | cut -d' ' -f1
}

# Get current hash
CURRENT_HASH=$(calculate_hash)

# Check if build hash file exists and read previous hash
BUILD_HASH_FILE="build/.build_hash"
if [ -f "$BUILD_HASH_FILE" ]; then
    PREVIOUS_HASH=$(cat "$BUILD_HASH_FILE")
else
    PREVIOUS_HASH=""
fi

# Check if binary exists
BINARY_PATH="build/rkdb"
BINARY_EXISTS=false
if [ -f "$BINARY_PATH" ]; then
    BINARY_EXISTS=true
fi

# Compile if hashes are different, no hash file exists, or binary doesn't exist
if [ "$CURRENT_HASH" != "$PREVIOUS_HASH" ] || [ ! -f "$BUILD_HASH_FILE" ] || [ "$BINARY_EXISTS" = false ]; then
    echo "Compiling rkdb..."

    dart pub get
    dart compile exe bin/rkdb.dart -o "$BINARY_PATH"

    # Save the current hash
    echo "$CURRENT_HASH" > "$BUILD_HASH_FILE"

    echo "Compilation complete."
else
    echo "Using existing binary (no changes detected)."
fi

# Execute the binary with all passed arguments
"$BINARY_PATH" "$@"
