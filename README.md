# TModLite

Native iOS modding runtime for **Terraria Mobile** — **no jailbreak
required**. Not a tModLoader port: a lean, purpose-built runtime with a
clearly separated platform-independent core and an iOS adapter, injected
into your own, legally purchased copy of Terraria via sideload signing
(Feather or similar).

Architecture details: [CLAUDE.md](CLAUDE.md), [docs/architecture.md](docs/architecture.md).

## What works (verified on a real, non-jailbroken device)

- ✅ **Injection without jailbreak** — via Feather/`insert_dylib`, the dylib
  loads itself automatically when the app starts ([docs/ios-injection.md](docs/ios-injection.md))
- ✅ **IL2CPP bridge** — resolve and call Terraria classes/methods/fields at
  runtime (`dlopen`/`dlsym` against `UnityFramework`, no reverse-engineering
  framework needed) ([docs/il2cpp-bridge.md](docs/il2cpp-bridge.md))
- ✅ **God Mode** — `Player.statLife` polled in real time via the IL2CPP bridge
- ✅ **Native in-game overlay** — a touch-passthrough trigger, a main-menu
  settings panel (mod list with toggles), and a separate in-game panel
  depending on the detected game state
- ✅ **ModLoader with folder scan** — a `manifest.json` per mod folder is
  detected, mods can be enabled/disabled ([docs/modloader.md](docs/modloader.md))

## What's planned but not built (yet)

- ⚠️ **Actually running mod code** — the ModLoader currently only scans
  metadata (`manifest.json`); mods don't carry real code yet
  ([docs/modloader.md](docs/modloader.md))
- ⚠️ **Custom content** (bosses, weapons, companions, recipes, invasion
  triggers, etc.) — thought through in [docs/calamity-architecture.md](docs/calamity-architecture.md),
  but **on hold**: the underlying concept needs behavior-hooking of existing
  Terraria methods, and that doesn't work without a jailbreak (see next point)
- ⚠️ **Android adapter** — iOS only so far
- ⚠️ PlayerLoop integration instead of a poll timer, custom textures,
  persisting mod state — see [docs/roadmap.md](docs/roadmap.md)

## ⚠️ Known limitation

**No behavior-hooking of existing methods without a jailbreak.** iOS
enforces codesigning/W^X — executable memory of a foreign, codesigned
process can't be rewritten at runtime. Two approaches were tested on a real
device (Dobby inline hook, MethodInfo pointer swap), both failed. TModLite
can **call** existing methods (God Mode, menuMode control), but not
**change** their behavior. Details, tested approaches, and what this means
for mod ideas: [docs/technical-limitations.md](docs/technical-limitations.md).

## Screenshots

*(Placeholder — add your own screenshots of the in-game overlay and the
settings panel here once available.)*

## Prerequisites

- Your own, legally purchased copy of Terraria (iOS)
- Your own iOS device — **no jailbreak required**
- A sideload signing tool (e.g. [Feather](https://github.com/khcrysalis/Feather),
  ESign, AltStore) with your own certificate/profile
- Full Xcode (not just Command Line Tools) with the iOS SDK, `xcode-select -p`
  must point at `Xcode.app/Contents/Developer`
- CMake >= 3.20

## Setup: Build → Inject → Test

```bash
# 1. Build the dylib (arm64, real device)
./scripts/build-ios.sh
# -> build-ios/src/platform/ios/libtml_ios_bootstrap.dylib

# 2. Embed it into your own Terraria IPA (e.g. via insert_dylib or
#    Feather's built-in tweak injection) and resign with Feather.

# 3. Install, launch the app, tap the trigger button.
```

Detailed step-by-step instructions including logging tips:
[docs/ios-injection.md](docs/ios-injection.md).

### Desktop build (development/testing, no real game needed)

```bash
cmake -S . -B build
cmake --build build
./build/src/sim/tml_sim
```

Builds `tml_core` (core lib) and `tml_sim` (simulation harness with test
mods, live ASCII visualization). Useful for testing core changes without
needing a device — see the dev workflow in [CLAUDE.md](CLAUDE.md).

### Android build (`tml_core` only, adapter not implemented yet)

```bash
export ANDROID_NDK_HOME=/path/to/ndk
./scripts/build-android.sh
```

## More docs

- [docs/architecture.md](docs/architecture.md) — core/platform separation
- [docs/ios-injection.md](docs/ios-injection.md) — the complete injection workflow
- [docs/il2cpp-bridge.md](docs/il2cpp-bridge.md) — IL2CPP research, what works and why
- [docs/technical-limitations.md](docs/technical-limitations.md) — what doesn't work and why
- [docs/modloader.md](docs/modloader.md) — mod folder scan
- [docs/roadmap.md](docs/roadmap.md) — next steps
- [CONTRIBUTING.md](CONTRIBUTING.md) — build/test/PR expectations

## Disclaimer

For personal use only, with a legally acquired copy of Terraria. No
redistribution of Terraria's own files/assets. This project has no
affiliation with Re-Logic or 505 Games and is not endorsed or authorized by
either. Use at your own risk.
