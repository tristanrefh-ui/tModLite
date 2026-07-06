# iOS Injection Workflow

The complete path from a core build to a running overlay on a real,
non-jailbroken device.

## 1. Build the dylib

```bash
./scripts/build-ios.sh
```

Builds `tml_core` (static) + `tml_ios_bootstrap` (SHARED, arm64, real
device) via `cmake/ios.toolchain.cmake` (leetal/ios-cmake), `PLATFORM=OS64`,
`DEPLOYMENT_TARGET=15.0`. Result: `build-ios/src/platform/ios/libtml_ios_bootstrap.dylib`.

Requirement: full Xcode (not just Command Line Tools) — `xcode-select -p`
must point at `Xcode.app/Contents/Developer`, otherwise the iOS SDK is
missing.

## 2. Get an IPA

Your own, legally purchased Terraria IPA (e.g. downloaded/extracted via
your own Apple account). No redistributing, no sharing — only local
modification of your own copy.

## 3. Embed the dylib into the IPA

- Place `libtml_ios_bootstrap.dylib` as its own framework in
  `Payload/Terraria.app/Frameworks/`.
- The main executable needs an extra `LC_LOAD_DYLIB` load command pointing
  at `@executable_path/Frameworks/libtml_ios_bootstrap.dylib` (standard
  technique: `insert_dylib`, or Feather's built-in tweak injection
  mechanism does this automatically on resign).

## 4. Sign via Feather

Feather (a sideload signing tool) resigns the entire modified IPA with your
own certificate/profile — no jailbreak needed. Feather also re-signs the
embedded dylib itself (every binary in the bundle needs a valid signature
from the same signer).

## 5. Install + test

Install onto the device via Feather. When the app starts:

1. dyld loads all frameworks, including `libtml_ios_bootstrap.dylib`.
2. The `__attribute__((constructor))` block in `Bootstrap.mm` fires
   automatically during dylib loading, **before** the app's `main()`/
   `UIApplicationMain()`.
3. `runtime.start()` runs synchronously.
4. `dispatch_after(1.5s, ...)` delays the actual UIKit work until the host
   app has built its UI (too early and `UIApplication.sharedApplication`
   might not be ready yet).
5. After that: the overlay window (`TMLOverlayWindow`, touch passthrough via
   `hitTest:` override), trigger text, native settings panel.

## Logging while testing

**Important:** use `NSLog`/`os_log` instead of `printf`/`std::cout`. Raw
stdout of a process started via Feather (without an attached debugger) often
doesn't end up in Console.app — `NSLog` does, reliably. This finding came
from real debugging, see `il2cpp-bridge.md`.

Test cycle: `./scripts/build-ios.sh` → re-embed/resign the dylib via
Feather → reinstall → Console.app (select the device, filter for
`[Il2CppBridge]` / `[iOS Bootstrap]` / `[TMLOverlayManager]`).

## Limitation of this injection path

This entire path (Feather/`insert_dylib`, no jailbreak) allows purely
**adding** code (your own dylib) and **calling** existing Terraria methods
via the IL2CPP bridge — it does not allow **changing** existing Terraria
code at runtime (codesigning/W^X prevents that regardless of the chosen
hooking approach). Details and tested approaches:
`technical-limitations.md`.
