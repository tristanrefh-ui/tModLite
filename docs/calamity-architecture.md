# TModLite — Calamity-level content architecture

> **Update:** The entire "puppeteer" pattern in this document assumes that
> existing Terraria methods can be redirected via inline hooking (point 1,
> "Dobby integration"). That has since been tested on a real, non-jailbroken
> device — both tested approaches (Dobby inline hook, MethodInfo pointer
> swap) failed, see [`technical-limitations.md`](technical-limitations.md).
> This document is therefore **on hold, not an active plan** — kept as a
> reference in case a different hooking approach or different constraints
> (e.g. jailbreak support as a separate, clearly labeled branch) reopen the
> topic later.
>
> Status: concept, not implemented yet. Result of a research session
> (IL2CPP dump analysis + architecture discussion). Scope: **singleplayer
> only**, no multiplayer sync planned.

## Core problem

Terraria Mobile is IL2CPP-compiled, no JIT at runtime. That means:
- No new classes can be created at runtime
- `NPCID`/`ItemID`/`BuffID` are fixed `const int` constants, no dynamic
  registration (no `ModContent`/`ModItem`/`ModNPC` system like tModLoader
  Desktop)
- `Main.maxNPCs = 200`, `Item`/`NPC`-related lookup arrays (textures,
  animations, stats) are dimensioned exactly to the vanilla ID range

**Hard rule that applies to the entire architecture:**
> Every `type` ID (NPC or item) must always remain a valid, existing
> vanilla ID. An ID above the last vanilla ID is guaranteed to cause an
> `IndexOutOfRange`/segfault on the first array lookup (texture, animation,
> stats) and crashes the app immediately.

Discarded idea: a MelonLoader/Il2CppInterop-style approach (registering new
managed types at runtime) — doesn't exist for iOS without a jailbreak,
since Apple's JIT ban for third-party apps prevents creating executable
memory at runtime. Rebuilding this infrastructure for iOS would be a
multi-year project.

## The core principle: the "puppeteer" pattern

Instead of creating new IDs (impossible), an **existing vanilla type is
hijacked**: let it spawn normally, immediately mark it with a custom flag,
then completely override its behavior/appearance via **native inline
hooking (Dobby)**. For Terraria it internally remains the original vanilla
type forever (memory management, slot allocation work normally) — only the
hook layer decides what the player actually sees/experiences.

Technical building block still missing: **Dobby** (an ARM64 inline hooking
library) needs to be integrated into the dylib to redirect function
pointers like `NPC.Update()`/`Main.DrawNPC()` at runtime. So far TModLite
only uses plain API calls (`il2cpp_runtime_invoke` etc.), no hooking.

## Content categories in detail

### 1. Custom bosses/enemies ✅ feasible
- Spawn an existing, harmless NPC (e.g. slime, `NPCID=1`)
- Immediately in the same tick: set a custom flag (an unused `ai[]` field,
  e.g. `ai[3] = 9999`)
- Hook on `NPC.Update()`: when the flag is set → block the original call,
  run our own C++ logic for movement/attacks/projectiles
- Hook on `Main.DrawNPC()`: draw our own sprite instead of the vanilla
  texture
- Slot usage identical to any normal NPC spawn (no permanent loss of a
  slot)

### 2. Custom companions (instead of town NPCs) ✅ feasible, with a trade-off
**Not** solved via town NPCs — the `NPC.AnyNPCs(type)` check only allows 1
instance per type, and housing-assignment logic breaks easily under
manipulation (Gemini: "a nightmare").

**Solution:** hijack a harmless **critter** (e.g. bunny, `NPCID=46`) —
never triggers `AnyNPCs()`, needs no housing.
- Hook on `NPC.Update()`: override velocity so the critter follows the
  player (pet behavior)
- Hook on input detection (touch on the NPC): block the vanilla dialog,
  open our own UIKit panel for shop/dialog instead
- **Trade-off:** no moving into a vanilla house — the companion despawns
  when far from the player, has to be resummoned. Acceptable for
  merchants/lore characters.

### 3. Custom weapons/equipment: "category hijacking" ✅ feasible
Don't hijack the item with the least logic (that means rebuilding
melee physics/hitboxes yourself), but the **mechanically matching,
simplest vanilla item of the same category**:
- Melee weapons → hijack the wooden sword (`ItemID=24`), the engine takes
  care of swing/hitbox, the hook only overrides damage/sprite/spawns custom
  projectiles
- Ranged weapons → hijack the flintlock pistol, the engine takes care of
  cursor aiming/cooldown
- Accessories (wings etc.) → hijack a weak vanilla accessory, the engine
  takes care of slot/gravity, the hook overrides flight time/speed

**Marking custom items:** no `ai[]` array available like for NPCs →
repurpose `Item.prefix` (vanilla prefixes go up to ~83, custom marker e.g.
`prefix=200`). **Trade-off:** custom items can no longer carry real vanilla
prefixes.

Pure decoration/material items (no combat relevance) remain the simplest
case for crafting ingredients/quest items/loot with no logic of their own.

### 4. Custom biomes (structural, not just visual) ✅ feasible
**Not** by hooking into Terraria's `GenPass` pipeline (a fragile
state-machine monolith, would need native mocks of C# delegates). Instead:
- **Post-processing after normal world generation**: get a pointer to the
  `Main.tile` array (fixed-allocated depending on world size, but the data
  is mutable), generate custom cave shapes/zones in C++ with
  noise/cellular automata, replace existing tiles with hijacked custom tile
  IDs
- **Biome detection**: hook Terraria's own counting logic (tile sampling
  around the player), count custom tile IDs in parallel →
  `isPlayerInCustomBiome` flag
- **Zone mechanics** (e.g. acid damage): hook `Player.Update()` (NOT
  NSTimer polling — that runs asynchronously to the game loop and risks
  frame desyncs), apply damage/debuffs when the flag is active
- **Zone spawn pool**: hook the central spawn decision, spawn our own
  (hijacked) NPCs instead of the vanilla pool when the flag is active

### 5. Custom chests with custom loot ✅ "surprisingly simple" (Gemini)
Search the `Main.chest` array (~8000 slots) after world-generation
post-processing, identify chests at custom biome coordinates, fill
`chest[i].item[]` (40 slots) with hijacked custom items. No known
Terraria-internal validations that block this.

### 6. New crafting recipes ✅ already verified in the dump
The `Recipe` class has a real construction pattern: `new Recipe()` →
`SetIngredients(int[])` → `SetCraftingStation(int)` → internally
`AddRecipe()`. Re-Logic itself uses exactly this pattern (see the many
`AddXYZFurniture()` methods in the dump).

### 7. Magic-Storage-like feature ⚠️ feasible, two parts of different difficulty
- **UI aggregation** (easy): our own C++ data structure as the "source of
  truth" that aggregates the contents of several hijacked chest instances,
  hooked up to our own UIKit panel (do NOT rebuild Terraria's native UI
  system — "an endless reverse-engineering pit")
- **Crafting from storage** (medium): hook the item-consumption call during
  crafting — if the item isn't in the player's inventory, deduct it from
  our own storage structure instead (find the associated chest instance,
  reduce the `stack` value), fake success on the original function
- **Known risk**: raw pointers to IL2CPP objects (chest instances) can be
  freed by the GC (e.g. when a chest is destroyed) → segfault risk. Hooks
  on chest destruction are needed to invalidate references cleanly.

## ❌ What isn't feasible

- **Real new item/NPC/boss IDs** in the game's own system (fixed
  compile-time arrays, see above)
- **Full-fledged town NPCs** with real housing integration (only the
  critter workaround from point 2 is practical)
- **Multiplayer sync** of any of this — deliberately out of scope, would
  mean network packet interception + server-authority conflicts, a big
  topic on its own

## Persistence: sidecar save system (mandatory, not optional)

Terraria doesn't automatically save volatile state (`ai[]` values, custom
prefixes) — the `.wld` format is dimensioned exactly to vanilla data
structures, extending it would corrupt the world.

**Solution:**
- Hook `WorldFile.saveWorld()`: before/after the normal save, write our own
  custom objects (NPCs/items/chests with custom flags) with coordinates +
  custom data to a separate file (e.g. `WorldName.wld.moddata`, JSON or a
  custom binary format)
- Hook `WorldFile.loadWorld()`: after the vanilla load, read the
  `.moddata` file, find the corresponding dummy objects at the saved
  coordinates, reapply the custom flags

**Without this system, all custom features are completely lost after every
app restart.** Should come before any larger content implementation.

## Recommended implementation order

1. **Dobby integration** — integrate the ARM64 inline-hooking library into
   the dylib, first test: a single hook on `NPC.Update()` for a slime, only
   logging (no behavior change) — proves that hooking is stable on this
   setup
2. **Sidecar save system** — foundation for everything else, without it
   every bit of progress is volatile
3. **Custom biome (post-processing)** — lowest risk (one-time at world
   generation, not per frame), biggest visible effect
4. **Custom bosses** — uses the proven puppeteer pattern
5. **Custom recipes & custom chests** — technically already mostly
   verified, no hooking needed
6. **Custom weapons (category hijacking)** — more individual cases, but the
   same pattern applies repeatedly
7. **Custom companions** — the critter workaround
8. **Magic Storage UI** — builds on chest reading (already verified) + our
   own panel (already exists)

Estimated effort for the whole package: several weeks to a few months, not
days — well beyond the scope of everything TModLite has built so far (God
Mode, menuMode panel, ModLoader scan).

## Reference: already verified technical building blocks (as of today)

- Resolving IL2CPP classes/methods/fields at runtime (`dlopen`/`dlsym`
  against the `il2cpp_*` API)
- Reading/writing static properties (`Main.menuMode`)
- Reading/writing instance fields in array elements
  (`Main.player[Main.myPlayer].statLife`)
- Creating new instances of existing classes (`il2cpp_object_new` +
  `.ctor`)
- Value-type boxing/unboxing (`il2cpp_object_unbox`)
- **Verified as not working:** native inline hooking (Dobby) and
  MethodInfo pointer swap — both failed on a real device, see
  `technical-limitations.md`
- Not yet verified (largely moot now that hooking as a foundation is off
  the table): tile-array access, sidecar persistence
