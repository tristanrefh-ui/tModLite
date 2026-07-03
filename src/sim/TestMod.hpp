#pragma once

#include "Mod.hpp"

namespace tml::sim {

class TestMod : public Mod {
public:
    void OnLoad(GameContext& context) override;
    void OnUpdate(GameContext& context) override;
    void OnUnload(GameContext& context) override;

private:
    int tickCount_ = 0;
};

} // namespace tml::sim
