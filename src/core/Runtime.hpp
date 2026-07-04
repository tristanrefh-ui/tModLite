#pragma once

#include <memory>

#include "GameContext.hpp"
#include "ModLoader.hpp"

namespace tml {

class Runtime {
public:
    void start();
    void tick();
    void shutdown();

    void registerMod(std::unique_ptr<Mod> mod);

    GameContext& context();
    ModLoader& modLoader();

private:
    GameContext context_;
    ModLoader modLoader_;
    bool running_ = false;
};

} // namespace tml
