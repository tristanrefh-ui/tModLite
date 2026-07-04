#import "Il2CppBridge.h"

#import <Foundation/Foundation.h>

#include <cstring>
#include <dlfcn.h>
#include <mach-o/dyld.h>

namespace {

// --- Minimale, von Hand nachgebildete IL2CPP-C-API-Deklarationen ---
//
// Wir linken NICHT gegen libil2cpp/UnityFramework zur Compile-Zeit (das ist
// ein Terraria-Build-Artefakt, das wir weder besitzen noch einbetten). Alle
// Funktionspointer werden zur Laufzeit per dlsym aus der bereits im Prozess
// geladenen UnityFramework aufgeloest.
//
// Alle Signaturen hier sind gegen reference/il2cpp-api-functions.h
// (die echte DO_API-Deklarationsdatei) abgeglichen - keine Abweichungen.
extern "C" {
typedef struct Il2CppDomain Il2CppDomain;
typedef struct Il2CppThread Il2CppThread;
typedef struct Il2CppAssembly Il2CppAssembly;
typedef struct Il2CppImage Il2CppImage;
typedef struct Il2CppClass Il2CppClass;
typedef struct Il2CppObject Il2CppObject;
typedef struct Il2CppException Il2CppException;
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
using Il2CppRuntimeInvokeFn = Il2CppObject* (*)(const MethodInfo*, void*, void**, Il2CppException**);
using Il2CppFormatExceptionFn = void (*)(const Il2CppException*, char*, int);
using Il2CppObjectUnboxFn = void* (*)(Il2CppObject*);

struct Il2CppApi {
    Il2CppDomainGetFn domain_get = nullptr;
    Il2CppThreadAttachFn thread_attach = nullptr;
    Il2CppDomainGetAssembliesFn domain_get_assemblies = nullptr;
    Il2CppAssemblyGetImageFn assembly_get_image = nullptr;
    Il2CppImageGetNameFn image_get_name = nullptr;
    Il2CppClassFromNameFn class_from_name = nullptr;
    Il2CppClassGetMethodFromNameFn class_get_method_from_name = nullptr;
    Il2CppRuntimeClassInitFn runtime_class_init = nullptr;
    Il2CppRuntimeInvokeFn runtime_invoke = nullptr;
    Il2CppFormatExceptionFn format_exception = nullptr;
    Il2CppObjectUnboxFn object_unbox = nullptr;
};

template <typename FnPtr>
bool ResolveSymbol(void* handle, const char* name, FnPtr& outFn) {
    void* symbol = dlsym(handle, name);
    NSLog(@"[Il2CppBridge] dlsym(%s) -> %s", name, symbol ? "OK" : "NULL");
    outFn = reinterpret_cast<FnPtr>(symbol);
    return symbol != nullptr;
}

// dlopen(RTLD_NOLOAD) mit dem blossen Framework-Namen matcht auf Darwin
// ueblicherweise bereits geladene Images ueber deren Pfad-Suffix. Falls
// nicht, suchen wir explizit ueber die dyld-Image-Liste nach dem echten
// geladenen Pfad - das ist Standard-Darwin-API, keine IL2CPP-Unsicherheit.
void* OpenUnityFrameworkHandle() {
    void* handle = dlopen("UnityFramework", RTLD_NOLOAD);
    if (handle) {
        NSLog(@"[Il2CppBridge] dlopen(UnityFramework, RTLD_NOLOAD) -> OK (%p)", handle);
        return handle;
    }

    NSLog(@"[Il2CppBridge] dlopen(UnityFramework, RTLD_NOLOAD) -> NULL, "
           "durchsuche geladene dyld-Images...");

    uint32_t imageCount = _dyld_image_count();
    for (uint32_t i = 0; i < imageCount; ++i) {
        const char* imageName = _dyld_get_image_name(i);
        if (imageName && std::strstr(imageName, "UnityFramework")) {
            NSLog(@"[Il2CppBridge] dyld-Image gefunden: %s", imageName);
            handle = dlopen(imageName, RTLD_NOLOAD);
            if (handle) {
                NSLog(@"[Il2CppBridge] dlopen(%s, RTLD_NOLOAD) -> OK (%p)", imageName, handle);
                return handle;
            }
        }
    }

    NSLog(@"[Il2CppBridge] Kein geladenes Image mit 'UnityFramework' im Pfad gefunden - "
           "Bibliotheksname evtl. anders benannt.");
    return nullptr;
}

bool LoadIl2CppApi(Il2CppApi& api) {
    void* handle = OpenUnityFrameworkHandle();
    if (!handle) {
        return false;
    }

    bool ok = true;
    ok &= ResolveSymbol(handle, "il2cpp_domain_get", api.domain_get);
    ok &= ResolveSymbol(handle, "il2cpp_thread_attach", api.thread_attach);
    ok &= ResolveSymbol(handle, "il2cpp_domain_get_assemblies", api.domain_get_assemblies);
    ok &= ResolveSymbol(handle, "il2cpp_assembly_get_image", api.assembly_get_image);
    ok &= ResolveSymbol(handle, "il2cpp_image_get_name", api.image_get_name);
    ok &= ResolveSymbol(handle, "il2cpp_class_from_name", api.class_from_name);
    ok &= ResolveSymbol(handle, "il2cpp_class_get_method_from_name", api.class_get_method_from_name);
    ok &= ResolveSymbol(handle, "il2cpp_runtime_class_init", api.runtime_class_init);
    ok &= ResolveSymbol(handle, "il2cpp_runtime_invoke", api.runtime_invoke);
    ok &= ResolveSymbol(handle, "il2cpp_object_unbox", api.object_unbox);
    // Nur fuer lesbarere Fehlermeldungen - kein harter Abbruch falls das fehlt.
    ResolveSymbol(handle, "il2cpp_format_exception", api.format_exception);

    return ok;
}

const Il2CppImage* FindImageContainingClass(const Il2CppApi& api, const Il2CppDomain* domain,
                                             const char* namespaze, const char* className,
                                             Il2CppClass** outClass) {
    size_t assemblyCount = 0;
    const Il2CppAssembly** assemblies = api.domain_get_assemblies(domain, &assemblyCount);
    NSLog(@"[Il2CppBridge] domain_get_assemblies -> %p, count=%zu",
          static_cast<const void*>(assemblies), assemblyCount);

    if (!assemblies || assemblyCount == 0) {
        return nullptr;
    }

    for (size_t i = 0; i < assemblyCount; ++i) {
        const Il2CppImage* image = api.assembly_get_image(assemblies[i]);
        if (!image) {
            continue;
        }
        const char* imageName = api.image_get_name(image);
        Il2CppClass* klass = api.class_from_name(image, namespaze, className);
        NSLog(@"[Il2CppBridge]   Image[%zu]=%s -> class_from_name(%s.%s) = %s", i,
              imageName ? imageName : "?", namespaze, className, klass ? "OK" : "null");
        if (klass) {
            *outClass = klass;
            return image;
        }
    }
    return nullptr;
}

void LogException(const Il2CppApi& api, const Il2CppException* exception, const char* context) {
    if (api.format_exception && exception) {
        char buffer[512];
        api.format_exception(exception, buffer, sizeof(buffer));
        NSLog(@"[Il2CppBridge] Exception bei %s: %s", context, buffer);
    } else {
        NSLog(@"[Il2CppBridge] Exception bei %s (keine Details, format_exception fehlt oder null)", context);
    }
}

// Einmalig aufgeloest und ueber die Lebensdauer des Prozesses zwischen-
// gespeichert - menuMode wird jetzt bei jedem Panel-Oeffnen/Schliessen
// gesetzt, nicht nur einmalig, dlopen/dlsym/Class-Lookup soll sich also
// nicht bei jedem Tap wiederholen.
struct CachedBridge {
    Il2CppApi api;
    Il2CppDomain* domain = nullptr;
    Il2CppClass* mainClass = nullptr;
    const MethodInfo* getMenuModeMethod = nullptr;
    const MethodInfo* setMenuModeMethod = nullptr;
    bool attempted = false;
    bool ready = false;
};

CachedBridge& GetCachedBridge() {
    static CachedBridge cached;
    if (cached.attempted) {
        return cached;
    }
    cached.attempted = true;

    if (!LoadIl2CppApi(cached.api)) {
        NSLog(@"[Il2CppBridge] Abbruch: nicht alle Pflicht-Symbole aufloesbar.");
        return cached;
    }

    cached.domain = cached.api.domain_get();
    NSLog(@"[Il2CppBridge] domain_get -> %s", cached.domain ? "OK" : "NULL");
    if (!cached.domain) {
        return cached;
    }

    cached.api.thread_attach(cached.domain);

    Il2CppClass* mainClass = nullptr;
    const Il2CppImage* mainImage =
        FindImageContainingClass(cached.api, cached.domain, "Terraria", "Main", &mainClass);
    if (!mainImage || !mainClass) {
        NSLog(@"[Il2CppBridge] Abbruch: Terraria.Main nicht gefunden.");
        return cached;
    }
    NSLog(@"[Il2CppBridge] Terraria.Main gefunden.");
    cached.mainClass = mainClass;

    cached.api.runtime_class_init(mainClass);

    // menuMode ist eine C#-Property (public static int menuMode { get; set; }
    // auf Terraria.Main, kein Feld) - aufgeloest ueber die generierten
    // statischen Zugriffsmethoden.
    cached.getMenuModeMethod = cached.api.class_get_method_from_name(mainClass, "get_menuMode", 0);
    cached.setMenuModeMethod = cached.api.class_get_method_from_name(mainClass, "set_menuMode", 1);
    NSLog(@"[Il2CppBridge] get_menuMode -> %s, set_menuMode -> %s",
          cached.getMenuModeMethod ? "OK" : "NULL", cached.setMenuModeMethod ? "OK" : "NULL");

    cached.ready = (cached.getMenuModeMethod != nullptr && cached.setMenuModeMethod != nullptr);
    return cached;
}

} // namespace

void TML_SetMenuMode(int value) {
    CachedBridge& bridge = GetCachedBridge();
    if (!bridge.ready) {
        NSLog(@"[Il2CppBridge] Abbruch: Bridge nicht einsatzbereit (siehe vorherige Logs).");
        return;
    }

    // Der int-Rueckgabewert von get_menuMode() kommt von il2cpp_runtime_invoke
    // geboxt zurueck (Il2CppObject*), daher il2cpp_object_unbox zum Auslesen
    // des rohen Werts.
    Il2CppException* exception = nullptr;
    Il2CppObject* oldBoxed =
        bridge.api.runtime_invoke(bridge.getMenuModeMethod, nullptr, nullptr, &exception);
    int oldMenuMode = 0;
    if (exception) {
        LogException(bridge.api, exception, "get_menuMode (vorher)");
    } else if (oldBoxed) {
        oldMenuMode = *static_cast<int*>(bridge.api.object_unbox(oldBoxed));
    }

    void* args[1] = {&value};
    exception = nullptr;
    bridge.api.runtime_invoke(bridge.setMenuModeMethod, nullptr, args, &exception);
    if (exception) {
        LogException(bridge.api, exception, "set_menuMode");
        return;
    }

    exception = nullptr;
    Il2CppObject* verifyBoxed =
        bridge.api.runtime_invoke(bridge.getMenuModeMethod, nullptr, nullptr, &exception);
    int verifyMenuMode = 0;
    if (exception) {
        LogException(bridge.api, exception, "get_menuMode (nachher)");
    } else if (verifyBoxed) {
        verifyMenuMode = *static_cast<int*>(bridge.api.object_unbox(verifyBoxed));
    }

    NSLog(@"[Il2CppBridge] Main.menuMode: alt=%d, gesetzt=%d, verifiziert=%d", oldMenuMode, value,
          verifyMenuMode);
}
