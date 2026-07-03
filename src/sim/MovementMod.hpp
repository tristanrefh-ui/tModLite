#pragma once

#include <random>

#include "Mod.hpp"

namespace tml::sim {

class MovementMod : public Mod {
public:
    void OnLoad(GameContext& context) override;
    void OnUpdate(GameContext& context) override;
    void OnUnload(GameContext& context) override;

private:
    std::mt19937 rng_{std::random_device{}()};
};

} // namespace tml::sim
