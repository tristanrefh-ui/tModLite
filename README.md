# TModLite

Native iOS-Modding-Runtime fuer **Terraria Mobile** — **kein Jailbreak
noetig**. Kein tModLoader-Port: eigene, schlanke Runtime mit klar getrenntem
plattformunabhaengigem Core und einem iOS-Adapter, der per Sideload-Signing
(Feather o.ae.) in eine eigene, legal gekaufte Terraria-Kopie injiziert wird.

Details zur Architektur: [CLAUDE.md](CLAUDE.md), [docs/architecture.md](docs/architecture.md).

## Was funktioniert (verifiziert auf echtem, nicht-jailbroken Geraet)

- ✅ **Injection ohne Jailbreak** — via Feather/`insert_dylib`, eigene dylib
  laedt sich beim Start der App automatisch mit ([docs/ios-injection.md](docs/ios-injection.md))
- ✅ **IL2CPP-Bridge** — Terraria-Klassen/-Methoden/-Felder zur Laufzeit
  auflösen und aufrufen (`dlopen`/`dlsym` auf `UnityFramework`, kein
  Reverse-Engineering-Framework noetig) ([docs/il2cpp-bridge.md](docs/il2cpp-bridge.md))
- ✅ **God Mode** — `Player.statLife` in Echtzeit ueber die IL2CPP-Bridge gepollt
- ✅ **Natives In-Game-Overlay** — eigener Touch-Passthrough-Trigger, ein
  Hauptmenue-Settings-Panel (Mod-Liste mit Toggles) und ein separates
  In-Game-Panel, je nach erkanntem Spielzustand
- ✅ **ModLoader mit Ordner-Scan** — `manifest.json` pro Mod-Ordner wird
  erkannt, Mods koennen aktiviert/deaktiviert werden ([docs/modloader.md](docs/modloader.md))

## Was geplant, aber (noch) nicht gebaut ist

- ⚠️ **Echtes Ausfuehren von Mod-Code** — der ModLoader scannt aktuell nur
  Metadaten (`manifest.json`); Mods bringen noch keinen echten Code mit
  ([docs/modloader.md](docs/modloader.md))
- ⚠️ **Custom-Inhalte** (Bosse, Waffen, Begleiter, Rezepte, Invasions-Trigger
  o.ae.) — durchdacht in [docs/calamity-architecture.md](docs/calamity-architecture.md),
  aber **auf Eis**: das zugrunde liegende Konzept braucht Behavior-Hooking
  bestehender Terraria-Methoden, und das funktioniert ohne Jailbreak nicht
  (siehe naechster Punkt)
- ⚠️ **Android-Adapter** — bisher nur iOS implementiert
- ⚠️ PlayerLoop-Integration statt Poll-Timer, Custom-Texturen, Mod-Zustand
  persistieren — siehe [docs/roadmap.md](docs/roadmap.md)

## ⚠️ Bekannte Grenze

**Kein Verhalten-Hooking bestehender Methoden ohne Jailbreak.** iOS erzwingt
Codesigning/W^X — ausfuehrbarer Speicher fremder, codesignierter Prozesse
kann zur Laufzeit nicht umgeschrieben werden. Zwei Ansaetze wurden auf einem
echten Geraet getestet (Dobby-Inline-Hook, MethodInfo-Pointer-Swap), beide
sind gescheitert. TModLite kann bestehende Methoden **aufrufen** (God Mode,
menuMode-Steuerung), aber nicht ihr Verhalten **aendern**. Details, getestete
Ansaetze und was das fuer Mod-Ideen bedeutet:
[docs/technical-limitations.md](docs/technical-limitations.md).

## Screenshots

*(Platzhalter — fuege hier eigene Screenshots vom In-Game-Overlay und dem
Settings-Panel ein, sobald verfuegbar.)*

## Voraussetzungen

- Eigene, legal gekaufte Kopie von Terraria (iOS)
- Eigenes iOS-Geraet — **kein Jailbreak noetig**
- Ein Sideload-Signing-Tool (z.B. [Feather](https://github.com/khcrysalis/Feather),
  ESign, AltStore) mit eigenem Zertifikat/Profil
- Volles Xcode (nicht nur Command Line Tools) mit iOS-SDK, `xcode-select -p`
  muss auf `Xcode.app/Contents/Developer` zeigen
- CMake >= 3.20

## Setup: Build → Inject → Test

```bash
# 1. dylib bauen (arm64, echtes Device)
./scripts/build-ios.sh
# -> build-ios/src/platform/ios/libtml_ios_bootstrap.dylib

# 2. In die eigene Terraria-IPA einbetten (z.B. via insert_dylib oder
#    Feathers eingebaute Tweak-Injection) und mit Feather resignen.

# 3. Installieren, App starten, Trigger-Button antippen.
```

Ausfuehrliche Schritt-fuer-Schritt-Anleitung inkl. Logging-Tipps:
[docs/ios-injection.md](docs/ios-injection.md).

### Desktop-Build (Entwicklung/Tests, ohne echtes Spiel)

```bash
cmake -S . -B build
cmake --build build
./build/src/sim/tml_sim
```

Baut `tml_core` (Core-Lib) und `tml_sim` (Simulation Harness mit
Test-Mods, Live-ASCII-Visualisierung). Sinnvoll, um Core-Aenderungen zu
testen, ohne ein Geraet zu brauchen — siehe Dev-Workflow in [CLAUDE.md](CLAUDE.md).

### Android-Build (nur `tml_core`, Adapter noch nicht implementiert)

```bash
export ANDROID_NDK_HOME=/pfad/zum/ndk
./scripts/build-android.sh
```

## Weitere Docs

- [docs/architecture.md](docs/architecture.md) — Core/Platform-Trennung
- [docs/ios-injection.md](docs/ios-injection.md) — kompletter Injection-Workflow
- [docs/il2cpp-bridge.md](docs/il2cpp-bridge.md) — IL2CPP-Recherche, was funktioniert und warum
- [docs/technical-limitations.md](docs/technical-limitations.md) — was nicht geht und warum
- [docs/modloader.md](docs/modloader.md) — Mod-Ordner-Scan
- [docs/roadmap.md](docs/roadmap.md) — naechste Schritte
- [CONTRIBUTING.md](CONTRIBUTING.md) — Build/Test/PR-Erwartungen

## Disclaimer

Nur fuer den eigenen, persoenlichen Gebrauch mit einer legal erworbenen
Kopie von Terraria. Kein Redistribute von Terraria-eigenen Dateien/Assets.
Dieses Projekt steht in keinem Zusammenhang mit Re-Logic oder 505 Games und
wird von keinem der beiden unterstuetzt oder autorisiert. Nutzung auf eigene
Verantwortung.
