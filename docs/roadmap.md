# Roadmap

## Standing (verified, built on desktop + iOS)

- **Core:** `Runtime`, `EventBus`, `Mod`, `GameContext`, `ModLoader` with
  `registerMod` (real code) + `scanDirectory` (metadata from
  `manifest.json`) + `toggleMod`/`setModEnabled`.
- **Sim:** live ASCII visualization (`MovementMod`), mod-scan logging at
  startup.
- **iOS adapter:**
  - Bootstrap dylib with an `__attribute__((constructor))` entry, verified
    via Feather injection on a real device.
  - Touch-passthrough overlay window (`hitTest:` override), orientation
    lock.
  - Native UIKit panel styled after Terraria's real settings menu (own
    colors/assets, no copied Terraria material) with real ModLoader data
    (name + toggle per row).
  - IL2CPP bridge: `Terraria.Main.menuMode` controllable as a signal state
    (empty Terraria background while our own panel is open),
    `Terraria.Main.gameMenu` read to distinguish the main menu from a
    running world.
  - Two separate panels depending on context: `TMLOverlayPanel` (main menu,
    changes `menuMode`) and `TMLInGamePanel` (running world, doesn't change
    game state) — see `architecture.md`.

## Concluded, no further step planned

- **Behavior-hooking existing methods.** Two approaches tested for real on
  the device (Dobby inline hook, MethodInfo pointer swap), both without
  success — see `technical-limitations.md`. Reference code for this lives in
  `experimental/`, but is no longer part of the active build. This also
  means the entire hook-based "puppeteer" concept from
  `calamity-architecture.md` isn't achievable for now.

## Reasonable next steps

1. **PlayerLoop integration instead of NSTimer polling.** God Mode (and any
   future poll-based feature) currently runs on a plain native timer
   (500ms), independent of Unity's own frame cadence — it works, but isn't
   frame-synced. `experimental/PlayerLoopTest.mm` (active, not a concluded
   experiment) investigates whether `UnityEngine.LowLevel.PlayerLoop` icalls
   (`GetCurrentPlayerLoop`/`SetPlayerLoop`) can be addressed directly via
   `il2cpp_resolve_icall` despite managed-code stripping. Important
   difference from the concluded hooking chapter above: this is about an
   extension point Unity itself provides (hooking in your own subsystem),
   not about patching/redirecting existing methods — so it shouldn't fail
   at the same codesigning wall.
2. **An `IContentSource`-like mechanism for custom textures.** TModLite
   currently has no way to bring its own sprites/textures into the running
   game (every "custom" feature from `calamity-architecture.md` that needs
   its own look depends on this). Check Terraria's own content loading
   (`IContentSource`) as an extension point — whether additional textures
   can be registered through it without hooking existing load methods.
3. **Use more delegate-/event-based hook points.** Instead of poll timers
   (God Mode) or failed hooking: check which real `Action`/`event` fields
   Terraria itself exposes (analogous to the approach for `menuMode`/
   `gameMenu`, but for actual game events instead of plain state
   properties) and whether they can be wired up without
   `il2cpp_method_get_flags`/code patches.
4. **Real dynamic mod-code loading.** Scanned mods are currently pure
   metadata (see `modloader.md`). Next step: a defined format for how a mod
   folder actually brings code along and how the `ModLoader` loads it —
   e.g. a bundled `.dylib`/`.so` with a fixed C ABI (matching the `Mod`
   base class), or an embedded scripting language (e.g. Lua) for
   platform-independent mods with no compile step per target device. The
   latter would be more robust for distribution (no arm64 binaries needed
   per mod), the former more direct/performant.
5. **Android adapter.** Only iOS implemented so far. Analogous: `.so`
   injection, process attach, its own hooking backend — the groundwork per
   `CLAUDE.md` is still open. The same codesigning caveats as in
   `technical-limitations.md` don't directly carry over to Android
   (different platform policy), would need to be verified separately.
6. **Persisting the enabled/disabled state.** Currently in-memory, resets
   to the manifest defaults on every process start.
7. **If a real Terraria screen is ever needed after all:** the current
   approach (clear the screen + our own native panel) deliberately avoids a
   deeper understanding of Terraria's rendering pipeline (see
   `il2cpp-bridge.md`, points 2-5 of the path). If a real Terraria screen
   needs to be hijacked later after all, that's where it would continue.
