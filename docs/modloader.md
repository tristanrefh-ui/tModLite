# ModLoader — folder scan

## How the scan works

`ModLoader::scanDirectory(path)` (`src/core/ModLoader.cpp`):

1. Iterates all direct subfolders of `path`.
2. Looks for `manifest.json` in each subfolder.
3. Parses it via `nlohmann::json`. If the file is missing or isn't valid
   JSON, the folder is skipped (no crash).
4. Creates a pure metadata `Entry` per valid manifest (`mod == nullptr` — no
   code, just name/version/enabled flag).
5. Returns the number of newly found mods.

Scanned entries end up in the same list as real mods registered via
`registerMod()` (see `architecture.md`) — `modCount()`/`modName()`/
`modVersion()`/`isModEnabled()` treat both kinds the same.

## manifest.json format

```json
{
  "name": "QuickHeal",
  "version": "1.0",
  "enabled": true
}
```

- `name` (string) — **required**. If it's missing or not a string, the
  folder is skipped.
- `version` (string) — optional, default `"0.0"`.
- `enabled` (bool) — optional, default `true`.

## Adding a new mod

1. Create a new folder under `mods/<ModName>/`.
2. Drop in a `manifest.json` with at least `name`.
3. Done — it's automatically found on the next `scanDirectory("mods/")`
   call (desktop sim: `src/sim/main.cpp`, iOS: `Bootstrap.mm`).

Currently in the repo: `mods/QuickHeal/` (enabled) and `mods/InfiniteAmmo/`
(disabled) — both fake mods with no real game logic, only for testing the
scan/display/toggle pipeline.

## Where iOS scans

On a real device without a jailbreak, the app's own bundle folder isn't
writable. `Bootstrap.mm` therefore scans `<App-Documents>/mods` (via
`NSSearchPathForDirectoriesInDomains`) — the only place you can write to
without a jailbreak (e.g. via the Files app or file sharing through
Finder/iTunes). On a fresh device with no manually copied mod folders, the
result is correctly empty ("no mods loaded") — not a fake value, a genuinely
empty scan.

## Current state / limitation

This is purely **metadata and toggle management**. `toggleMod(name)` only
flips the `enabled` flag in the `ModLoader` — it runs **no** mod code,
because the scanned entries have no code at all (`mod == nullptr`).
QuickHeal and InfiniteAmmo therefore do (still) nothing when enabled.

Actually loading mod code from the folder is the next stage — see
`roadmap.md`.
