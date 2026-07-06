# TModLite — Calamity-Level Content Architektur

> **Update:** Das komplette "Puppenspieler"-Pattern in diesem Dokument setzt
> voraus, dass sich bestehende Terraria-Methoden per Inline-Hooking umleiten
> lassen (Punkt 1, "Dobby-Integration"). Genau das wurde seitdem auf einem
> echten, nicht-jailbroken Geraet getestet — beide getesteten Ansaetze
> (Dobby-Inline-Hook, MethodInfo-Pointer-Swap) sind gescheitert, siehe
> [`technical-limitations.md`](technical-limitations.md). Dieses Dokument ist
> deshalb **auf Eis, nicht aktiver Plan** — als Referenz aufgehoben, falls
> spaeter ein anderer Hooking-Ansatz oder andere Rahmenbedingungen (z.B.
> Jailbreak-Support als separater, klar gekennzeichneter Zweig) das Thema
> wieder eroeffnen.
>
> Status: Konzept, noch nicht implementiert. Ergebnis einer Recherche-Session (IL2CPP-Dump-Analyse + Architektur-Diskussion). Scope: **Singleplayer only**, kein Multiplayer-Sync geplant.

## Grundproblem

Terraria Mobile ist IL2CPP-kompiliert, ohne JIT zur Laufzeit. Das bedeutet:
- Keine neuen Klassen können zur Laufzeit erschaffen werden
- `NPCID`/`ItemID`/`BuffID` sind feste `const int`-Konstanten, keine dynamische Registrierung (kein `ModContent`/`ModItem`/`ModNPC`-System wie bei tModLoader Desktop)
- `Main.maxNPCs = 200`, `Item`/`NPC`-bezogene Lookup-Arrays (Texturen, Animationen, Stats) sind exakt auf die Vanilla-ID-Range dimensioniert

**Harte Regel, die für die gesamte Architektur gilt:**
> Jede `type`-ID (NPC oder Item) muss immer eine gültige, existierende Vanilla-ID bleiben. Eine ID oberhalb der letzten Vanilla-ID führt garantiert zu `IndexOutOfRange`/Segfault beim ersten Array-Lookup (Textur, Animation, Stats) und crasht die App sofort.

Verworfene Idee: MelonLoader/Il2CppInterop-artiger Ansatz (neue Managed-Types zur Laufzeit registrieren) — existiert nicht für iOS ohne Jailbreak, da Apples JIT-Verbot für Drittanbieter-Apps das Erzeugen von ausführbarem Speicher zur Laufzeit verhindert. Neubau dieser Infrastruktur für iOS wäre ein Multi-Jahres-Projekt.

## Das Kernprinzip: "Puppenspieler"-Pattern

Statt neue IDs zu erschaffen (unmöglich), wird ein **bestehender Vanilla-Typ gekapert**: normal spawnen lassen, sofort mit einem Custom-Flag markieren, danach per **nativem Inline-Hooking (Dobby)** komplettes Verhalten/Aussehen überschreiben. Für Terraria bleibt es intern für immer der ursprüngliche Vanilla-Typ (Speicherverwaltung, Slot-Vergabe funktionieren normal) — nur die Hook-Schicht bestimmt, was der Spieler tatsächlich sieht/erlebt.

Technischer Baustein, der noch fehlt: **Dobby** (ARM64 Inline-Hooking-Library) muss in die dylib integriert werden, um Funktionszeiger wie `NPC.Update()`/`Main.DrawNPC()` zur Laufzeit umzuleiten. Bisher nutzt TModLite nur reine API-Aufrufe (`il2cpp_runtime_invoke` etc.), kein Hooking.

## Content-Kategorien im Detail

### 1. Custom-Bosse / Gegner ✅ machbar
- Bestehenden, harmlosen NPC spawnen (z.B. Slime, `NPCID=1`)
- Sofort im selben Tick: Custom-Flag setzen (ungenutztes `ai[]`-Feld, z.B. `ai[3] = 9999`)
- Hook auf `NPC.Update()`: bei gesetztem Flag → Original-Aufruf blocken, eigene C++-Logik für Bewegung/Angriffe/Projektile ausführen
- Hook auf `Main.DrawNPC()`: eigenes Sprite statt Vanilla-Textur zeichnen
- Slot-Verbrauch identisch zu jedem normalen NPC-Spawn (kein permanenter Verlust eines Slots)

### 2. Custom-Begleiter (statt Town-NPCs) ✅ machbar, mit Trade-off
**Nicht** über Town-NPCs lösen — `NPC.AnyNPCs(type)`-Check erlaubt nur 1 Instanz pro Typ, Wohnraum-Zuweisungslogik bricht bei Manipulation leicht (Gemini: "Albtraum").

**Lösung:** Harmlosen **Critter** kapern (z.B. Hase, `NPCID=46`) — triggert `AnyNPCs()` nie, braucht keinen Wohnraum.
- Hook auf `NPC.Update()`: Velocity so überschreiben, dass der Critter dem Spieler folgt (Pet-Verhalten)
- Hook auf Input-Erkennung (Touch auf NPC): Vanilla-Dialog blocken, stattdessen eigenes UIKit-Panel für Shop/Dialog öffnen
- **Trade-off:** Kein Einzug in ein Vanilla-Haus — Begleiter despawnt bei Entfernung vom Spieler, muss neu beschworen werden. Für Händler/Lore-Charaktere akzeptabel.

### 3. Custom-Waffen/Ausrüstung: "Category Hijacking" ✅ machbar
Nicht das logikärmste Item kapern (führt dazu, dass man Nahkampf-Physik/Hitboxen selbst nachbauen muss), sondern das **mechanisch passende, einfachste Vanilla-Item derselben Kategorie**:
- Nahkampfwaffen → Holzschwert (`ItemID=24`) kapern, Engine übernimmt Schwung/Hitbox, Hook überschreibt nur Schaden/Sprite/Spawnt Custom-Projektile
- Schusswaffen → Steinschlosspistole kapern, Engine übernimmt Cursor-Ausrichtung/Cooldown
- Accessoires (Flügel etc.) → schwaches Vanilla-Accessoire kapern, Engine übernimmt Slot/Gravitation, Hook überschreibt Flugzeit/Speed

**Markierung von Custom-Items:** kein `ai[]`-Array wie bei NPCs verfügbar → `Item.prefix` zweckentfremden (Vanilla-Prefixe gehen bis ~83, Custom-Marker z.B. `prefix=200`). **Trade-off:** Custom-Items können keine echten Vanilla-Prefixe mehr tragen.

Reine Deko-/Material-Items (kein Kampf-Bezug) bleiben der einfachste Fall für Crafting-Zutaten/Quest-Items/Loot ohne eigene Logik.

### 4. Custom-Biome (strukturell, nicht nur visuell) ✅ machbar
**Nicht** in Terrarias `GenPass`-Pipeline einklinken (fragiler State-Machine-Monolith, würde native Mocks von C#-Delegates brauchen). Stattdessen:
- **Post-Processing nach normaler Weltgenerierung**: Pointer auf `Main.tile`-Array holen (fix alloziert je nach Weltgröße, aber Daten mutierbar), in C++ mit Noise/Cellular-Automata eigene Höhlenformen/Zonen erzeugen, bestehende Tiles durch gekaperte Custom-Tile-IDs ersetzen
- **Biome-Erkennung**: Terrarias eigene Zähl-Logik (tile-sampling um den Spieler) hooken, parallel eigene Custom-Tile-IDs zählen → `isPlayerInCustomBiome`-Flag
- **Zonen-Mechaniken** (z.B. Säure-Schaden): Hook auf `Player.Update()` (NICHT NSTimer-Polling — das läuft asynchron zur Game-Loop und riskiert Frame-Desyncs), bei aktivem Flag Schaden/Debuffs anwenden
- **Zonen-Spawn-Pool**: zentrale Spawn-Entscheidung hooken, bei aktivem Flag eigene (gekaperte) NPCs statt Vanilla-Pool spawnen

### 5. Custom-Truhen mit Custom-Loot ✅ "erstaunlich einfach" (Gemini)
`Main.chest`-Array (~8000 Slots) nach Weltgenerierungs-Post-Processing durchsuchen, Truhen in Custom-Biome-Koordinaten identifizieren, `chest[i].item[]` (40 Slots) mit gekaperten Custom-Items befüllen. Keine bekannten Terraria-internen Validierungen, die das blockieren.

### 6. Neue Crafting-Rezepte ✅ bereits verifiziert im Dump
`Recipe`-Klasse hat echtes Erzeugungsmuster: `new Recipe()` → `SetIngredients(int[])` → `SetCraftingStation(int)` → intern `AddRecipe()`. Re-Logic nutzt selbst exakt dieses Muster (siehe die vielen `AddXYZFurniture()`-Methoden im Dump).

### 7. Magic-Storage-artiges Feature ⚠️ machbar, zwei Teile unterschiedlich schwer
- **UI-Aggregation** (einfach): eigene C++-Datenstruktur als "Source of Truth", die Inhalte mehrerer gekaperter Chest-Instanzen aggregiert, angebunden an eigenes UIKit-Panel (Terrarias natives UI-System NICHT umbauen — "endloses Reverse-Engineering-Grab")
- **Craften aus dem Lager heraus** (mittel): Hook auf den Item-Konsum-Aufruf beim Craften — falls Item nicht im Spieler-Inventar, aus eigener Storage-Struktur abziehen (zugehörige Chest-Instanz finden, `stack`-Wert reduzieren), Original-Funktion Erfolg vorgaukeln
- **Bekanntes Risiko**: rohe Zeiger auf IL2CPP-Objekte (Chest-Instanzen) können vom GC freigegeben werden (z.B. Truhe wird zerstört) → Segfault-Gefahr. Hooks auf Truhen-Zerstörung nötig, um Referenzen sauber zu invalidieren.

## ❌ Was nicht machbar ist

- **Echte neue Item/NPC/Boss-IDs** im Spiel-eigenen System (feste Compile-Zeit-Arrays, s.o.)
- **Vollwertige Town-NPCs** mit echter Wohnraum-Integration (nur der Critter-Workaround aus Punkt 2 ist praktikabel)
- **Multiplayer-Sync** von alledem — bewusst aus dem Scope genommen, würde Netzwerk-Paket-Interception + Server-Autoritäts-Konflikte bedeuten, eigenes großes Themenfeld für sich

## Persistenz: Sidecar-Save-System (Pflicht, nicht optional)

Terraria speichert flüchtigen State (`ai[]`-Werte, Custom-Prefixe) nicht automatisch mit — das `.wld`-Format ist exakt auf Vanilla-Datenstrukturen zugeschnitten, Erweitern würde die Welt korrumpieren.

**Lösung:**
- Hook auf `WorldFile.saveWorld()`: vor/nach dem normalen Speichern eigene Custom-Objekte (NPCs/Items/Chests mit Custom-Flags) mit Koordinaten + Custom-Daten in eine separate Datei schreiben (z.B. `WorldName.wld.moddata`, JSON oder eigenes Binärformat)
- Hook auf `WorldFile.loadWorld()`: nach Vanilla-Laden die `.moddata`-Datei einlesen, an den gespeicherten Koordinaten die entsprechenden Dummy-Objekte wiederfinden, Custom-Flags erneut anwenden

**Ohne dieses System sind alle Custom-Features nach jedem App-Neustart komplett verloren.** Sollte vor jeder größeren Content-Implementierung stehen.

## Empfohlene Umsetzungsreihenfolge

1. **Dobby-Integration** — ARM64-Inline-Hooking-Library in die dylib einbinden, erster Test: einen einzelnen Hook auf `NPC.Update()` für einen Slime, nur loggen (kein Verhalten ändern) — beweist, dass Hooking auf dem Setup stabil läuft
2. **Sidecar-Save-System** — Grundlage für alles Weitere, ohne das ist jeder Fortschritt flüchtig
3. **Custom-Biome (Post-Processing)** — geringstes Risiko (einmalig bei Weltgenerierung, nicht pro Frame), größter sichtbarer Effekt
4. **Custom-Bosse** — nutzt das bewährte Puppenspieler-Pattern
5. **Custom-Rezepte & Custom-Truhen** — technisch bereits größtenteils verifiziert, kein Hooking nötig
6. **Custom-Waffen (Category Hijacking)** — mehr Einzelfälle, aber gleiches Muster wiederholt anwendbar
7. **Custom-Begleiter** — Critter-Workaround
8. **Magic-Storage-UI** — baut auf Chest-Lesen (schon verifiziert) + eigenem Panel (schon vorhanden) auf

Geschätzter Aufwand fürs Gesamtpaket: mehrere Wochen bis wenige Monate, nicht Tage — deutlich über dem Umfang aller bisherigen TModLite-Features (God Mode, menuMode-Panel, ModLoader-Scan).

## Referenz: bereits verifizierte technische Bausteine (Stand heute)

- IL2CPP-Klassen/Methoden/Felder zur Laufzeit auflösen (`dlopen`/`dlsym` auf `il2cpp_*`-API)
- Statische Properties lesen/schreiben (`Main.menuMode`)
- Instanzfelder in Array-Elementen lesen/schreiben (`Main.player[Main.myPlayer].statLife`)
- Neue Instanzen bestehender Klassen erzeugen (`il2cpp_object_new` + `.ctor`)
- Value-Type Boxing/Unboxing (`il2cpp_object_unbox`)
- **Verifiziert als nicht funktionierend:** natives Inline-Hooking (Dobby) und MethodInfo-Pointer-Swap — beide auf echtem Geraet gescheitert, siehe `technical-limitations.md`
- Noch nicht verifiziert (weil Hooking als Grundlage bereits entfaellt, dadurch groesstenteils hinfaellig): Tile-Array-Zugriff, Sidecar-Persistenz
