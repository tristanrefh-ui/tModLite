# Dobby (vendored, prebuilt)

Source: the official release asset `dobby-iphoneos-all.tar.gz` from
https://github.com/jmpews/Dobby (tag `latest`, published 2024-03-14).

Why prebuilt instead of source/FetchContent:
- `git clone` via `FetchContent(GIT_REPOSITORY)` hangs in this development
  environment on the git-smart-HTTP transport (same problem as with
  nlohmann/json, see the root `CMakeLists.txt`) — plain HTTPS downloads of
  release assets work reliably instead.
- Dobby's own CMake build system is tailored to standalone cross-compile
  invocations (its own toolchain flags), not to a clean `add_subdirectory`
  into an existing iOS toolchain setup — the official release asset already
  contains finished `.a` files built by the Dobby maintainers themselves,
  making that risk completely irrelevant.

## Contents

- `include/dobby.h` — the public C API (`DobbyHook`, `DobbyDestroy`,
  `DobbyGetVersion`, ...).
- `lib/ios/libdobby.a` — a universal (fat) static lib, architectures
  `arm64` + `arm64e` (verified via `lipo -info`). The linker automatically
  picks the slice matching the target architecture — our `build-ios.sh`
  currently builds for `arm64` (`PLATFORM=OS64`).

## Updating

Download a newer tarball from the Dobby repo's releases page, replace
`dobby.h` and the matching `.a` from `build/iphoneos/universal/` here.
