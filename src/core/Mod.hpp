#pragma once

#include <string>

namespace tml {

struct GameContext;

class Mod {
public:
    virtual ~Mod() = default;

    virtual void OnLoad(GameContext& context) = 0;
    virtual void OnUpdate(GameContext& context) = 0;
    virtual void OnUnload(GameContext& context) = 0;

    virtual std::string name() const { return "Unnamed Mod"; }
    virtual std::string version() const { return "0.0"; }
};

} // namespace tml
