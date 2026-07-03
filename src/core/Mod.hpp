#pragma once

namespace tml {

struct GameContext;

class Mod {
public:
    virtual ~Mod() = default;

    virtual void OnLoad(GameContext& context) = 0;
    virtual void OnUpdate(GameContext& context) = 0;
    virtual void OnUnload(GameContext& context) = 0;
};

} // namespace tml
