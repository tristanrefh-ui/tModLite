#pragma once

// Schritt A, v2 (reines Lesen, kein Aufruf, keine Mutation):
// UnityEngine.LowLevel.PlayerLoop ist per Managed-Code-Stripping komplett
// aus den C#-Metadaten entfernt (bestaetigt per dump.cs-Grep) -
// il2cpp_class_from_name schlaegt deshalb fehl. Statt ueber die C#-Klasse
// versuchen wir, die nativen Funktionszeiger der zugehoerigen Internal
// Calls direkt ueber il2cpp_resolve_icall() zu bekommen - das ist eine
// vom C#-Metadatenbestand komplette unabhaengige, native Engine-Tabelle.
// Loggt nur die zurueckgegebenen Pointer (0x0 = nicht gefunden), ruft sie
// NICHT auf. Wird einmalig beim Start der dylib aufgerufen (siehe
// Bootstrap.mm), kein UI-Trigger noetig - rein diagnostisch.
void TML_LogCurrentPlayerLoop();
