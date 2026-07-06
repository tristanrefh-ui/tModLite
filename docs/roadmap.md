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
    (leerer Terraria-Hintergrund waehrend das eigene Panel offen ist),
    `Terraria.Main.gameMenu` gelesen, um zwischen Hauptmenue und laufender
    Welt zu unterscheiden.
  - Zwei getrennte Panels je nach Kontext: `TMLOverlayPanel` (Hauptmenue,
    aendert `menuMode`) und `TMLInGamePanel` (laufende Welt, aendert nichts
    am Spielzustand) — siehe `architecture.md`.

## Abgeschlossen, kein weiterer Schritt geplant

- **Behavior-Hooking bestehender Methoden.** Zwei Ansaetze real auf dem
  Geraet getestet (Dobby-Inline-Hook, MethodInfo-Pointer-Swap), beide ohne
  Erfolg — siehe `technical-limitations.md`. Referenzcode dazu liegt in
  `experimental/`, ist aber nicht mehr Teil des aktiven Builds. Damit ist
  auch das komplette Hook-basierte "Puppenspieler"-Konzept aus
  `calamity-architecture.md` vorerst nicht umsetzbar.

## Sinnvolle naechste Schritte

1. **PlayerLoop-Integration statt NSTimer-Polling.** God Mode (und jedes
   zukuenftige Poll-basierte Feature) laeuft aktuell ueber einen reinen
   nativen Timer (500ms), unabhaengig von Unitys eigenem Frame-Takt —
   funktioniert, ist aber nicht frame-synchron. `experimental/PlayerLoopTest.mm`
   (aktiv, kein abgeschlossenes Experiment) untersucht, ob sich
   `UnityEngine.LowLevel.PlayerLoop`-ICalls (`GetCurrentPlayerLoop`/
   `SetPlayerLoop`) trotz Managed-Code-Stripping direkt ueber
   `il2cpp_resolve_icall` ansprechen lassen. Wichtiger Unterschied zum
   abgeschlossenen Hooking-Kapitel oben: hier geht es um einen von Unity
   selbst vorgesehenen Erweiterungspunkt (eigenes Subsystem einhaengen),
   nicht um das Patchen/Umleiten bestehender Methoden — sollte also nicht an
   derselben Codesigning-Grenze scheitern.
2. **`IContentSource`-artiger Mechanismus fuer Custom-Texturen.** Aktuell hat
   TModLite keinen Weg, eigene Sprites/Texturen ins laufende Spiel zu
   bringen (jedes "Custom"-Feature aus `calamity-architecture.md`, das
   eigenes Aussehen braucht, haengt daran). Terrarias eigenes Content-Loading
   (`IContentSource`) als Erweiterungspunkt pruefen — ob sich darueber
   zusaetzliche Texturen registrieren lassen, ohne bestehende Lade-Methoden
   zu hooken.
3. **Mehr Delegate-/Event-basierte Anknuepfungspunkte nutzen.** Statt Poll-
   Timern (God Mode) oder gescheitertem Hooking: pruefen, welche echten
   `Action`/`event`-Felder Terraria selbst exponiert (analog zum Ansatz bei
   `menuMode`/`gameMenu`, aber fuer tatsaechliche Spielereignisse statt reine
   Zustands-Properties) und sich darueber verdrahten lassen, ohne
   `il2cpp_method_get_flags`/Codepatches.
4. **Echtes dynamisches Mod-Code-Laden.** Aktuell sind gescannte Mods reine
   Metadaten (siehe `modloader.md`). Naechster Schritt: ein definiertes
   Format, wie ein Mod-Ordner tatsaechlich Code mitbringt und der
   `ModLoader` ihn laedt — z.B. eine mitgelieferte `.dylib`/`.so` mit einer
   festen C-ABI-Schnittstelle (passend zur `Mod`-Basisklasse), oder eine
   eingebettete Scriptsprache (z.B. Lua) fuer plattformunabhaengige Mods ohne
   Compile-Schritt pro Zielgeraet. Letzteres waere robuster fuer Verteilung
   (keine arm64-Binaries pro Mod noetig), Ersteres direkter/performanter.
5. **Android-Adapter.** Bisher nur iOS implementiert. Analog: `.so`-Injection,
   Process-Attach, eigener Hooking-Backend — Grundgeruest laut `CLAUDE.md`
   noch offen. Gleiche Codesigning-Vorbehalte wie unter `technical-limitations.md`
   sind auf Android nicht direkt uebertragbar (andere Plattform-Policy),
   muessten separat verifiziert werden.
6. **Persistenz des enabled/disabled-Zustands.** Aktuell in-memory, geht bei
   jedem Prozessstart auf die Manifest-Defaults zurueck.
7. **Falls doch mal echte Terraria-Screens gebraucht werden:** der aktuelle
   Ansatz (Screen leeren + eigenes natives Panel) umgeht bewusst tieferes
   Verstaendnis von Terrarias Rendering-Pipeline (siehe `il2cpp-bridge.md`,
   Punkte 2-5 im Denkweg). Falls spaeter doch ein echter Terraria-Screen
   gekapert werden soll, muesste dort weitergemacht werden.
