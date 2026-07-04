# Roadmap

## Steht (verifiziert, Desktop + iOS gebaut)

- **Core:** `Runtime`, `EventBus`, `Mod`, `GameContext`, `ModLoader` mit
  `registerMod` (echter Code) + `scanDirectory` (Metadaten aus
  `manifest.json`) + `toggleMod`/`setModEnabled`.
- **Sim:** Live-ASCII-Visualisierung (`MovementMod`), Mod-Scan-Logging beim
  Start.
- **iOS-Adapter:**
  - Bootstrap-dylib mit `__attribute__((constructor))`-Entry, verifiziert per
    Feather-Injection auf echtem Geraet.
  - Touch-Passthrough-Overlay-Fenster (`hitTest:`-Override), Orientation-Lock.
  - Natives, an Terrarias echtem Settings-Menu orientiertes UIKit-Panel
    (eigene Farben/Assets, kein kopiertes Terraria-Material) mit echten
    ModLoader-Daten (Name + Toggle pro Zeile).
  - IL2CPP-Bridge: `Terraria.Main.menuMode` als Signalzustand steuerbar
    (leerer Terraria-Hintergrund waehrend das eigene Panel offen ist).

## Sinnvolle naechste Schritte

1. **Echtes dynamisches Mod-Code-Laden.** Aktuell sind gescannte Mods reine
   Metadaten (siehe `modloader.md`). Naechster Schritt: ein definiertes
   Format, wie ein Mod-Ordner tatsaechlich Code mitbringt und der
   `ModLoader` ihn laedt — z.B. eine mitgelieferte `.dylib`/`.so` mit einer
   festen C-ABI-Schnittstelle (passend zur `Mod`-Basisklasse), oder eine
   eingebettete Scriptsprache (z.B. Lua) fuer plattformunabhaengige Mods ohne
   Compile-Schritt pro Zielgeraet. Letzteres waere robuster fuer Verteilung
   (keine arm64-Binaries pro Mod noetig), Ersteres direkter/performanter.
2. **Android-Adapter.** Bisher nur iOS implementiert. Analog: `.so`-Injection,
   Process-Attach, eigener Hooking-Backend — Grundgeruest laut `CLAUDE.md`
   noch offen.
3. **Echtes Function-Hooking fuer echte Spiellogik-Mods.** Die IL2CPP-Bridge
   kann aktuell nur bestehende Methoden **aufrufen** (`menuMode`-Property).
   Fuer echte Gameplay-Mods (QuickHeal soll tatsaechlich heilen, InfiniteAmmo
   soll tatsaechlich Ammo nicht verbrauchen) braucht es **Inline-Hooking**
   bestehender Terraria-Methoden (z.B. via eine Hooking-Bibliothek), nicht nur
   Aufrufe bestehender Methoden — technisch ein deutlich groesserer Schritt
   als alles bisher Gebaute.
4. **Persistenz des enabled/disabled-Zustands.** Aktuell in-memory, geht bei
   jedem Prozessstart auf die Manifest-Defaults zurueck.
5. **Falls doch mal echte Terraria-Screens gebraucht werden:** der aktuelle
   Ansatz (Screen leeren + eigenes natives Panel) umgeht bewusst tieferes
   Verstaendnis von Terrarias Rendering-Pipeline (siehe `il2cpp-bridge.md`,
   Punkte 2-5 im Denkweg). Falls spaeter doch ein echter Terraria-Screen
   gekapert werden soll, muesste dort weitergemacht werden.
