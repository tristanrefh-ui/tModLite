add_executable(tml_sim
    main.cpp
    TestMod.cpp
    LoggerMod.cpp
    MovementMod.cpp
)

target_link_libraries(tml_sim PRIVATE tml_core)
