# Technical Limitations

Ehrliche Bestandsaufnahme, was auf iOS **ohne Jailbreak** technisch nicht
(oder noch nicht) geht, und warum. Zielgruppe: jeder, der ueberlegt, ob
TModLite fuer sein Mod-Vorhaben die richtige Grundlage ist, bevor er Zeit
investiert.

## Kein Behavior-Hooking bestehender Terraria-Methoden

Das groesste Limit. TModLite kann bestehende IL2CPP-Methoden **aufrufen**
(siehe `il2cpp-bridge.md` — `menuMode`, `gameMenu`, `Player.statLife`), aber
nicht deren **Verhalten veraendern**. Fuer echte Gameplay-Mods (QuickHeal soll
tatsaechlich beim Schaden eingreifen, InfiniteAmmo soll den Ammo-Verbrauch
unterbinden) braucht es Inline-Hooking bestehender Methoden — das haben wir
auf einem echten, nicht-jailbroken Geraet getestet, und beide getesteten
Ansaetze sind gescheitert.

### Warum: Codesigning / W^X

iOS erzwingt fuer Apps ohne Jailbreak, dass Speicherseiten nicht gleichzeitig
beschreibbar und ausfuehrbar sein duerfen (W^X, "Write XOR Execute") und dass
ausfuehrbarer Code signiert sein muss. Terrarias kompilierter IL2CPP-Code
(in `UnityFramework`) liegt auf codesignierten Seiten, die zur Laufzeit nicht
umgeschrieben werden koennen — unabhaengig davon, mit welcher Bibliothek man
das versucht.

### Getestete Ansaetze (Referenz, Code in `experimental/HookTest.mm`)

| # | Ansatz | Idee | Ergebnis auf echtem Geraet |
|---|--------|------|------------------------------|
| 1 | **Dobby Inline-Hook** | ARM64-Trampolin-Hook via [Dobby](https://github.com/jmpews/Dobby), patcht die native Codeadresse von `NPC.UpdateNPC(int)` direkt | Bereits der **Self-Test** (Hook auf eine triviale Funktion in der eigenen, selbst-signierten dylib — nicht in Terraria) ist abgestuerzt. Das deutet auf eine grundsaetzliche Plattformgrenze hin, nicht nur ein Terraria-spezifisches Problem mit fremden codesignierten Seiten. |
| 2 | **MethodInfo-Pointer-Swap** | Kein Codepatch: `MethodInfo::method` (Offset 0 im Struct, reiner Datenspeicher, keine Codeseite) direkt auf die Adresse einer eigenen Funktion umbiegen — umgeht Dobby und damit potenziell auch W^X, weil kein ausfuehrbarer Speicher beschrieben wird | Ebenfalls auf dem Geraet getestet, ebenfalls ohne Erfolg — keine funktionierende Umleitung des echten Spielaufrufpfads beobachtet. |
| 3 | **Vtable-Slot-Swap** *(nicht implementiert)* | Falls `NPC.UpdateNPC` eine virtuelle Methode ist (wird zur Laufzeit ueber `il2cpp_method_get_flags`/`METHOD_ATTRIBUTE_VIRTUAL` bestimmt, siehe `experimental/HookTest.mm`), koennte man statt `MethodInfo::method` den passenden Slot in `Il2CppClass::vtable` (`reference/il2cpp.h` Zeile 275) ueberschreiben | Nicht getestet — reine Idee, kein Code dafuer existiert. Da Ansatz 2 (strukturell sehr aehnlich: Datenspeicher-Write, kein Codepatch) schon ohne Erfolg war, ist die Erwartung nicht hoch, aber unwiderlegt. |

**Fazit:** Mit den bisher getesteten Mitteln ist Behavior-Hooking bestehender
Terraria-Methoden auf einem nicht-jailbroken Geraet nicht erreichbar. Das ist
kein endgueltiger Beweis (Vtable-Ansatz offen, andere Hooking-Bibliotheken
denkbar), aber genug Signal, um es nicht als verlaessliche Grundlage fuer
Features einzuplanen. Betroffen: das komplette "Puppenspieler"-Konzept aus
`calamity-architecture.md` (Custom-Bosse, -Waffen, -Begleiter über gekaperte
Vanilla-Typen) — dieses Dokument ist deshalb aktuell als Konzept auf Eis,
nicht als aktiver Plan zu verstehen.

## Was das nicht betrifft: reine API-Aufrufe

Wichtig zur Abgrenzung — folgendes funktioniert weiterhin uneingeschraenkt,
weil es **keine bestehende Methode veraendert**, nur **aufruft**:

- Statische/Instanz-Properties lesen/schreiben (`menuMode`, `gameMenu`,
  `Player.statLife`/`statLifeMax`)
- Neue Instanzen bestehender Klassen erzeugen (`il2cpp_object_new` + `.ctor`)
- Bestehende Methoden ganz normal aufrufen (`il2cpp_runtime_invoke`)
- `Recipe`/`AddRecipe()` — neue Rezepte anlegen, weil das dem vorgesehenen
  Erweiterungsmuster von Terraria selbst entspricht, kein Hook noetig

God Mode (`Il2CppBridge.mm`, Poll-Timer auf `Player.statLife`) ist ein
Beispiel dafuer, wie weit man **ohne** Hooking kommt: kein Hook auf
`Player.Update()`, sondern ein simpler nativer Timer, der den Wert periodisch
zuruecksetzt.

## Nicht-virtuelle Methoden

Selbst falls ein Hooking-Ansatz irgendwann funktioniert: nicht-virtuelle
Methoden lassen sich prinzipbedingt nicht ueber Vtable-Manipulation umleiten
(es gibt keinen Vtable-Slot) — dafuer bliebe nur ein echter Codepatch auf die
Aufrufstelle selbst (Ansatz 1) oder auf `MethodInfo::method` (Ansatz 2),
beide oben bereits erfolglos getestet. Ob `NPC.UpdateNPC(int)` virtuell ist,
ermittelt `experimental/HookTest.mm` zur Laufzeit (`TML_IsUpdateNpcVirtual`),
war zum Zeitpunkt dieses Dokuments aber kein entscheidender Faktor mehr, weil
schon der Datenspeicher-Ansatz (2) nicht griff.

## Keine neuen NPCID/ItemID/BuffID

`NPCID`/`ItemID`/`BuffID` sind feste `const int`-Konstanten, keine dynamische
Registrierung wie `ModContent`/`ModItem`/`ModNPC` bei tModLoader Desktop.
`Main.maxNPCs`, Textur-/Animations-/Stats-Lookup-Arrays sind exakt auf die
Vanilla-ID-Range dimensioniert — jede ID oberhalb der letzten Vanilla-ID
fuehrt zu `IndexOutOfRange`/Segfault beim ersten Array-Lookup. Neue IDs sind
technisch also nicht moeglich, ohne diese Arrays selbst zu vergroessern (was
wiederum Codepatches an Terrarias eigener Initialisierung braeuchte — siehe
oben).

## Kein Data-Driven-Content wie bei tModLoader Desktop

Terraria Mobile ist IL2CPP-kompiliert, **kein JIT zur Laufzeit** — es koennen
keine neuen Klassen zur Laufzeit erschaffen werden (kein
`ModContent.Load<T>()`-Aequivalent, keine neuen `Item`/`NPC`-Subklassen).
Apples JIT-Verbot fuer Drittanbieter-Apps verhindert generell das Erzeugen
von ausfuehrbarem Speicher zur Laufzeit — ein MelonLoader/Il2CppInterop-
artiger Ansatz (neue Managed-Types zur Laufzeit registrieren) existiert dafuer
nicht auf iOS ohne Jailbreak. Content-Erweiterung ist deshalb strukturell
etwas anderes als bei tModLoader Desktop: nicht "neue Typen definieren",
sondern bestehende Vanilla-Typen zweckentfremden (Details und Grenzen davon:
`calamity-architecture.md`, mit dem Vorbehalt oben, dass dessen komplettes
Hook-basiertes Verhalten-Umschreiben nicht erreichbar war).

## Zusammenfassung

| Geht | Geht nicht (ohne Jailbreak) |
|------|------------------------------|
| Bestehende Properties/Methoden lesen & aufrufen | Verhalten bestehender Methoden aendern (Hooking) |
| Neue Instanzen bestehender Klassen | Neue Klassen/Typen zur Laufzeit |
| Neue Rezepte (`AddRecipe`) | Neue NPCID/ItemID/BuffID |
| Poll-basierte Effekte (God Mode) | Event-/Delegate-Hooks auf Spiel-interne Ablaeufe |
| UI-Overlay komplett eigenstaendig | Terrarias eigenes UI-System umbauen |
