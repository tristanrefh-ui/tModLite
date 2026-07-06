# experimental/

Abgeschlossene Forschungs-/Testcode, der nicht mehr Teil des aktiven Builds
ist, aber als Referenz aufgehoben wird — falls das Thema spaeter (z. B. mit
einem anderen Hooking-Ansatz oder unter anderen Rahmenbedingungen) nochmal
aufgegriffen wird. Nichts hier ist in `src/platform/ios/CMakeLists.txt`
verdrahtet.

## HookTest.h / HookTest.mm

Zwei Ansaetze, um bestehende Terraria-Methoden (`NPC.UpdateNPC(int)`) zur
Laufzeit umzuleiten, beide auf echtem, nicht-jailbroken Geraet getestet:

1. **Dobby-Inline-Hook** (`TML_EnableHookTest`) — Codepatch auf die native
   Funktionsadresse via [Dobby](https://github.com/jmpews/Dobby). Bereits der
   Self-Test (Hook auf eine triviale Funktion in der **eigenen** dylib, nicht
   in Terraria) ist auf dem Geraet abgestuerzt.
2. **MethodInfo-Pointer-Swap** (`TML_EnableMethodPointerSwapTest`) — kein
   Codepatch, sondern direktes Ueberschreiben von `MethodInfo::method`
   (Offset 0, reiner Datenspeicher). Ebenfalls auf dem Geraet getestet, auch
   ohne Erfolg.

Ergebnis und Einordnung: siehe [`docs/technical-limitations.md`](../docs/technical-limitations.md).
Kurzfassung: beide Ansaetze scheitern, was auf eine grundsaetzliche
Plattformgrenze hindeutet (iOS-Codesigning/W^X), nicht auf einen loesbaren
Bug im Testcode.

### Re-Aktivieren, falls das Thema spaeter wieder aufgegriffen wird

1. `HookTest.h`/`HookTest.mm` zurueck nach `src/platform/ios/` verschieben.
2. In `src/platform/ios/CMakeLists.txt`: `HookTest.mm` wieder zur
   `add_library(tml_ios_bootstrap SHARED ...)`-Quellenliste hinzufuegen, plus
   den Dobby-Imported-Target-Block (siehe Git-History dieser Datei,
   Commit vor diesem Cleanup) und `dobby` wieder zu
   `target_link_libraries(tml_ios_bootstrap PRIVATE ...)` hinzufuegen.
3. Aufruf-Stellen (z. B. ein Diagnose-Eintrag im UI) wieder verdrahten — siehe
   Git-History von `src/platform/ios/ui/TMLInGamePanel.mm` fuer das fruehere
   Beispiel.

Die vendorte Dobby-Lib selbst bleibt unabhaengig davon unter
`third_party/dobby/` liegen (siehe deren eigene `README.md`).

## PlayerLoopTest.h / PlayerLoopTest.mm

**Nicht** hierher verschoben, sondern weiterhin aktiv in
`src/platform/ios/` — das ist keine abgeschlossene Sackgasse, sondern
laufende Grundlagenrecherche fuer den naechsten Roadmap-Schritt
(PlayerLoop-Integration statt NSTimer-Polling, siehe `docs/roadmap.md`).
Wichtiger Unterschied zu den beiden Tests oben: hier geht es nicht um das
Patchen/Umleiten bestehender Methoden, sondern um `PlayerLoop.SetPlayerLoop`-
artige, von Unity selbst vorgesehene Erweiterungspunkte — falls das
funktioniert, umgeht es die Codesigning-Grenze komplett, weil kein fremder
Code gepatcht wird.
