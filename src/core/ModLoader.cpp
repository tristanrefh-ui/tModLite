#include "ModLoader.hpp"

#include "GameContext.hpp"

namespace tml {

void ModLoader::registerMod(std::unique_ptr<Mod> mod) {
    mods_.push_back(Entry{std::move(mod), true});
}

void ModLoader::loadAll(GameContext& context) {
    for (auto& entry : mods_) {
        entry.mod->OnLoad(context);
    }
}

void ModLoader::updateAll(GameContext& context) {
    for (auto& entry : mods_) {
        if (entry.enabled) {
            entry.mod->OnUpdate(context);
        }
    }
}

void ModLoader::unloadAll(GameContext& context) {
    for (auto& entry : mods_) {
        entry.mod->OnUnload(context);
    }
    mods_.clear();
}

std::size_t ModLoader::modCount() const {
    return mods_.size();
}

std::string ModLoader::modName(std::size_t index) const {
    return mods_[index].mod->name();
}

std::string ModLoader::modVersion(std::size_t index) const {
    return mods_[index].mod->version();
}

bool ModLoader::isModEnabled(std::size_t index) const {
    return mods_[index].enabled;
}

void ModLoader::setModEnabled(std::size_t index, bool enabled) {
    mods_[index].enabled = enabled;
}

} // namespace tml
