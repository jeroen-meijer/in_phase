#!/usr/bin/env bash

set -e

# Compiles tool/playlist_length.dart when sources change, then runs it.
# Mirrors run.sh: hash lib/**/*.dart + pubspec.yaml + the tool entrypoint.

THIS_SCRIPT_DIR=$(dirname "$0")
pushd "$THIS_SCRIPT_DIR" > /dev/null

print_grey() {
    echo -e "\033[90m$1\033[0m"
}

mkdir -p build

calculate_hash() {
    {
        find . -name "*.dart" -path "*/lib/*" -o -name "pubspec.yaml"
        echo "./tool/playlist_length.dart"
    } | sort -u | xargs sha256sum | sha256sum | cut -d' ' -f1
}

CURRENT_HASH=$(calculate_hash)

BUILD_HASH_FILE="build/.playlist_length_build_hash"
if [ -f "$BUILD_HASH_FILE" ]; then
    PREVIOUS_HASH=$(cat "$BUILD_HASH_FILE")
else
    PREVIOUS_HASH=""
fi

BINARY_PATH="build/playlist_length"
BINARY_EXISTS=false
if [ -f "$BINARY_PATH" ]; then
    BINARY_EXISTS=true
fi

if [ "$CURRENT_HASH" != "$PREVIOUS_HASH" ] || [ ! -f "$BUILD_HASH_FILE" ] || [ "$BINARY_EXISTS" = false ]; then
    print_grey "Compiling playlist_length..."

    dart pub get
    dart compile exe tool/playlist_length.dart -o "$BINARY_PATH"

    echo "$CURRENT_HASH" > "$BUILD_HASH_FILE"

    print_grey "Compilation complete."
fi

"$BINARY_PATH" "$@"

popd > /dev/null
