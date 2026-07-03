add_library(tml_ios_bootstrap SHARED
    Bootstrap.cpp
)

target_link_libraries(tml_ios_bootstrap PRIVATE tml_core)
