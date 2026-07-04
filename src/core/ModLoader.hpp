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

    // Scannt alle Unterordner von path nach manifest.json ({"name",
    // "version", "enabled"}) und registriert sie als reine Metadaten-
    // Eintraege (kein Mod-Objekt, keine echte Code-Ausfuehrung - das ist
    // die naechste Ausbaustufe, siehe docs/modloader.md). Gibt die Anzahl
    // neu gefundener Mods zurueck.
    std::size_t scanDirectory(const std::string& path);

    void loadAll(GameContext& context);
    void updateAll(GameContext& context);
    void unloadAll(GameContext& context);

    std::size_t modCount() const;
    std::string modName(std::size_t index) const;
    std::string modVersion(std::size_t index) const;
    bool isModEnabled(std::size_t index) const;
    void setModEnabled(std::size_t index, bool enabled);

    // Kippt den enabled-Status anhand des Namens (z.B. von der UI aus, die
    // Mods namentlich statt per Index kennt). Gibt false zurueck, falls
    // kein Mod mit diesem Namen existiert.
    bool toggleMod(const std::string& name);

private:
    struct Entry {
        std::unique_ptr<Mod> mod; // nullptr fuer reine Scan-Metadaten
        std::string name;
        std::string version;
        bool enabled = true;
    };

    std::vector<Entry> mods_;
};

} // namespace tml
