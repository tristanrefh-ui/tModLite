#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
TOOLCHAIN_FILE="$REPO_ROOT/cmake/ios.toolchain.cmake"
BUILD_DIR="$REPO_ROOT/build-ios"
PLATFORM="OS64"
DEPLOYMENT_TARGET="15.0"

if ! command -v xcode-select >/dev/null 2>&1; then
    echo "Fehler: xcode-select nicht gefunden. Xcode Command Line Tools installieren:" >&2
    echo "  xcode-select --install" >&2
    exit 1
fi

if ! xcrun --sdk iphoneos --show-sdk-path >/dev/null 2>&1; then
    echo "Fehler: Keine iOS-SDK ueber xcrun erreichbar." >&2
    echo "Aktuelle Developer-Dir: $(xcode-select -p 2>/dev/null || echo unbekannt)" >&2
    echo "Fuer iOS-Cross-Compiles wird volles Xcode benoetigt, nicht nur die CommandLineTools." >&2
    echo "Umschalten mit:" >&2
    echo "  sudo xcode-select -s /Applications/Xcode.app/Contents/Developer" >&2
    exit 1
fi

if [[ ! -f "$TOOLCHAIN_FILE" ]]; then
    echo "Fehler: Toolchain-File nicht gefunden: $TOOLCHAIN_FILE" >&2
    echo "Erwartet wird cmake/ios.toolchain.cmake (leetal/ios-cmake) im Repo-Root." >&2
    exit 1
fi

echo "Konfiguriere iOS-Build (PLATFORM=$PLATFORM, DEPLOYMENT_TARGET=$DEPLOYMENT_TARGET)..."
cmake -S "$REPO_ROOT" -B "$BUILD_DIR" \
    -DCMAKE_TOOLCHAIN_FILE="$TOOLCHAIN_FILE" \
    -DPLATFORM="$PLATFORM" \
    -DDEPLOYMENT_TARGET="$DEPLOYMENT_TARGET"

echo "Baue tml_core und tml_ios_bootstrap..."
cmake --build "$BUILD_DIR" --target tml_core --target tml_ios_bootstrap

CORE_LIB_PATH=$(find "$BUILD_DIR" -name "libtml_core.a" -print -quit)
if [[ -z "$CORE_LIB_PATH" ]]; then
    echo "Fehler: libtml_core.a wurde nicht gefunden." >&2
    exit 1
fi

BOOTSTRAP_LIB_PATH=$(find "$BUILD_DIR" -name "libtml_ios_bootstrap.dylib" -print -quit)
if [[ -z "$BOOTSTRAP_LIB_PATH" ]]; then
    echo "Fehler: libtml_ios_bootstrap.dylib wurde nicht gefunden." >&2
    exit 1
fi

echo ""
echo "iOS-Build erfolgreich:"
echo "  Core:      $CORE_LIB_PATH"
echo "  Bootstrap: $BOOTSTRAP_LIB_PATH"
