# tModLite

Mobile-first Modding Runtime für Terraria (iOS/Android). Kein tModLoader-Port.
Eigene Runtime mit klar getrenntem Shared Core und Platform Adaptern.

## Architecture

```
src/
  core/         Shared Core (C++17, plattformunabhängig)
  platform/
    ios/        iOS Adapter: dylib entry, injection bootstrap, hooking backend
    android/    Android Adapter: .so injection, process attach, hooking backend
  sim/          Simulation Harness zum Testen ohne echtes Game
docs/           Detail-Notizen (Injection-Konzept, Hooking, Signing-Workflow etc.)
```

### Core Components (src/core/)
- `Runtime` — start(), tick(), shutdown()
- `EventBus` — register(event), emit(event)
- `Mod` — OnLoad(), OnUpdate(), OnUnload()
- `ModLoader` — scannt mods folder, lädt Module, registriert Hooks
- `GameContext` — Abstraktion für Player/World/Entities

### Hard Rule
**Core darf NIE wissen, wie er ins Spiel injiziert wird.**
- Kein iOS/Android-spezifischer Code in `src/core/`
- Keine Injection-Details, keine Offsets, kein Memory-Hacking im Core
- Core kommuniziert nur über die `GameContext`-Abstraktion

## Tech Stack
- C++17, CMake Build
- iOS Cross-Compile: `ios.toolchain.cmake`, finales Signing/Deployment über Xcode-Tooling
- Android Cross-Compile: NDK-Toolchain via CMake
- Sideload-Signing (ESign/Feather/AltStore), kein Jailbreak nötig

## Conventions
- Naming: `PascalCase` für Klassen, `camelCase` für Methoden
- Header/Source getrennt (`.hpp` / `.cpp`)
- Jede neue Core-Klasse braucht einen Test im Simulation Harness, bevor Platform-Layer angefasst wird

## Dev Workflow (Reihenfolge einhalten)
1. Core-Feature implementieren
2. In der Simulation (`src/sim/`) testen — 60 FPS Update-Loop, Fake Player/World State
3. Erst danach: Platform-Layer (iOS/Android) anfassen

## Current Sprint Focus
<!-- Hier aktualisieren, was gerade dran ist -->
- [ ] Runtime + EventBus Grundgerüst
- [ ] Simulation Test Harness
- [ ] Erste Test-Mod im Simulator

## Known Issues / Open TODOs
<!-- Hier laufend pflegen statt in den Chat-Verlauf zu schreiben -->

## Notes
Größere Doku (z. B. Details zum iOS-Signing-Flow, Hooking-Strategien, Android-Loader-Konzept)
gehört nach `docs/` in eigene Dateien, nicht hier rein — CLAUDE.md unter ~5k Tokens halten.