# tModLite

Mobile-first Modding Runtime fuer Terraria (iOS/Android). Kein tModLoader-Port.
Details zur Architektur: [CLAUDE.md](CLAUDE.md).

## Desktop-Build (Entwicklung/Tests)

Voraussetzungen: CMake >= 3.20, C++17-Compiler (Xcode Command Line Tools reichen).

```bash
cmake -S . -B build
cmake --build build
./build/src/sim/tml_sim
```

Alternativ direkt in CLion oeffnen (Root-`CMakeLists.txt`). Baut `tml_core`
(Core-Lib) und `tml_sim` (Simulation Harness mit Test-Mods).

## iOS-Build (nur `tml_core`)

Voraussetzungen: volles Xcode (nicht nur die Command Line Tools) mit
iOS-SDK. `xcode-select -p` muss auf `Xcode.app/Contents/Developer` zeigen,
sonst: `sudo xcode-select -s /Applications/Xcode.app/Contents/Developer`.

```bash
./scripts/build-ios.sh
```

Baut nach `build-ios/`, `PLATFORM=OS64` (arm64, echtes Device),
`DEPLOYMENT_TARGET=15.0`. Nutzt `cmake/ios.toolchain.cmake`
([leetal/ios-cmake](https://github.com/leetal/ios-cmake)). Kein Signing,
kein Deployment — nur Compile-Verifikation der Core-Lib.

## Android-Build (nur `tml_core`)

Voraussetzungen: Android NDK installiert, `ANDROID_NDK_HOME` gesetzt
(z. B. via Android Studio -> SDK Manager -> Tab "SDK Tools" -> "NDK
(Side by side)").

```bash
export ANDROID_NDK_HOME=/pfad/zum/ndk
./scripts/build-android.sh
```

Baut nach `build-android/`, `ABI=arm64-v8a`. Nutzt das Toolchain-File,
das mit dem NDK mitgeliefert wird (`android.toolchain.cmake`).

## Platform-Layer

`src/platform/ios/` und `src/platform/android/` sind noch leer. Injection-
und Hooking-Code kommt erst, wenn der Core-Build fuer beide Plattformen
sauber durchlaeuft — siehe Dev-Workflow in [CLAUDE.md](CLAUDE.md).
