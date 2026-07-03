#include "TestMod.hpp"

#include <cstdio>

#include "GameContext.hpp"

namespace tml::sim {

void TestMod::OnLoad(GameContext& context) {
    context.player.name = "TestPlayer";
    context.world.name = "TestWorld";
    std::printf("[TestMod] OnLoad: Welt '%s' fuer Spieler '%s' vorbereitet\n",
                context.world.name.c_str(), context.player.name.c_str());
}

void TestMod::OnUpdate(GameContext& context) {
    ++tickCount_;
    context.world.time += 1.0f / 60.0f;

    if (tickCount_ % 60 == 0) {
        std::printf("[TestMod] OnUpdate: Tick %d, Weltzeit %.2fs\n", tickCount_, context.world.time);
    }
}

void TestMod::OnUnload(GameContext& context) {
    std::printf("[TestMod] OnUnload: %d Ticks insgesamt fuer Welt '%s'\n", tickCount_, context.world.name.c_str());
}

} // namespace tml::sim
