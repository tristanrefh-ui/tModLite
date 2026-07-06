#import "HookTest.h"

#import <Foundation/Foundation.h>

#include <atomic>
#include <cstdint>
#include <cstring>
#include <dlfcn.h>
#include <mach-o/dyld.h>

#include "dobby.h"

// ECMA-335/Mono-Standardwert, gegen reference/il2cpp.h Zeile 55 verifiziert
// (#define METHOD_ATTRIBUTE_VIRTUAL 0x0040) - nicht geraten.
static constexpr uint32_t kTmlMethodAttributeVirtual = 0x0040;

// Dobbys eigenes internes Diagnose-Logging (ERROR_LOG/DEBUG_LOG in seiner
// Hook-Routing-Logik) ist standardmaessig auf rohes printf() nach stdout
// verdrahtet - auf einem debugger-losen Sideload-Prozess unsichtbar, exakt
// dasselbe Problem, das wir bei unserem eigenen Logging schon einmal
// geloest haben. logger_set_options() ist nicht in dobby.h deklariert
// (unser vendorter Header exponiert nur die "Nutzer"-API), aber ein
// echtes, exportiertes Symbol in third_party/dobby/lib/ios/libdobby.a -
// per nm verifiziert (_logger_set_options, _logger_create,
// _logger_log_impl, alle global sichtbar). Signatur 1:1 aus Dobbys
// eigenem external/logging/logging/logging.h uebernommen.
extern "C" {
typedef enum {
    kTmlDobbyLogLevelDebug = 0,
    kTmlDobbyLogLevelInfo = 1,
    kTmlDobbyLogLevelWarn = 2,
    kTmlDobbyLogLevelError = 3,
    kTmlDobbyLogLevelFatal = 4,
} TmlDobbyLogLevel;

void logger_set_options(void* logger, const char* tag, const char* file, TmlDobbyLogLevel level,
                         bool enable_time_tag, bool enable_syslog);
}

namespace {

// --- Eigene, minimale IL2CPP-Deklarationen, bewusst isoliert von
// Il2CppBridge.mm (dort in einem anonymous namespace, nicht exportiert). Das
// ist ein reiner Nachweis-Test - keine gemeinsame Infrastruktur mit dem
// bereits verifizierten menuMode/God-Mode-Code anfassen. Signaturen gegen
// reference/il2cpp-api-functions.h abgeglichen.
extern "C" {
typedef struct Il2CppDomain Il2CppDomain;
typedef struct Il2CppThread Il2CppThread;
typedef struct Il2CppAssembly Il2CppAssembly;
typedef struct Il2CppImage Il2CppImage;
typedef struct Il2CppClass Il2CppClass;
typedef struct MethodInfo MethodInfo;
}

using Il2CppDomainGetFn = Il2CppDomain* (*)();
using Il2CppThreadAttachFn = Il2CppThread* (*)(Il2CppDomain*);
using Il2CppDomainGetAssembliesFn = const Il2CppAssembly** (*)(const Il2CppDomain*, size_t*);
using Il2CppAssemblyGetImageFn = const Il2CppImage* (*)(const Il2CppAssembly*);
using Il2CppImageGetNameFn = const char* (*)(const Il2CppImage*);
using Il2CppClassFromNameFn = Il2CppClass* (*)(const Il2CppImage*, const char*, const char*);
using Il2CppClassGetMethodFromNameFn = const MethodInfo* (*)(Il2CppClass*, const char*, int);
using Il2CppRuntimeClassInitFn = void (*)(Il2CppClass*);
using Il2CppMethodGetFlagsFn = uint32_t (*)(const MethodInfo*, uint32_t*);

// -1 = noch nicht ermittelt, 0 = nicht virtuell, 1 = virtuell. Wird als
// Nebeneffekt von ResolveNpcUpdateMethod() gesetzt, ueber die echte
// il2cpp_method_get_flags()-API - kein dump.cs, kein geratener Offset.
std::atomic<int> g_updateNpcVirtual{-1};

void* OpenUnityFrameworkHandle() {
    void* handle = dlopen("UnityFramework", RTLD_NOLOAD);
    if (handle) {
        return handle;
    }

    uint32_t imageCount = _dyld_image_count();
    for (uint32_t i = 0; i < imageCount; ++i) {
        const char* imageName = _dyld_get_image_name(i);
        if (imageName && std::strstr(imageName, "UnityFramework")) {
            handle = dlopen(imageName, RTLD_NOLOAD);
            if (handle) {
                return handle;
            }
        }
    }
    return nullptr;
}

template <typename FnPtr>
bool ResolveSymbol(void* handle, const char* name, FnPtr& outFn) {
    void* symbol = dlsym(handle, name);
    NSLog(@"[TML_HOOK] dlsym(%s) -> %s", name, symbol ? "OK" : "NULL");
    outFn = reinterpret_cast<FnPtr>(symbol);
    return symbol != nullptr;
}

// Gemeinsam von beiden Tests (Dobby-Hook und Pointer-Swap) genutzt: loest
// die IL2CPP-API auf, findet Terraria.NPC und darin UpdateNPC(int). Gibt
// nullptr zurueck, falls irgendein Schritt fehlschlaegt (jeder Schritt
// loggt seinen eigenen Erfolg/Misserfolg).
const MethodInfo* ResolveNpcUpdateMethod() {
    void* handle = OpenUnityFrameworkHandle();
    if (!handle) {
        NSLog(@"[TML_HOOK] Abbruch: UnityFramework-Handle nicht gefunden.");
        return nullptr;
    }

    Il2CppDomainGetFn domain_get = nullptr;
    Il2CppThreadAttachFn thread_attach = nullptr;
    Il2CppDomainGetAssembliesFn domain_get_assemblies = nullptr;
    Il2CppAssemblyGetImageFn assembly_get_image = nullptr;
    Il2CppImageGetNameFn image_get_name = nullptr;
    Il2CppClassFromNameFn class_from_name = nullptr;
    Il2CppClassGetMethodFromNameFn class_get_method_from_name = nullptr;
    Il2CppRuntimeClassInitFn runtime_class_init = nullptr;
    Il2CppMethodGetFlagsFn method_get_flags = nullptr;

    bool ok = true;
    ok &= ResolveSymbol(handle, "il2cpp_domain_get", domain_get);
    ok &= ResolveSymbol(handle, "il2cpp_thread_attach", thread_attach);
    ok &= ResolveSymbol(handle, "il2cpp_domain_get_assemblies", domain_get_assemblies);
    ok &= ResolveSymbol(handle, "il2cpp_assembly_get_image", assembly_get_image);
    ok &= ResolveSymbol(handle, "il2cpp_image_get_name", image_get_name);
    ok &= ResolveSymbol(handle, "il2cpp_class_from_name", class_from_name);
    ok &= ResolveSymbol(handle, "il2cpp_class_get_method_from_name", class_get_method_from_name);
    ok &= ResolveSymbol(handle, "il2cpp_runtime_class_init", runtime_class_init);
    ok &= ResolveSymbol(handle, "il2cpp_method_get_flags", method_get_flags);
    if (!ok) {
        NSLog(@"[TML_HOOK] Abbruch: nicht alle Pflicht-Symbole aufloesbar.");
        return nullptr;
    }

    NSLog(@"[TML_HOOK] UnityFramework-Handle: %p", handle);

    Il2CppDomain* domain = domain_get();
    NSLog(@"[TML_HOOK] il2cpp_domain_get() -> %p", static_cast<void*>(domain));
    if (!domain) {
        NSLog(@"[TML_HOOK] Abbruch: il2cpp_domain_get() -> NULL.");
        return nullptr;
    }

    Il2CppThread* thread = thread_attach(domain);
    NSLog(@"[TML_HOOK] il2cpp_thread_attach() -> %p", static_cast<void*>(thread));

    size_t assemblyCount = 0;
    const Il2CppAssembly** assemblies = domain_get_assemblies(domain, &assemblyCount);
    NSLog(@"[TML_HOOK] il2cpp_domain_get_assemblies() -> %p, count=%zu",
          static_cast<const void*>(assemblies), assemblyCount);
    if (!assemblies || assemblyCount == 0) {
        NSLog(@"[TML_HOOK] Abbruch: keine Assemblies gefunden.");
        return nullptr;
    }

    Il2CppClass* npcClass = nullptr;
    for (size_t i = 0; i < assemblyCount; ++i) {
        const Il2CppImage* image = assembly_get_image(assemblies[i]);
        if (!image) {
            NSLog(@"[TML_HOOK]   Assembly[%zu]: assembly_get_image() -> NULL, ueberspringe", i);
            continue;
        }
        const char* imageName = image_get_name(image);
        Il2CppClass* candidate = class_from_name(image, "Terraria", "NPC");
        NSLog(@"[TML_HOOK]   Assembly[%zu]=%s -> class_from_name(Terraria.NPC) = %s", i,
              imageName ? imageName : "?", candidate ? "OK" : "null");
        if (candidate) {
            npcClass = candidate;
            break;
        }
    }
    if (!npcClass) {
        NSLog(@"[TML_HOOK] Abbruch: Terraria.NPC nicht gefunden.");
        return nullptr;
    }
    NSLog(@"[TML_HOOK] Terraria.NPC-Klasse: %p", static_cast<void*>(npcClass));

    NSLog(@"[TML_HOOK] Rufe il2cpp_runtime_class_init(NPC) auf...");
    runtime_class_init(npcClass);
    NSLog(@"[TML_HOOK] il2cpp_runtime_class_init(NPC) zurueckgekehrt.");

    NSLog(@"[TML_HOOK] Suche NPC.UpdateNPC Methode (il2cpp_class_get_method_from_name, argsCount=1)...");
    const MethodInfo* updateMethod = class_get_method_from_name(npcClass, "UpdateNPC", 1);
    NSLog(@"[TML_HOOK] NPC.UpdateNPC MethodInfo: %p", static_cast<const void*>(updateMethod));
    if (!updateMethod) {
        NSLog(@"[TML_HOOK] Abbruch: NPC.UpdateNPC(int) nicht gefunden.");
        return nullptr;
    }

    uint32_t iflags = 0;
    uint32_t flags = method_get_flags(updateMethod, &iflags);
    bool isVirtual = (flags & kTmlMethodAttributeVirtual) != 0;
    g_updateNpcVirtual.store(isVirtual ? 1 : 0);
    NSLog(@"[TML_HOOK] NPC.UpdateNPC Flags: 0x%08x (virtual=%@)", flags, isVirtual ? @"JA" : @"NEIN");

    return updateMethod;
}

// Angenommene native Aufrufkonvention (IL2CPP-Codegen-Konvention, nicht aus
// einer offiziellen Datei verifizierbar - siehe Absprache mit dem Nutzer):
// this-Pointer + deklarierte Parameter + ein angehaengter versteckter
// MethodInfo*-Parameter.
using NpcUpdateFn = void (*)(void* npcThis, int32_t i, void* methodInfo);

NpcUpdateFn g_originalNpcUpdate = nullptr;
uint64_t g_callCount = 0;

// --- Self-Test: hookt eine triviale Funktion in UNSERER EIGENEN dylib,
// nicht in Terrarias Binary. Damit lasst sich unterscheiden, ob Dobby auf
// diesem Setup GRUNDSAETZLICH funktioniert (Self-Test OK, aber der echte
// NPC.UpdateNPC-Hook schlaegt fehl -> Problem ist spezifisch das Patchen
// von Terrarias fremden, codesignierten Speicherseiten) oder ob Dobby hier
// gar nicht hooken kann (Self-Test schlaegt ebenfalls fehl -> echte
// Plattform-Grenze, unabhaengig von Terraria - dann ist das komplette
// Puppenspieler-Pattern aus docs/calamity-architecture.md so nicht
// umsetzbar).
//
// Ergebnis eines ersten Testlaufs: der Self-Test selbst ist gecrasht -
// deutet auf eine echte Plattform-Grenze hin (Codesigning/W^X), nicht nur
// ein Terraria-spezifisches Problem. Deshalb der separate, Dobby-freie
// Pointer-Swap-Test weiter unten.
__attribute__((noinline)) int TmlDobbySelfTestTarget() {
    return 42;
}

using SelfTestFn = int (*)();
SelfTestFn g_originalSelfTestTarget = nullptr;

__attribute__((noinline)) int TmlDobbySelfTestHook() {
    NSLog(@"[TML_HOOK] Self-Test-Hook aufgerufen (Original wuerde 42 liefern).");
    if (g_originalSelfTestTarget) {
        return g_originalSelfTestTarget();
    }
    return -1;
}

bool RunDobbySelfTest() {
    void* targetAddress = reinterpret_cast<void*>(&TmlDobbySelfTestTarget);
    NSLog(@"[TML_HOOK] Self-Test: eigene Zielfunktion bei %p, rufe DobbyHook() auf...", targetAddress);

    int result = DobbyHook(targetAddress, reinterpret_cast<void*>(&TmlDobbySelfTestHook),
                           reinterpret_cast<void**>(&g_originalSelfTestTarget));
    NSLog(@"[TML_HOOK] Self-Test: DobbyHook() Rueckgabewert: %d (%s)", result,
          result == 0 ? "Erfolg" : "Fehler");

    if (result != 0) {
        NSLog(@"[TML_HOOK] Self-Test FEHLGESCHLAGEN - Dobby hookt nicht einmal eigenen Code. "
               "Das deutet auf eine echte Plattform-Grenze hin (Codesigning/W^X), unabhaengig von "
               "Terraria - das Puppenspieler-Pattern waere so nicht umsetzbar.");
        return false;
    }

    int valueAfterHook = TmlDobbySelfTestTarget();
    NSLog(@"[TML_HOOK] Self-Test: Aufruf nach Hook-Installation liefert %d (Hook-Log sollte direkt "
           "davor erschienen sein).",
          valueAfterHook);

    DobbyDestroy(targetAddress);
    g_originalSelfTestTarget = nullptr;
    NSLog(@"[TML_HOOK] Self-Test ERFOLGREICH - Dobby hookt eigenen Code einwandfrei. Schlaegt der "
           "echte NPC.UpdateNPC-Hook trotzdem fehl, liegt es spezifisch an Terrarias "
           "codesignierten fremden Speicherseiten (Verdachtsmoment #1 bestaetigt).");
    return true;
}

// Der eigentliche Hook-Callback: loggt nur jeden 60. Aufruf, reicht danach
// unveraendert per Trampolin an die Original-UpdateNPC()-Implementierung
// weiter - kein Blocken, kein Manipulieren der Argumente.
void HookedNpcUpdate(void* npcThis, int32_t i, void* methodInfo) {
    ++g_callCount;
    if (g_callCount % 60 == 0) {
        NSLog(@"[TML_HOOK] NPC.UpdateNPC aufgerufen, npc-Pointer: %p, i=%d (Aufruf #%llu)", npcThis, i,
              (unsigned long long)g_callCount);
    }

    if (g_originalNpcUpdate) {
        g_originalNpcUpdate(npcThis, i, methodInfo);
    }
}

// --- Pointer-Swap-Test: KEIN Dobby. Ersetzt direkt MethodInfo::method
// (Offset 0 im Struct, reiner Datenspeicher, keine Codeseite) durch die
// Adresse dieser Funktion. Fuer den ersten Testlauf wird bewusst NICHT die
// Original-Methode aufgerufen - wir wollen nur sehen, ob der Aufruf
// ueberhaupt umgeleitet wird.
std::atomic<uint64_t> g_methodInfoSwapCallCount{0};

void TmlMethodPointerSwapReplacement(void* npcThis, int32_t i, void* methodInfo) {
    uint64_t count = ++g_methodInfoSwapCallCount;
    NSLog(@"[TML_HOOK] Pointer-Swap: Ersatzfunktion aufgerufen! npc-Pointer: %p, i=%d, methodInfo: %p "
           "(Aufruf #%llu)",
          npcThis, i, methodInfo, (unsigned long long)count);
}

} // namespace

void TML_EnableHookTest() {
    static bool installed = false;

    // Dobbys eigenes Diagnose-Logging so frueh wie moeglich auf syslog
    // umstellen (Level DEBUG = nichts wird gefiltert), damit auch der
    // Self-Test unten Dobbys interne Fehlermeldungen in Console.app zeigt
    // statt unsichtbar auf stdout zu verpuffen.
    logger_set_options(nullptr, "[Dobby]", nullptr, kTmlDobbyLogLevelDebug,
                       /*enable_time_tag=*/true, /*enable_syslog=*/true);
    NSLog(@"[TML_HOOK] Dobby-internes Logging auf syslog umgestellt (Tag [Dobby], Level DEBUG).");

    NSLog(@"[TML_HOOK] === Self-Test: hooke eigene Funktion (nicht Terraria) ===");
    RunDobbySelfTest();

    if (installed) {
        NSLog(@"[TML_HOOK] Echter NPC.UpdateNPC-Hook bereits installiert, ueberspringe Rest.");
        return;
    }

    const MethodInfo* updateMethod = ResolveNpcUpdateMethod();
    if (!updateMethod) {
        return;
    }

    // Keine il2cpp-API liefert die native Codeadresse einer MethodInfo* -
    // reference/il2cpp-api-functions.h (vollstaendig geprueft) hat dafuer
    // keine Funktion. Einzige bekannte Methode (auch von anderen IL2CPP-
    // Modding-Tools genutzt): MethodInfo::method ist das allererste Feld
    // (Offset 0, siehe reference/il2cpp.h Zeile 208-210 - dort zwar in
    // einem Kommentarblock, also nicht Teil der offiziell kompilierten API,
    // aber als Struct-Layout-Referenz verwendbar). Deshalb direkter
    // Offset-0-Read statt eines API-Aufrufs.
    NSLog(@"[TML_HOOK] Extrahiere native Funktionsadresse aus MethodInfo (Offset-0-Read)...");
    void* nativeUpdateAddress = *reinterpret_cast<void* const*>(updateMethod);
    NSLog(@"[TML_HOOK] Native Funktionsadresse extrahiert: %p", nativeUpdateAddress);

    NSLog(@"[TML_HOOK] Rufe DobbyHook(address=%p, fake_func=%p, out_origin_func=%p) auf...",
          nativeUpdateAddress, reinterpret_cast<void*>(&HookedNpcUpdate),
          reinterpret_cast<void*>(&g_originalNpcUpdate));
    int result = DobbyHook(nativeUpdateAddress, reinterpret_cast<void*>(&HookedNpcUpdate),
                           reinterpret_cast<void**>(&g_originalNpcUpdate));
    // Dobby-Konvention (verifiziert gegen den offiziellen Quellcode,
    // source/dobby.cpp, DobbyDestroy als direkte Referenz in derselben
    // Datei): 0 = Erfolg, -1 = Fehler.
    NSLog(@"[TML_HOOK] DobbyHook() Rueckgabewert: %d (%s), Original-Trampolin: %p", result,
          result == 0 ? "Erfolg" : "Fehler", reinterpret_cast<void*>(g_originalNpcUpdate));
    if (result != 0) {
        NSLog(@"[TML_HOOK] Abbruch: DobbyHook fehlgeschlagen (result=%d)", result);
        return;
    }

    installed = true;
    NSLog(@"[TML_HOOK] Hook auf NPC.UpdateNPC(int) erfolgreich installiert.");
}

void TML_EnableMethodPointerSwapTest() {
    static bool installed = false;
    if (installed) {
        NSLog(@"[TML_HOOK] Pointer-Swap bereits durchgefuehrt, ueberspringe.");
        return;
    }

    NSLog(@"[TML_HOOK] === Pointer-Swap-Test: MethodInfo::method direkt ueberschreiben (kein Dobby) ===");

    const MethodInfo* updateMethod = ResolveNpcUpdateMethod();
    if (!updateMethod) {
        return;
    }

    void** methodPointerSlot = reinterpret_cast<void**>(const_cast<MethodInfo*>(updateMethod));
    void* originalAddress = *methodPointerSlot;
    NSLog(@"[TML_HOOK] Pointer-Swap: MethodInfo bei %p, aktueller methodPointer (Original): %p",
          static_cast<const void*>(updateMethod), originalAddress);

    void* replacementAddress = reinterpret_cast<void*>(&TmlMethodPointerSwapReplacement);
    NSLog(@"[TML_HOOK] Pointer-Swap: schreibe neue Adresse %p in methodPointer-Slot...", replacementAddress);
    *methodPointerSlot = replacementAddress;

    // Sofort zurueckgelesen, VOR jedem tatsaechlichen NPC-Update-Aufruf -
    // isoliert "Schreibzugriff crasht/funktioniert" von "Schreibzugriff
    // klappt, wird aber vom echten Aufrufpfad nicht genutzt".
    void* readBack = *methodPointerSlot;
    bool writeConfirmed = (readBack == replacementAddress);
    NSLog(@"[TML_HOOK] Pointer-Swap: sofort zurueckgelesen: %p (%@)", readBack,
          writeConfirmed ? @"stimmt mit neuer Adresse ueberein" : @"WEICHT AB - unerwartet!");

    installed = true;
    NSLog(@"[TML_HOOK] Pointer-Swap abgeschlossen. Original-Adresse war %p, jetzt %p.",
          originalAddress, replacementAddress);
    NSLog(@"[TML_HOOK] Swap fertig, schliesse jetzt das Panel und beobachte NPCs in der Welt.");
}

uint64_t TML_GetMethodInfoSwapCallCount() {
    return g_methodInfoSwapCallCount.load();
}

int TML_IsUpdateNpcVirtual() {
    return g_updateNpcVirtual.load();
}
