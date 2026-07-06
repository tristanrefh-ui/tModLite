# iOS Injection Workflow

Kompletter Weg vom Core-Build zum laufenden Overlay auf einem echten,
nicht-jailbroken Geraet.

## 1. dylib bauen

```bash
./scripts/build-ios.sh
```

Baut `tml_core` (statisch) + `tml_ios_bootstrap` (SHARED, arm64, echtes Device)
via `cmake/ios.toolchain.cmake` (leetal/ios-cmake), `PLATFORM=OS64`,
`DEPLOYMENT_TARGET=15.0`. Ergebnis: `build-ios/src/platform/ios/libtml_ios_bootstrap.dylib`.

Voraussetzung: volles Xcode (nicht nur Command Line Tools) — `xcode-select -p`
muss auf `Xcode.app/Contents/Developer` zeigen, sonst fehlt das iOS-SDK.

## 2. IPA besorgen

Eigene, legal gekaufte Terraria-IPA (z.B. via eigenem Apple-Account
heruntergeladen/extrahiert). Kein Redistribute, kein Teilen — nur lokale
Modifikation der eigenen Kopie.

## 3. dylib in die IPA einbetten

- `libtml_ios_bootstrap.dylib` als eigenes Framework in `Payload/Terraria.app/Frameworks/`
  ablegen.
- Der Haupt-Executable braucht einen zusaetzlichen `LC_LOAD_DYLIB`-Load-Command,
  der auf `@executable_path/Frameworks/libtml_ios_bootstrap.dylib` zeigt
  (Standard-Technik: `insert_dylib`, oder Feathers eingebauter
  Tweak-Injection-Mechanismus macht das automatisch beim Resign).

## 4. Signieren via Feather

Feather (Sideload-Signing-Tool) resignt die komplette modifizierte IPA mit
einem eigenen Zertifikat/Profil — kein Jailbreak noetig. Feather uebernimmt
dabei auch das Neu-Signieren der eingebetteten dylib selbst (jede Binaerdatei
im Bundle braucht eine gueltige Signatur vom selben Signer).

## 5. Installieren + Testen

Ueber Feather auf das Geraet installieren. Beim Start der App:

1. dyld laedt alle Frameworks, darunter `libtml_ios_bootstrap.dylib`.
2. Der `__attribute__((constructor))`-Block in `Bootstrap.mm` feuert automatisch
   waehrend des dylib-Ladens, **vor** `main()`/`UIApplicationMain()` der App.
3. `runtime.start()` laeuft synchron.
4. `dispatch_after(1.5s, ...)` verzoegert die eigentliche UIKit-Arbeit, bis
   die Host-App ihre UI aufgebaut hat (zu frueh waere `UIApplication.sharedApplication`
   evtl. noch nicht bereit).
5. Danach: Overlay-Fenster (`TMLOverlayWindow`, Touch-Passthrough via
   `hitTest:`-Override), Trigger-Text, natives Settings-Panel.

## Logging beim Testen

**Wichtig:** `NSLog`/`os_log` statt `printf`/`std::cout` verwenden. Rohes
stdout eines per Feather (ohne angehaengten Debugger) gestarteten Prozesses
landet oft nicht in Console.app — `NSLog` dagegen zuverlaessig. Diese
Erkenntnis kam aus echtem Debugging, siehe `il2cpp-bridge.md`.

Testzyklus: `./scripts/build-ios.sh` → dylib neu einbetten/resignen via
Feather → neu installieren → Console.app (Geraet auswaehlen, nach `[Il2CppBridge]`
/ `[iOS Bootstrap]` / `[TMLOverlayManager]` filtern).

## Grenze dieses Injection-Wegs

Dieser komplette Weg (Feather/`insert_dylib`, kein Jailbreak) erlaubt reines
**Hinzufuegen** von Code (die eigene dylib) und **Aufrufen** bestehender
Terraria-Methoden ueber die IL2CPP-Bridge — er erlaubt nicht das
**Veraendern** von bestehendem Terraria-Code zur Laufzeit (Codesigning/W^X
verhindert das unabhaengig vom gewaehlten Hooking-Ansatz). Details und
getestete Ansaetze: `technical-limitations.md`.
