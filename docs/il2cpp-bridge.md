# IL2CPP Bridge — research, dead ends, final approach

Terraria Mobile is a Unity/IL2CPP build. This file records what actually
worked, what didn't, and why — so the same thinking doesn't have to be
repeated next time.

## Tools

- **IL2CppDumper** run against `UnityFramework` (the IL2CPP runtime +
  compiled game embedded in the IPA). Result: `dump.cs` (decompiled
  class/method signatures as pseudo-C#), `script.json` (raw data),
  `il2cpp.h` (struct layouts of the **metadata file** — careful, see below).

### Important mix-up risk

There are **three different, similarly named headers** in the IL2CPP world:

1. **Metadata format header** (what IL2CppDumper outputs as `il2cpp.h`) —
   describes how `global-metadata.dat` is laid out on disk
   (`Il2CppTypeDefinition`, `Il2CppGlobalMetadataHeader`, ...). Not the
   runtime API.
2. **Runtime struct internals** (`Il2CppClass`, `Il2CppObject` with real
   fields) — for direct offset access, we didn't need these.
3. **`il2cpp-api-functions.h`** — the actually exported C functions
   (`il2cpp_domain_get`, `il2cpp_class_from_name`, `il2cpp_runtime_invoke`, ...).
   **This is the only file our `Il2CppBridge.mm` was verified against**
   (checked into the repo as `reference/il2cpp-api-functions.h`). Tell: the
   declarations go through a `DO_API(returnType, name, (params))` macro.

On the first attempt, IL2CppDumper's `il2cpp.h` was mistakenly assumed to be
the API file — but it contained none of the functions we needed. Only the
real `il2cpp-api-functions.h` (sourced separately) confirmed the signatures.

## The path (chronological)

1. **Bridge foundation:** `dlopen("UnityFramework", RTLD_NOLOAD)` (fallback:
   search `_dyld_image_count()`/`_dyld_get_image_name()` for the real path)
   + `dlsym` for the whole API we needed. All types rebuilt as opaque
   `typedef struct X X;` handles, no runtime headers included (those belong
   to the game, not us).

2. **First real test:** read `Terraria.UI.UserInterface.ActiveInstance` (a
   static field), call `SetState(UIState)` on it with a freshly created
   `UIAchievementsMenu` instance (`il2cpp_object_new` + `.ctor` invoke). The
   bridge call succeeded according to the log — **but nothing visually
   changed in the game.**

3. **Hypothesis falsified:** `ActiveInstance` apparently isn't the instance
   actually being drawn. Found in `dump.cs`: `Terraria.Main` has its own
   static fields `MenuUI`/`InGameUI`, presumably the real draw targets.

4. **Switched to `Main.MenuUI`** as the target for `SetState`. Succeeded
   again according to the log, still no visible change.

5. **Added `RefreshState()`** (found in `dump.cs`: an `_isStateDirty` field +
   `internal void RefreshState()` — hypothesis: a dirty-flag mechanism
   decides whether `SetState` actually triggers a redraw). Important side
   finding: **`internal` is not an obstacle at runtime** — IL2CPP no longer
   has C# access modifiers, `class_get_method_from_name` finds `internal`
   methods just like `public` ones.

6. **`Main.menuMode` as a signal approach.** First mistakenly treated as a
   static field, then mistakenly as an instance field (reading
   `Main.instance`, then `il2cpp_field_get_value`/`set_value` with the
   instance). Eventually the correct insight: `menuMode` is a **C# auto
   property** (`public static int menuMode { get; set; }`), the compiler
   generates `get_menuMode()`/`set_menuMode(int)` as perfectly ordinary
   static methods for it — no field access needed, no `Main.instance` needed.

7. **Final approach:** stop hijacking real Terraria screens entirely. Use
   `menuMode` purely as a **signal state** (10 = an internal, empty Terraria
   screen in the background, no Terraria UI visible; 0 = back to the title
   screen), and lay a completely own, native UIKit panel **on top** of it.
   The `SetState`/`RefreshState`/`UIAchievementsMenu` code was removed
   (no longer needed).

## Technical pitfalls (for next time)

- **Boxing on value-type returns:** `il2cpp_runtime_invoke` returns a
  **boxed** `Il2CppObject*` for an `int` return value (like
  `get_menuMode()`), not the raw value. `il2cpp_object_unbox(obj)` gives a
  `void*` to the actual data — only then cast to `*(int*)`.
- **Instance vs. static field functions:** `il2cpp_field_get_value`/
  `il2cpp_field_set_value` take `Il2CppObject* obj` as the **first**
  parameter (`(obj, field, value)`), while `il2cpp_field_static_get_value`
  only takes `(field, value)` — easy to mix up.
- **`il2cpp_domain_get_assemblies`** returns `const Il2CppAssembly**` (an
  array of pointers, not a single pointer) — the one signature where a wrong
  guess would have been plausible; verified against the real reference file
  and it checked out.
- **Constructors** are always internally called `.ctor` (CLR convention).
- **`runtime_invoke` parameter array:** reference-type arguments are the
  object pointer directly; value-type arguments are a pointer **to** the
  value (`int v = 10; void* args[] = {&v};`).
- **Logging:** `std::printf`/`fflush` often isn't enough on a real device
  without an attached debugger — lines didn't show up in Console.app.
  `NSLog` is reliably visible. See also `ios-injection.md`.

## Current final API usage

- `Terraria.Main.get_menuMode()` / `set_menuMode(int)`, resolved and cached
  once per process (`Il2CppBridge.mm`, `TML_SetMenuMode(int)`).
- `Terraria.Main.get_gameMenu()` (getter only, analogous to the menuMode
  property, see below) — `TML_IsGameMenuActive()`.
- `Terraria.Player`: the `myPlayer` property, the `Main.player` array field,
  the `statLife`/`statLifeMax` instance fields — the God Mode poll
  (`TML_SetGodMode`).

## gameMenu: telling the main menu apart from a running world

Same pattern as `menuMode`: `gameMenu` is also a C# auto property
(`public static bool gameMenu { get; set; }`), we only use the generated
getter `get_gameMenu()`. Purpose: `TMLOverlayManager` needs to know, when
opening the overlay, whether the main menu or a running world is currently
active, to show the right panel (`TMLOverlayPanel` vs. `TMLInGamePanel` —
see `architecture.md`). No setter needed, since we only want to detect the
state, not switch it ourselves. Fallback when the bridge isn't ready: `true`
(when in doubt, treat it like the main menu — the existing settings-panel
path is more conservative than the newer, more experimental in-game panel).

## Limitation: calls only, no hooking

Everything above is a **call** to an existing method — works reliably. A
**hook** (changing/redirecting existing method behavior) is a completely
different problem and was investigated separately, with a negative result
on a real device — see `technical-limitations.md` and
`experimental/HookTest.mm`. This bridge file deliberately stays free of
hooking code.
