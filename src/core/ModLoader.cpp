#include "ModLoader.hpp"

#include <filesystem>
#include <fstream>

#include <nlohmann/json.hpp>

#include "GameContext.hpp"

namespace tml {

void ModLoader::registerMod(std::unique_ptr<Mod> mod) {
    Entry entry;
    entry.name = mod->name();
    entry.version = mod->version();
    entry.enabled = true;
    entry.mod = std::move(mod);
    mods_.push_back(std::move(entry));
}

std::size_t ModLoader::scanDirectory(const std::string& path) {
    namespace fs = std::filesystem;

    std::error_code dirError;
    if (!fs::is_directory(path, dirError) || dirError) {
        return 0;
    }

    std::size_t foundCount = 0;

    for (const auto& entry : fs::directory_iterator(path)) {
        if (!entry.is_directory()) {
            continue;
        }

        fs::path manifestPath = entry.path() / "manifest.json";
        std::ifstream manifestFile(manifestPath);
        if (!manifestFile.is_open()) {
            continue;
        }

        nlohmann::json manifest;
        try {
            manifestFile >> manifest;
        } catch (const nlohmann::json::parse_error&) {
            continue;
        }

        if (!manifest.contains("name") || !manifest["name"].is_string()) {
            continue;
        }

        Entry modEntry;
        modEntry.mod = nullptr;
        modEntry.name = manifest["name"].get<std::string>();
        modEntry.version = manifest.value("version", "0.0");
        modEntry.enabled = manifest.value("enabled", true);

        mods_.push_back(std::move(modEntry));
        ++foundCount;
    }

    return foundCount;
}

void ModLoader::loadAll(GameContext& context) {
    for (auto& entry : mods_) {
        if (entry.mod) {
            entry.mod->OnLoad(context);
        }
    }
}

void ModLoader::updateAll(GameContext& context) {
    for (auto& entry : mods_) {
        if (entry.enabled && entry.mod) {
            entry.mod->OnUpdate(context);
        }
    }
}

void ModLoader::unloadAll(GameContext& context) {
    for (auto& entry : mods_) {
        if (entry.mod) {
            entry.mod->OnUnload(context);
        }
    }
    mods_.clear();
}

std::size_t ModLoader::modCount() const {
    return mods_.size();
}

std::string ModLoader::modName(std::size_t index) const {
    return mods_[index].name;
}

std::string ModLoader::modVersion(std::size_t index) const {
    return mods_[index].version;
}

bool ModLoader::isModEnabled(std::size_t index) const {
    return mods_[index].enabled;
}

void ModLoader::setModEnabled(std::size_t index, bool enabled) {
    mods_[index].enabled = enabled;
}

bool ModLoader::toggleMod(const std::string& name) {
    for (auto& entry : mods_) {
        if (entry.name == name) {
            entry.enabled = !entry.enabled;
            return true;
        }
    }
    return false;
}

} // namespace tml
