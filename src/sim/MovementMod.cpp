#include "MovementMod.hpp"

#include <algorithm>
#include <cstdio>

#include "GameContext.hpp"

namespace tml::sim {

void MovementMod::OnLoad(GameContext& context) {
    std::printf("[MovementMod] OnLoad: bewege %zu Entities auf %dx%d Grid\n",
                context.world.entities.size(), context.world.gridWidth, context.world.gridHeight);
}

void MovementMod::OnUpdate(GameContext& context) {
    std::uniform_int_distribution<int> dirDist(0, 3);

    for (Entity& entity : context.world.entities) {
        int dx = 0;
        int dy = 0;
        switch (dirDist(rng_)) {
            case 0: dy = -1; break;
            case 1: dy = 1; break;
            case 2: dx = -1; break;
            default: dx = 1; break;
        }
        entity.x = std::clamp(entity.x + dx, 0, context.world.gridWidth - 1);
        entity.y = std::clamp(entity.y + dy, 0, context.world.gridHeight - 1);
    }
}

void MovementMod::OnUnload(GameContext& /*context*/) {
    std::printf("[MovementMod] OnUnload\n");
}

} // namespace tml::sim
