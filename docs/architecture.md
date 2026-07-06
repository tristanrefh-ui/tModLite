# Architecture

## Grundprinzip

```
src/core/         Shared Core (C++17, plattformunabhaengig)
src/platform/ios/ iOS Adapter: dylib-Entry, Injection-Bootstrap, IL2CPP-Bridge, native UI
src/platform/android/  Android Adapter (noch nicht implementiert)
src/sim/          Simulation Harness zum Testen ohne echtes Spiel
mods/             Mod-Ordner (Metadaten, siehe modloader.md)
experimental/     Abgeschlossene Forschungs-/Testcode, nicht im aktiven Build
```

**Harte Regel:** `src/core/` weiss nie, wie er injiziert wird. Kein iOS/Android-Code,
keine Injection-Details, keine Offsets im Core. Kommunikation nur ueber `GameContext`.

## Core-Komponenten (`src/core/`)

- **`Runtime`** — `start()` / `tick()` / `shutdown()`. Besitzt `GameContext` und
  `ModLoader`. Einziger Einstiegspunkt fuer Platform-Adapter.
- **`EventBus`** — einfaches Pub/Sub (`registerHandler`/`emit`), `Event`-Struct
  mit Namen. Aktuell nicht mit Runtime/ModLoader verdrahtet, eigenstaendig nutzbar.
- **`Mod`** — abstrakte Basisklasse: `OnLoad`/`OnUpdate`/`OnUnload` (Pflicht),
  `name()`/`version()` (virtuell mit Default-Werten, ueberschreibbar).
- **`GameContext`** — Platzhalter-State: `Player`, `World` (mit Grid-Massen
  `gridWidth`/`gridHeight` fuer die Sim-Visualisierung), `Entity`-Liste.
- **`ModLoader`** — haelt eine Liste von `Entry`s (Name, Version, enabled-Flag,
  optional ein echtes `Mod`-Objekt). Zwei Wege, Eintraege zu bekommen:
  - `registerMod(unique_ptr<Mod>)` — echter, code-tragender Mod (z.B. `MovementMod`
    in der Sim).
  - `scanDirectory(path)` — liest `manifest.json` aus Unterordnern, legt reine
    Metadaten-Eintraege an (`mod == nullptr`, siehe `modloader.md`).

  `updateAll()` tickt nur Eintraege mit `enabled == true` UND einem echten
  `Mod`-Objekt. `toggleMod(name)` / `setModEnabled(index, enabled)` steuern den
  Status unabhaengig davon, ob ein echtes Mod-Objekt dahintersteht.

## Platform-Layer-Prinzip

Adapter (`src/platform/ios/`) duerfen `Runtime`/`GameContext`/`ModLoader`
importieren und aufrufen, aber Core importiert nie etwas aus `platform/`.

Innerhalb eines Adapters gilt eine weitere Trennung: die C++/Objective-C++-
Bruecke (`Bootstrap.mm`, `Il2CppBridge.mm`) ist der einzige Ort, der sowohl
Core-Typen (`tml::Runtime`, `tml::ModLoader`) als auch native UI-Typen kennt.
Die UI-Komponenten selbst (`src/platform/ios/ui/`) sind reines Objective-C,
kennen keine C++-Core-Typen — sie bekommen fertige, einfache Objective-C-
Objekte (`TMLOverlayModRow`) und Blocks uebergeben. Das haelt die UI
wiederverwendbar und die Kopplungsstellen minimal.

`TMLOverlayManager` haelt zwei Panels und zeigt je nach Spielzustand
(`TML_IsGameMenuActive()`) genau eins davon: `TMLOverlayPanel` im
Hauptmenue (aendert `menuMode`, zeigt die Mod-Liste mit Toggles) und
`TMLInGamePanel` waehrend einer laufenden Welt (aendert nichts am
Spielzustand, aktuell ein Platzhalter fuer zukuenftige In-Game-Features —
siehe `roadmap.md`).

`experimental/` liegt bewusst ausserhalb von `src/` — Code dort ist
abgeschlossene, gescheiterte oder nicht mehr aktiv verfolgte Forschung (siehe
`technical-limitations.md`), nicht Teil des Adapters und nicht im Build
verdrahtet.

Details zu den einzelnen Adapter-Mechanismen: `ios-injection.md`,
`il2cpp-bridge.md`. Zum Mod-Scan: `modloader.md`. Zu Grenzen: `technical-limitations.md`.
Zum Ausblick: `roadmap.md`.
