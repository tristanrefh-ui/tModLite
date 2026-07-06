# experimental/

Concluded research/test code that's no longer part of the active build, but
kept as a reference — in case the topic gets picked up again later (e.g.
with a different hooking approach or under different constraints). Nothing
here is wired into `src/platform/ios/CMakeLists.txt`.

## HookTest.h / HookTest.mm

Two approaches to redirecting existing Terraria methods
(`NPC.UpdateNPC(int)`) at runtime, both tested on a real, non-jailbroken
device:

1. **Dobby inline hook** (`TML_EnableHookTest`) — a code patch on the native
   function address via [Dobby](https://github.com/jmpews/Dobby). Even the
   self-test (hooking a trivial function in our **own** dylib, not in
   Terraria) crashed on the device.
2. **MethodInfo pointer swap** (`TML_EnableMethodPointerSwapTest`) — no code
   patch, just directly overwriting `MethodInfo::method` (offset 0, plain
   data storage). Also tested on the device, also without success.

Result and interpretation: see
[`docs/technical-limitations.md`](../docs/technical-limitations.md). Short
version: both approaches fail, which points to a fundamental platform
limit (iOS codesigning/W^X), not a fixable bug in the test code.

### Re-enabling, if this gets picked up again later

1. Move `HookTest.h`/`HookTest.mm` back to `src/platform/ios/`.
2. In `src/platform/ios/CMakeLists.txt`: add `HookTest.mm` back to the
   `add_library(tml_ios_bootstrap SHARED ...)` source list, plus the Dobby
   imported-target block (see this file's git history, the commit before
   this cleanup) and add `dobby` back to
   `target_link_libraries(tml_ios_bootstrap PRIVATE ...)`.
3. Rewire the call sites (e.g. a diagnostic entry in the UI) — see the git
   history of `src/platform/ios/ui/TMLInGamePanel.mm` for the earlier
   example.

The vendored Dobby lib itself stays under `third_party/dobby/` regardless
(see its own `README.md`).

## PlayerLoopTest.h / PlayerLoopTest.mm

**Not** moved here — still active in `src/platform/ios/`. This isn't a
concluded dead end, but ongoing groundwork for the next roadmap step
(PlayerLoop integration instead of NSTimer polling, see `docs/roadmap.md`).
Important difference from the two tests above: this isn't about
patching/redirecting existing methods, but about `PlayerLoop.SetPlayerLoop`
-style extension points that Unity itself provides — if that works, it
bypasses the codesigning limit entirely, because no foreign code gets
patched.
