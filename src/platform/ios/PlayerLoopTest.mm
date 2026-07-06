#import "PlayerLoopTest.h"

#import <Foundation/Foundation.h>

#include <cstring>
#include <dlfcn.h>
#include <mach-o/dyld.h>

namespace {

// il2cpp_resolve_icall(name) schlaegt in einer nativen Engine-Tabelle nach,
// die Internal-Call-Namen ("Namespace.Klasse::Methode") auf native
// Funktionszeiger abbildet - komplett unabhaengig vom C#-Metadatenbestand
// (global-metadata.dat), der von Managed-Code-Stripping betroffen ist.
// Signatur gegen reference/il2cpp-api-functions.h Zeile 19 verifiziert:
// DO_API(Il2CppMethodPointer, il2cpp_resolve_icall, (const char* name));
// Il2CppMethodPointer ist ein generischer Funktionszeiger-Typedef, hier
// als void* behandelt - wir rufen nichts auf, nur Adresse loggen.
using Il2CppResolveIcallFn = void* (*)(const char* name);

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
    NSLog(@"[TML_PLAYERLOOP] dlsym(%s) -> %s", name, symbol ? "OK" : "NULL");
    outFn = reinterpret_cast<FnPtr>(symbol);
    return symbol != nullptr;
}

void LogIcallLookup(Il2CppResolveIcallFn resolveIcall, const char* icallName) {
    void* ptr = resolveIcall(icallName);
    NSLog(@"[TML_PLAYERLOOP] il2cpp_resolve_icall(\"%s\") -> %p (%s)", icallName, ptr,
          ptr ? "GEFUNDEN" : "null");
}

} // namespace

void TML_LogCurrentPlayerLoop() {
    NSLog(@"[TML_PLAYERLOOP] === Schritt A v2: PlayerLoop-ICalls direkt aufloesen (kein Aufruf) ===");

    void* handle = OpenUnityFrameworkHandle();
    if (!handle) {
        NSLog(@"[TML_PLAYERLOOP] Abbruch: UnityFramework-Handle nicht gefunden.");
        return;
    }
    NSLog(@"[TML_PLAYERLOOP] UnityFramework-Handle: %p", handle);

    Il2CppResolveIcallFn resolve_icall = nullptr;
    if (!ResolveSymbol(handle, "il2cpp_resolve_icall", resolve_icall)) {
        NSLog(@"[TML_PLAYERLOOP] Abbruch: il2cpp_resolve_icall nicht aufloesbar.");
        return;
    }

    LogIcallLookup(resolve_icall, "UnityEngine.LowLevel.PlayerLoop::GetCurrentPlayerLoop");
    LogIcallLookup(resolve_icall, "UnityEngine.LowLevel.PlayerLoop::GetCurrentPlayerLoop_Injected");
    LogIcallLookup(resolve_icall, "UnityEngine.LowLevel.PlayerLoop::SetPlayerLoop");
    LogIcallLookup(resolve_icall, "UnityEngine.LowLevel.PlayerLoop::SetPlayerLoop_Injected");

    NSLog(@"[TML_PLAYERLOOP] ICall-Lookup abgeschlossen - keiner der Pointer wurde aufgerufen.");
}
