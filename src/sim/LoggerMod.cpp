#include "LoggerMod.hpp"

#include <cstdio>

#include "GameContext.hpp"

namespace tml::sim {

void LoggerMod::OnLoad(GameContext& context) {
    std::printf("[LoggerMod] OnLoad: Logger fuer Welt '%s' aktiv\n", context.world.name.c_str());
}

void LoggerMod::OnUpdate(GameContext& context) {
    ++tickCount_;
    if (tickCount_ % 10 == 0) {
        std::printf("[LoggerMod] Tick %d, Weltzeit %.2fs\n", tickCount_, context.world.time);
    }
}

void LoggerMod::OnUnload(GameContext& /*context*/) {
    std::printf("[LoggerMod] OnUnload: %d Ticks geloggt\n", tickCount_);
}

} // namespace tml::sim
