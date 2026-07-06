# Dobby (vendored, prebuilt)

Quelle: offizielles Release-Asset `dobby-iphoneos-all.tar.gz` von
https://github.com/jmpews/Dobby (Tag `latest`, veroeffentlicht 2024-03-14).

Warum vorgebaut statt Source/FetchContent:
- `git clone` ueber FetchContent(GIT_REPOSITORY) haengt sich in dieser
  Entwicklungsumgebung beim git-smart-HTTP-Transport auf (gleiches Problem
  wie bei nlohmann/json, siehe Root-`CMakeLists.txt`) - reine HTTPS-Downloads
  von Release-Assets funktionieren dagegen zuverlaessig.
- Dobbys eigenes CMake-Buildsystem ist auf eigenstaendige Cross-Compile-Aufrufe
  zugeschnitten (eigene Toolchain-Flags), nicht auf sauberes `add_subdirectory`
  in ein bestehendes iOS-Toolchain-Setup - das offizielle Release-Asset
  enthaelt bereits fertige, von den Dobby-Maintainern selbst gebaute
  `.a`-Dateien und macht dieses Risiko komplett irrelevant.

## Inhalt

- `include/dobby.h` - oeffentliche C-API (`DobbyHook`, `DobbyDestroy`,
  `DobbyGetVersion`, ...).
- `lib/ios/libdobby.a` - universelle (fat) statische Lib, Architekturen
  `arm64` + `arm64e` (per `lipo -info` verifiziert). Der Linker waehlt beim
  Linken automatisch die zur Zielarchitektur passende Slice - unser
  `build-ios.sh` baut aktuell fuer `arm64` (PLATFORM=OS64).

## Aktualisieren

Neueren Tarball von der Releases-Seite des Dobby-Repos laden, `dobby.h` und
die passende `.a` aus `build/iphoneos/universal/` hier ersetzen.
