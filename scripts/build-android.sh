#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
BUILD_DIR="$REPO_ROOT/build-android"
ABI="arm64-v8a"

if [[ -z "${ANDROID_NDK_HOME:-}" ]]; then
    echo "Fehler: ANDROID_NDK_HOME ist nicht gesetzt." >&2
    echo "" >&2
    echo "NDK installieren:" >&2
    echo "  Android Studio -> Settings -> Languages & Frameworks -> Android SDK" >&2
    echo "  -> Tab 'SDK Tools' -> Haekchen bei 'NDK (Side by side)' -> Apply" >&2
    echo "" >&2
    echo "Danach ANDROID_NDK_HOME setzen, z.B.:" >&2
    echo "  export ANDROID_NDK_HOME=\$HOME/Library/Android/sdk/ndk/<version>" >&2
    exit 1
fi

TOOLCHAIN_FILE="$ANDROID_NDK_HOME/build/cmake/android.toolchain.cmake"

if [[ ! -f "$TOOLCHAIN_FILE" ]]; then
    echo "Fehler: Toolchain-File nicht gefunden: $TOOLCHAIN_FILE" >&2
    echo "ANDROID_NDK_HOME ($ANDROID_NDK_HOME) zeigt nicht auf eine gueltige NDK-Installation." >&2
    exit 1
fi

echo "Konfiguriere Android-Build (ABI=$ABI)..."
cmake -S "$REPO_ROOT" -B "$BUILD_DIR" \
    -DCMAKE_TOOLCHAIN_FILE="$TOOLCHAIN_FILE" \
    -DANDROID_ABI="$ABI"

echo "Baue tml_core..."
cmake --build "$BUILD_DIR" --target tml_core

LIB_PATH=$(find "$BUILD_DIR" -name "libtml_core.a" -print -quit)
if [[ -z "$LIB_PATH" ]]; then
    echo "Fehler: libtml_core.a wurde nicht gefunden." >&2
    exit 1
fi

echo ""
echo "Android-Build erfolgreich: $LIB_PATH"
