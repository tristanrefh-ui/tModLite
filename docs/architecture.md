# Architecture

## Basic principle

```
src/core/         Shared Core (C++17, platform-independent)
src/platform/ios/ iOS adapter: dylib entry, injection bootstrap, IL2CPP bridge, native UI
src/platform/android/  Android adapter (not implemented yet)
src/sim/          Simulation harness for testing without the real game
mods/             Mod folder (metadata, see modloader.md)
experimental/     Concluded research/test code, not part of the active build
```

**Hard rule:** `src/core/` never knows how it gets injected. No iOS/Android
code, no injection details, no offsets in the core. Communication only
through `GameContext`.

## Core components (`src/core/`)

- **`Runtime`** — `start()` / `tick()` / `shutdown()`. Owns `GameContext` and
  `ModLoader`. The single entry point for platform adapters.
- **`EventBus`** — simple pub/sub (`registerHandler`/`emit`), `Event` struct
  with a name. Not currently wired to Runtime/ModLoader, usable standalone.
- **`Mod`** — abstract base class: `OnLoad`/`OnUpdate`/`OnUnload` (required),
  `name()`/`version()` (virtual with default values, overridable).
- **`GameContext`** — placeholder state: `Player`, `World` (with grid
  dimensions `gridWidth`/`gridHeight` for the sim visualization), `Entity` list.
- **`ModLoader`** — holds a list of `Entry`s (name, version, enabled flag,
  optionally a real `Mod` object). Two ways to get entries:
  - `registerMod(unique_ptr<Mod>)` — a real, code-carrying mod (e.g.
    `MovementMod` in the sim).
  - `scanDirectory(path)` — reads `manifest.json` from subfolders, creates
    pure metadata entries (`mod == nullptr`, see `modloader.md`).

  `updateAll()` only ticks entries with `enabled == true` AND a real `Mod`
  object. `toggleMod(name)` / `setModEnabled(index, enabled)` control the
  status regardless of whether a real mod object backs the entry.

## Platform layer principle

Adapters (`src/platform/ios/`) may import and call `Runtime`/`GameContext`/
`ModLoader`, but the core never imports anything from `platform/`.

Within an adapter there's a further separation: the C++/Objective-C++
bridge (`Bootstrap.mm`, `Il2CppBridge.mm`) is the only place that knows both
core types (`tml::Runtime`, `tml::ModLoader`) and native UI types. The UI
components themselves (`src/platform/ios/ui/`) are pure Objective-C, they
know no C++ core types — they're handed ready-made, simple Objective-C
objects (`TMLOverlayModRow`) and blocks. That keeps the UI reusable and the
coupling points minimal.

`TMLOverlayManager` holds two panels and shows exactly one of them depending
on the game state (`TML_IsGameMenuActive()`): `TMLOverlayPanel` in the main
menu (changes `menuMode`, shows the mod list with toggles) and
`TMLInGamePanel` while a world is running (doesn't change game state,
currently a placeholder for future in-game features — see `roadmap.md`).

`experimental/` deliberately lives outside of `src/` — code there is
concluded, failed, or no longer actively pursued research (see
`technical-limitations.md`), not part of the adapter and not wired into the
build.

Details on the individual adapter mechanisms: `ios-injection.md`,
`il2cpp-bridge.md`. On the mod scan: `modloader.md`. On limitations:
`technical-limitations.md`. On the outlook: `roadmap.md`.
