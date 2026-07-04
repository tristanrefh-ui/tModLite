# ModLoader — Ordner-Scan

## Wie der Scan funktioniert

`ModLoader::scanDirectory(path)` (`src/core/ModLoader.cpp`):

1. Iteriert alle direkten Unterordner von `path`.
2. Sucht in jedem Unterordner nach `manifest.json`.
3. Parst sie via `nlohmann::json`. Fehlt die Datei oder ist sie kein
   gueltiges JSON, wird der Ordner uebersprungen (kein Absturz).
4. Legt pro gueltigem Manifest einen reinen Metadaten-`Entry` an
   (`mod == nullptr` — kein Code, nur Name/Version/enabled-Flag).
5. Gibt die Anzahl neu gefundener Mods zurueck.

Gescannte Eintraege landen in derselben Liste wie ueber `registerMod()`
registrierte echte Mods (siehe `architecture.md`) — `modCount()`/`modName()`/
`modVersion()`/`isModEnabled()` behandeln beide Arten gleich.

## manifest.json-Format

```json
{
  "name": "QuickHeal",
  "version": "1.0",
  "enabled": true
}
```

- `name` (string) — **Pflichtfeld**. Fehlt es oder ist es kein String, wird
  der Ordner uebersprungen.
- `version` (string) — optional, Default `"0.0"`.
- `enabled` (bool) — optional, Default `true`.

## Neue Mod hinzufuegen

1. Neuen Ordner unter `mods/<ModName>/` anlegen.
2. `manifest.json` mit mindestens `name` reinlegen.
3. Fertig — wird beim naechsten `scanDirectory("mods/")`-Aufruf automatisch
   gefunden (Desktop-Sim: `src/sim/main.cpp`, iOS: `Bootstrap.mm`).

Aktuell im Repo: `mods/QuickHeal/` (enabled) und `mods/InfiniteAmmo/`
(disabled) — beides Fake-Mods ohne echte Spiellogik, nur zum Testen der
Scan-/Anzeige-/Toggle-Pipeline.

## Wo iOS scannt

Auf einem echten Geraet ohne Jailbreak ist der App-eigene Bundle-Ordner
nicht beschreibbar. `Bootstrap.mm` scannt deshalb
`<App-Documents>/mods` (via `NSSearchPathForDirectoriesInDomains`) —
der einzige Ort, an den man ohne Jailbreak schreiben kann (z.B. ueber die
Dateien-App oder Datei-Freigabe via Finder/iTunes). Auf einem frischen
Geraet ohne manuell kopierte Mod-Ordner ist das Ergebnis korrekterweise
leer ("Keine Mods geladen") — kein Fake-Wert, ein echter leerer Scan.

## Aktueller Stand / Grenze

Das ist reine **Metadaten- und Toggle-Verwaltung**. `toggleMod(name)` kippt
nur das `enabled`-Flag im `ModLoader` — es fuehrt **keinen** Mod-Code aus,
weil die gescannten Eintraege gar keinen Code haben (`mod == nullptr`).
QuickHeal und InfiniteAmmo tun also (noch) nichts, wenn sie aktiviert werden.

Echtes Laden von Mod-Code aus dem Ordner ist die naechste Ausbaustufe —
siehe `roadmap.md`.
