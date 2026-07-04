#pragma once

#include <cstddef>
#include <memory>
#include <string>
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

    std::size_t modCount() const;
    std::string modName(std::size_t index) const;
    std::string modVersion(std::size_t index) const;
    bool isModEnabled(std::size_t index) const;
    void setModEnabled(std::size_t index, bool enabled);

private:
    struct Entry {
        std::unique_ptr<Mod> mod;
        bool enabled = true;
    };

    std::vector<Entry> mods_;
};

} // namespace tml
