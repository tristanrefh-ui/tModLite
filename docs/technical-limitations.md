# Technical Limitations

An honest inventory of what technically does not (or does not yet) work on
iOS **without a jailbreak**, and why. Audience: anyone considering whether
TModLite is the right foundation for their modding idea, before investing
time.

## No behavior-hooking of existing Terraria methods

The biggest limitation. TModLite can **call** existing IL2CPP methods (see
`il2cpp-bridge.md` — `menuMode`, `gameMenu`, `Player.statLife`), but not
**change their behavior**. Real gameplay mods (QuickHeal actually
intervening on damage, InfiniteAmmo actually preventing ammo consumption)
need inline hooking of existing methods — we tested that on a real,
non-jailbroken device, and both tested approaches failed.

### Why: codesigning / W^X

iOS enforces, for apps without a jailbreak, that memory pages can't be both
writable and executable at the same time (W^X, "Write XOR Execute") and
that executable code must be signed. Terraria's compiled IL2CPP code (in
`UnityFramework`) sits on codesigned pages that can't be rewritten at
runtime — regardless of which library is used to try.

### Tested approaches (reference, code in `experimental/HookTest.mm`)

| # | Approach | Idea | Result on a real device |
|---|--------|------|------------------------------|
| 1 | **Dobby inline hook** | ARM64 trampoline hook via [Dobby](https://github.com/jmpews/Dobby), patches the native code address of `NPC.UpdateNPC(int)` directly | Even the **self-test** (hooking a trivial function in our own, self-signed dylib — not in Terraria) crashed. That points to a fundamental platform limit, not just a Terraria-specific problem with foreign codesigned pages. |
| 2 | **MethodInfo pointer swap** | No code patch: redirect `MethodInfo::method` (offset 0 in the struct, plain data storage, not a code page) directly to the address of our own function — bypasses Dobby and thus potentially W^X too, since no executable memory is written | Also tested on the device, also without success — no working redirection of the real game call path was observed. |
| 3 | **Vtable slot swap** *(not implemented)* | If `NPC.UpdateNPC` is a virtual method (determined at runtime via `il2cpp_method_get_flags`/`METHOD_ATTRIBUTE_VIRTUAL`, see `experimental/HookTest.mm`), the matching slot in `Il2CppClass::vtable` (`reference/il2cpp.h` line 275) could be overwritten instead of `MethodInfo::method` | Not tested — a pure idea, no code exists for it. Since approach 2 (structurally very similar: a data-storage write, no code patch) already failed, expectations aren't high, but it's unrefuted. |

**Conclusion:** with the means tested so far, behavior-hooking existing
Terraria methods is not achievable on a non-jailbroken device. This isn't
final proof (the vtable approach is open, other hooking libraries are
conceivable), but enough signal to not plan it as a reliable foundation for
features. Affected: the entire "puppeteer" concept from
`calamity-architecture.md` (custom bosses, weapons, companions via hijacked
vanilla types) — that document should currently be understood as a concept
on hold, not an active plan.

## What this doesn't affect: plain API calls

Important distinction — the following keeps working without restriction,
because it **doesn't change any existing method**, only **calls** it:

- Reading/writing static/instance properties (`menuMode`, `gameMenu`,
  `Player.statLife`/`statLifeMax`)
- Creating new instances of existing classes (`il2cpp_object_new` +
  `.ctor`)
- Calling existing methods normally (`il2cpp_runtime_invoke`)
- `Recipe`/`AddRecipe()` — creating new recipes, since that matches
  Terraria's own intended extension pattern, no hook needed

God Mode (`Il2CppBridge.mm`, a poll timer on `Player.statLife`) is an
example of how far you can get **without** hooking: no hook on
`Player.Update()`, just a simple native timer that resets the value
periodically.

## Non-virtual methods

Even if a hooking approach ever works: non-virtual methods can't be
redirected via vtable manipulation in principle (there's no vtable slot) —
the only options left would be a real code patch on the call site itself
(approach 1) or on `MethodInfo::method` (approach 2), both already tested
above without success. Whether `NPC.UpdateNPC(int)` is virtual is
determined at runtime by `experimental/HookTest.mm`
(`TML_IsUpdateNpcVirtual`), but wasn't a decisive factor by the time of
this document, since the data-storage approach (2) already didn't work.

## No new NPCID/ItemID/BuffID

`NPCID`/`ItemID`/`BuffID` are fixed `const int` constants, no dynamic
registration like `ModContent`/`ModItem`/`ModNPC` in tModLoader Desktop.
`Main.maxNPCs`, texture/animation/stats lookup arrays are dimensioned
exactly to the vanilla ID range — any ID above the last vanilla ID causes
an `IndexOutOfRange`/segfault on the first array lookup. New IDs are
therefore technically not possible without enlarging these arrays
themselves (which in turn would need code patches to Terraria's own
initialization — see above).

## No data-driven content like tModLoader Desktop

Terraria Mobile is IL2CPP-compiled, **no JIT at runtime** — no new classes
can be created at runtime (no `ModContent.Load<T>()` equivalent, no new
`Item`/`NPC` subclasses). Apple's JIT ban for third-party apps generally
prevents creating executable memory at runtime — a MelonLoader/
Il2CppInterop-style approach (registering new managed types at runtime)
doesn't exist for this on iOS without a jailbreak. Content extension is
therefore structurally something different than in tModLoader Desktop: not
"define new types", but repurpose existing vanilla types (details and
limits of that: `calamity-architecture.md`, with the caveat above that its
complete hook-based behavior rewriting wasn't achievable).

## Summary

| Works | Doesn't work (without jailbreak) |
|------|------------------------------|
| Reading & calling existing properties/methods | Changing the behavior of existing methods (hooking) |
| New instances of existing classes | New classes/types at runtime |
| New recipes (`AddRecipe`) | New NPCID/ItemID/BuffID |
| Poll-based effects (God Mode) | Event/delegate hooks into internal game flows |
| A fully self-contained UI overlay | Rebuilding Terraria's own UI system |
