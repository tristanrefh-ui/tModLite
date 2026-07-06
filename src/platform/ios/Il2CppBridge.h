#pragma once

// Setzt Terraria.Main.menuMode zur Laufzeit ueber die vom C#-Compiler
// generierten Property-Zugriffsmethoden get_menuMode()/set_menuMode(int)
// (menuMode ist eine Property, kein Feld). Wird von TMLOverlayManager beim
// Oeffnen/Schliessen des eigenen Panels aufgerufen:
//   value=10 -> leerer Terraria-Hintergrund-Screen (kein Terraria-UI sichtbar)
//   value=0  -> zurueck zum normalen Titelbildschirm
void TML_SetMenuMode(int value);

// God Mode: kein Delegate-Hook auf ein Terraria-Event (dafuer gibt es keine
// verifizierte IL2CPP-API - siehe docs/il2cpp-bridge.md), sondern ein reiner
// nativer Poll-Timer (alle 500ms), der Player.statLife auf Player.statLifeMax
// setzt, solange enabled=true ist. Kein Main.OnTick-Hook noetig.
void TML_SetGodMode(bool enabled);

// Liest Terraria.Main.gameMenu (Property, get_gameMenu(), analog zu
// menuMode). true = Hauptmenue/Ladebildschirme, false = aktiv in einer
// laufenden Welt. Nur lesend, kein Setter noetig - wir wollen den
// Spielzustand nur erkennen, nicht selbst umschalten.
// Fallback bei nicht einsatzbereiter Bridge: true (im Zweifel wie
// Hauptmenue behandeln, das bestehende, bereits verifizierte Settings-
// Panel ist der konservativere Pfad als das neue In-Game-Panel).
bool TML_IsGameMenuActive();
