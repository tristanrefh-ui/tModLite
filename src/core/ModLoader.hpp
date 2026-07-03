#pragma once

#include <memory>
#include <vector>

#include "Mod.hpp"

namespace tml {

struct GameContext;

class ModLoader {
public:
    void registerMod(std::unique_ptr<Mod> mod);

    void loadAll(GameContext& context);
    void updateAll(GameContext& context);
    void unloadAll(GameContext& context);

private:
    std::vector<std::unique_ptr<Mod>> mods_;
};

} // namespace tml
