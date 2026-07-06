# tModLite

Mobile-first modding runtime for Terraria (iOS/Android). Not a tModLoader port.
Own runtime with a clearly separated shared core and platform adapters.

## Architecture

```
src/
  core/         Shared Core (C++17, platform-independent)
  platform/
    ios/        iOS adapter: dylib entry, injection bootstrap, hooking backend
    android/    Android adapter: .so injection, process attach, hooking backend
  sim/          Simulation harness for testing without the real game
docs/           Detail notes (injection concept, hooking, signing workflow etc.)
```

### Core Components (src/core/)
- `Runtime` — start(), tick(), shutdown()
- `EventBus` — register(event), emit(event)
- `Mod` — OnLoad(), OnUpdate(), OnUnload()
- `ModLoader` — scans mods folder, loads modules, registers hooks
- `GameContext` — abstraction for Player/World/Entities

### Hard Rule
**Core must NEVER know how it gets injected into the game.**
- No iOS/Android-specific code in `src/core/`
- No injection details, no offsets, no memory hacking in the core
- Core communicates only through the `GameContext` abstraction

## Tech Stack
- C++17, CMake build
- iOS cross-compile: `ios.toolchain.cmake`, final signing/deployment via Xcode tooling
- Android cross-compile: NDK toolchain via CMake
- Sideload signing (ESign/Feather/AltStore), no jailbreak needed

## Conventions
- Naming: `PascalCase` for classes, `camelCase` for methods
- Header/source separated (`.hpp` / `.cpp`)
- Every new core class needs a test in the simulation harness before the platform layer is touched

## Dev Workflow (keep the order)
1. Implement the core feature
2. Test it in the simulation (`src/sim/`) — 60 FPS update loop, fake player/world state
3. Only then: touch the platform layer (iOS/Android)

## Current Sprint Focus
<!-- Update here with what's currently being worked on -->
- [ ] Runtime + EventBus scaffolding
- [ ] Simulation test harness
- [ ] First test mod in the simulator

## Known Issues / Open TODOs
<!-- Maintain this ongoing instead of writing it into the chat history -->

## Notes
Larger documentation (e.g. details on the iOS signing flow, hooking strategies, Android loader concept)
belongs in its own files under `docs/`, not in here — keep CLAUDE.md under ~5k tokens.
