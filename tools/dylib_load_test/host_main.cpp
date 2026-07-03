#include <cstdio>

#include <dlfcn.h>

int main() {
    std::printf("[dylib_load_test] Lade %s via dlopen()...\n", TML_BOOTSTRAP_HOST_TEST_LIB);

    void* handle = dlopen(TML_BOOTSTRAP_HOST_TEST_LIB, RTLD_NOW);
    if (!handle) {
        std::fprintf(stderr, "[dylib_load_test] dlopen fehlgeschlagen: %s\n", dlerror());
        return 1;
    }

    std::printf("[dylib_load_test] dlopen erfolgreich - der Constructor-Log oben sollte bereits geschrieben sein.\n");

    dlclose(handle);
    std::printf("[dylib_load_test] dlclose aufgerufen.\n");

    return 0;
}
