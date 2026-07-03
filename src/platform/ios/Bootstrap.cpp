#include <cstdio>

#include "GameContext.hpp"
#include "Runtime.hpp"

__attribute__((constructor))
static void tml_ios_bootstrap() {
    static tml::Runtime runtime;

    tml::GameContext& context = runtime.context();
    context.player.name = "PlaceholderPlayer";
    context.world.name = "PlaceholderWorld";

    runtime.start();

    std::printf("[iOS Bootstrap] TModLite geladen und gestartet\n");
}
