add_library(tml_core STATIC
    Runtime.cpp
    EventBus.cpp
    ModLoader.cpp
)

target_include_directories(tml_core PUBLIC
    ${CMAKE_CURRENT_SOURCE_DIR}
)

target_compile_features(tml_core PUBLIC cxx_std_17)
