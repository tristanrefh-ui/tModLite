#pragma once

#include <cstdint>
#include <string>
#include <vector>

namespace tml {

struct Player {
    std::string name;
    float health = 100.0f;
    float maxHealth = 100.0f;
    float positionX = 0.0f;
    float positionY = 0.0f;
};

struct Entity {
    uint32_t id = 0;
    std::string type;
    int x = 0;
    int y = 0;
};

struct World {
    std::string name;
    float time = 0.0f;
    int gridWidth = 40;
    int gridHeight = 20;
    std::vector<Entity> entities;
};

struct GameContext {
    Player player;
    World world;
};

} // namespace tml
