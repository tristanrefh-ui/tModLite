#pragma once

#include <cstdint>

// Minimaler Beweis, dass natives Inline-Hooking (Dobby) auf unserem Setup
// grundsaetzlich funktioniert: hookt Terraria.NPC.UpdateNPC(int i) ueber
// die tatsaechliche native Codeadresse der Methode, loggt nur (jeder 60.
// Aufruf) und reicht den Original-Aufruf unveraendert per Trampolin durch -
// kein Verhalten wird geaendert. Reiner Nachweis-Test, kein Feature.
//
// Installiert sich beim ersten Aufruf einmalig (idempotent) und bleibt fuer
// den Rest des Prozesses aktiv; kein Deinstallieren vorgesehen.
void TML_EnableHookTest();

// Separater Test, KEIN Dobby: statt die native Codeadresse zu hooken,
// ueberschreibt dieser Test direkt MethodInfo::method (Offset 0, reiner
// Pointer-Write, kein Codepatch) mit der Adresse einer eigenen Funktion.
// Umgeht damit potenzielle Codesigning/W^X-Probleme von Dobby komplett,
// weil MethodInfo-Structs normaler (nicht ausfuehrbarer) Speicher sind.
// Fuer den ersten Testlauf wird bewusst NICHT die Original-Methode
// aufgerufen - Verhalten kann fuer diesen Testlauf kaputt sein, das ist
// akzeptiert. Kein Deinstallieren vorgesehen.
void TML_EnableMethodPointerSwapTest();

// Wie oft TmlMethodPointerSwapReplacement tatsaechlich aufgerufen wurde -
// sichtbar im In-Game-Panel, damit man ohne Console.app sieht, ob der
// reale Spiel-Code die Umleitung nutzt (0 falls nie).
uint64_t TML_GetMethodInfoSwapCallCount();

// Ermittelt, ob NPC.UpdateNPC(int) eine virtuelle Methode ist - ueber die
// echte il2cpp_method_get_flags()-API und die verifizierte
// METHOD_ATTRIBUTE_VIRTUAL-Konstante (reference/il2cpp.h Zeile 55), NICHT
// per dump.cs (liegt uns hier nicht vor) oder geratenem Struct-Offset.
// Wird als Nebeneffekt von ResolveNpcUpdateMethod() ermittelt und
// gecached, also erst aussagekraeftig nachdem einer der beiden Tests
// oben einmal gelaufen ist. Rueckgabe: -1 = noch nicht ermittelt,
// 0 = nicht virtuell, 1 = virtuell.
int TML_IsUpdateNpcVirtual();
