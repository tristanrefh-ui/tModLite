#include "ModLoader.hpp"

#include "GameContext.hpp"

namespace tml {

void ModLoader::registerMod(std::unique_ptr<Mod> mod) {
    mods_.push_back(std::move(mod));
}

void ModLoader::loadAll(GameContext& context) {
    for (auto& mod : mods_) {
        mod->OnLoad(context);
    }
}

void ModLoader::updateAll(GameContext& context) {
    for (auto& mod : mods_) {
        mod->OnUpdate(context);
    }
}

void ModLoader::unloadAll(GameContext& context) {
    for (auto& mod : mods_) {
        mod->OnUnload(context);
    }
    mods_.clear();
}

} // namespace tml
