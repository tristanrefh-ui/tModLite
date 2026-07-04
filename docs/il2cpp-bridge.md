# IL2CPP Bridge — Recherche, Irrwege, finaler Ansatz

Terraria Mobile ist ein Unity/IL2CPP-Build. Diese Datei haelt fest, was
tatsaechlich funktioniert hat, was nicht, und warum — damit der Denkweg beim
naechsten Mal nicht wiederholt werden muss.

## Werkzeuge

- **IL2CppDumper** gegen `UnityFramework` (die im IPA eingebettete IL2CPP-
  Runtime + kompiliertes Spiel) ausgefuehrt. Ergebnis: `dump.cs` (dekompilierte
  Klassen-/Methoden-Signaturen als Pseudo-C#), `script.json` (Rohdaten),
  `il2cpp.h` (Struct-Layouts der **Metadaten-Datei** — Achtung, siehe unten).

### Wichtige Verwechslungsgefahr

Es gibt in der IL2CPP-Welt **drei verschiedene, aehnlich benannte Header**:

1. **Metadata-Format-Header** (was IL2CppDumper als `il2cpp.h` ausgibt) —
   beschreibt, wie `global-metadata.dat` auf der Platte aufgebaut ist
   (`Il2CppTypeDefinition`, `Il2CppGlobalMetadataHeader`, ...). Nicht die
   Laufzeit-API.
2. **Runtime-Struct-Internals** (`Il2CppClass`, `Il2CppObject` mit echten
   Feldern) — fuer direkten Offset-Zugriff, haben wir nicht gebraucht.
3. **`il2cpp-api-functions.h`** — die tatsaechlich exportierten C-Funktionen
   (`il2cpp_domain_get`, `il2cpp_class_from_name`, `il2cpp_runtime_invoke`, ...).
   **Das ist die einzige Datei, gegen die unser `Il2CppBridge.mm` verifiziert
   wurde** (liegt als `reference/il2cpp-api-functions.h` im Repo). Erkennungs-
   merkmal: Deklarationen ueber ein `DO_API(returnType, name, (params))`-Makro.

Beim ersten Versuch wurde IL2CppDumpers `il2cpp.h` faelschlich fuer die
API-Datei gehalten — enthielt aber keine der gesuchten Funktionen. Erst die
echte `il2cpp-api-functions.h` (separat besorgt) hat die Signaturen bestaetigt.

## Der Denkweg (chronologisch)

1. **Bridge-Grundlage:** `dlopen("UnityFramework", RTLD_NOLOAD)` (Fallback:
   `_dyld_image_count()`/`_dyld_get_image_name()` nach dem echten Pfad
   durchsuchen) + `dlsym` fuer die komplette benoetigte API. Alle Typen als
   opake `typedef struct X X;`-Handles nachgebaut, keine Runtime-Header
   eingebunden (die gehoeren dem Spiel, nicht uns).

2. **Erster echter Test:** `Terraria.UI.UserInterface.ActiveInstance` (statisches
   Feld) lesen, `SetState(UIState)` darauf aufrufen mit einer neu erzeugten
   `UIAchievementsMenu`-Instanz (`il2cpp_object_new` + `.ctor`-Invoke). Bridge-
   Aufruf war laut Log erfolgreich — **aber visuell aenderte sich nichts im Spiel.**

3. **Hypothese falsifiziert:** `ActiveInstance` ist offenbar nicht die
   tatsaechlich gezeichnete Instanz. Fund in `dump.cs`: `Terraria.Main` hat
   eigene statische Felder `MenuUI`/`InGameUI`, vermutlich die echten
   Zeichenziele.

4. **Umgestellt auf `Main.MenuUI`** als Ziel fuer `SetState`. Wieder erfolgreich
   laut Log, wieder keine sichtbare Aenderung.

5. **`RefreshState()` ergaenzt** (in `dump.cs` gefunden: `_isStateDirty`-Feld +
   `internal void RefreshState()` — Vermutung: ein Dirty-Flag-Mechanismus
   entscheidet, ob `SetState` tatsaechlich einen Redraw ausloest). Wichtige
   Randerkenntnis dabei: **`internal` ist zur Laufzeit kein Hindernis** —
   IL2CPP kennt keine C#-Zugriffsmodifikatoren mehr, `class_get_method_from_name`
   findet `internal`-Methoden genauso wie `public`.

6. **`Main.menuMode` als Signal-Ansatz.** Erst faelschlich als statisches Feld
   behandelt, dann faelschlich als Instanzfeld (`Main.instance` gelesen, dann
   `il2cpp_field_get_value`/`set_value` mit der Instanz). Am Ende die korrekte
   Erkenntnis: `menuMode` ist eine **C#-Auto-Property**
   (`public static int menuMode { get; set; }`), der Compiler generiert dafuer
   `get_menuMode()`/`set_menuMode(int)` als ganz normale statische Methoden —
   kein Feldzugriff noetig, kein `Main.instance` noetig.

7. **Finaler Ansatz:** Keine echten Terraria-Screens mehr kapern. `menuMode`
   nur noch als **Signalzustand** genutzt (10 = ein interner, leerer
   Terraria-Screen im Hintergrund, kein Terraria-UI sichtbar; 0 = zurueck zum
   Titelbildschirm), und **darueber** ein komplett eigenes, natives UIKit-Panel
   gelegt. `SetState`/`RefreshState`/`UIAchievementsMenu`-Code wurde entfernt
   (nicht mehr gebraucht).

## Technische Stolperfallen (fuer's naechste Mal)

- **Boxing bei Werttyp-Rueckgaben:** `il2cpp_runtime_invoke` gibt bei einem
  `int`-Rueckgabewert (wie `get_menuMode()`) ein **geboxtes** `Il2CppObject*`
  zurueck, nicht den rohen Wert. `il2cpp_object_unbox(obj)` liefert einen
  `void*` auf die eigentlichen Daten — erst danach `*(int*)` casten.
- **Instanz- vs. statische Feldfunktionen:** `il2cpp_field_get_value`/
  `il2cpp_field_set_value` haben `Il2CppObject* obj` als **ersten** Parameter
  (`(obj, field, value)`), waehrend `il2cpp_field_static_get_value` nur
  `(field, value)` nimmt — leicht zu verwechseln.
- **`il2cpp_domain_get_assemblies`** gibt `const Il2CppAssembly**` zurueck
  (Array von Pointern, nicht ein einzelner Pointer) — die einzige Signatur, bei
  der eine falsche Vermutung realistisch gewesen waere; wurde gegen die echte
  Referenzdatei verifiziert und stimmte.
- **Konstruktoren** heissen intern immer `.ctor` (CLR-Konvention).
- **`runtime_invoke`-Parameter-Array:** Referenztyp-Argumente sind der
  Objekt-Pointer direkt; Werttyp-Argumente sind ein Pointer **auf** den Wert
  (`int v = 10; void* args[] = {&v};`).
- **Logging:** `std::printf`/`fflush` reicht auf einem echten Geraet ohne
  angehaengten Debugger oft nicht — Zeilen tauchten in Console.app nicht auf.
  `NSLog` ist zuverlaessig sichtbar. Siehe auch `ios-injection.md`.

## Aktuelle finale API-Nutzung

Nur noch `Terraria.Main.get_menuMode()` / `set_menuMode(int)`, einmalig pro
Prozess aufgeloest und gecacht (`Il2CppBridge.mm`, `TML_SetMenuMode(int)`).
Keine weiteren Terraria-Klassen mehr involviert.
