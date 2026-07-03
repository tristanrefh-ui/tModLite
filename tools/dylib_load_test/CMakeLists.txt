# Baut dieselbe Bootstrap.cpp-Quelle wie src/platform/ios, aber nativ fuer
# den Host (macOS) statt fuer iOS. Dient nur zur lokalen Verifikation des
# __attribute__((constructor))-Mechanismus per dlopen(), ohne echtes Geraet.
# Kein Teil des iOS-Builds (scripts/build-ios.sh fasst das nicht an).

add_library(tml_bootstrap_host_test SHARED
    ${CMAKE_SOURCE_DIR}/src/platform/ios/Bootstrap.cpp
)
target_link_libraries(tml_bootstrap_host_test PRIVATE tml_core)

add_executable(dylib_load_test
    host_main.cpp
)
target_link_libraries(dylib_load_test PRIVATE ${CMAKE_DL_LIBS})
add_dependencies(dylib_load_test tml_bootstrap_host_test)
target_compile_definitions(dylib_load_test PRIVATE
    TML_BOOTSTRAP_HOST_TEST_LIB="$<TARGET_FILE:tml_bootstrap_host_test>"
)
