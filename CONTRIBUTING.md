# Contributing

Kurzfassung fuer PRs. Architektur-Details: [CLAUDE.md](CLAUDE.md),
[docs/architecture.md](docs/architecture.md).

## Bauen

```bash
# Desktop (Core + Simulation, kein Geraet noetig)
cmake -S . -B build
cmake --build build
./build/src/sim/tml_sim

# iOS (Core + Bootstrap-dylib, braucht volles Xcode)
./scripts/build-ios.sh
```

## Testen

Kein automatisiertes Test-Framework — der `src/sim/`-Simulation-Harness
(60 FPS Update-Loop, Fake Player/World-State) ist der Test-Weg fuer
Core-Aenderungen. Reihenfolge, siehe [CLAUDE.md](CLAUDE.md#dev-workflow-reihenfolge-einhalten):

1. Core-Feature in `src/core/` implementieren
2. In der Simulation (`src/sim/`) testen, bevor der Platform-Layer angefasst wird
3. Erst danach: iOS/Android-Adapter

Fuer iOS-Aenderungen gibt es keinen Simulator-Ersatz fuer den echten
IL2CPP-Zugriff — Testzyklus (Build → Inject via Feather → Console.app-Logs)
steht in [docs/ios-injection.md](docs/ios-injection.md).

## Harte Regel: Core/Platform-Trennung

`src/core/` darf **nie** wissen, wie er ins Spiel injiziert wird — kein
iOS/Android-spezifischer Code, keine Injection-Details, keine Offsets, kein
Memory-Hacking im Core. Kommunikation nur ueber `GameContext`. PRs, die diese
Grenze verwischen, werden nicht angenommen.

## Ehrlichkeit statt Marketing

Dieses Projekt dokumentiert bewusst, was **nicht** geht
([docs/technical-limitations.md](docs/technical-limitations.md)), nicht nur
was geht. Bitte bei PRs:

- Keine Feature-Beschreibungen, die suggerieren, dass Verhalten bestehender
  Terraria-Methoden gehookt wird, wenn es tatsaechlich nur ein Aufruf/Poll ist.
- Neue Erkenntnisse zu Grenzen (z.B. ein weiterer gescheiterter
  Hooking-Versuch) gehoeren nach `docs/technical-limitations.md`, nicht
  stillschweigend geloescht.
- Experimenteller/abgeschlossener Testcode gehoert nach `experimental/` mit
  kurzer Begruendung im dortigen `README.md`, nicht geloescht und nicht in
  `src/` liegen gelassen.

## Sonstiges

- Naming: `PascalCase` fuer Klassen, `camelCase` fuer Methoden
- Header/Source getrennt (`.hpp`/`.cpp` bzw. `.h`/`.mm`)
- Groessere Konzept-/Recherche-Dokumente gehoeren nach `docs/`, nicht in
  `CLAUDE.md` (das soll unter ~5k Tokens bleiben)
