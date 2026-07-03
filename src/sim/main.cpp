#include <chrono>
#include <cstdio>
#include <memory>
#include <random>
#include <string>
#include <thread>
#include <vector>

#include "GameContext.hpp"
#include "MovementMod.hpp"
#include "Runtime.hpp"

using namespace std::chrono;

namespace {

void spawnEntities(tml::GameContext& context, int count) {
    std::mt19937 rng{std::random_device{}()};
    std::uniform_int_distribution<int> xDist(0, context.world.gridWidth - 1);
    std::uniform_int_distribution<int> yDist(0, context.world.gridHeight - 1);

    for (int i = 0; i < count; ++i) {
        tml::Entity entity;
        entity.id = static_cast<uint32_t>(i);
        entity.type = "TestEntity";
        entity.x = xDist(rng);
        entity.y = yDist(rng);
        context.world.entities.push_back(entity);
    }
}

void renderFrame(const tml::GameContext& context, int tick) {
    const tml::World& world = context.world;

    std::vector<std::string> rows(static_cast<size_t>(world.gridHeight),
                                   std::string(static_cast<size_t>(world.gridWidth), '.'));
    for (const tml::Entity& entity : world.entities) {
        if (entity.x < 0 || entity.x >= world.gridWidth || entity.y < 0 || entity.y >= world.gridHeight) {
            continue;
        }
        rows[static_cast<size_t>(entity.y)][static_cast<size_t>(entity.x)] =
            static_cast<char>('A' + (entity.id % 26));
    }

    std::string frame = "\033[2J\033[H";
    frame += "tModLite Sim | Tick " + std::to_string(tick) +
             " | Entities: " + std::to_string(world.entities.size()) +
             " | Mods: MovementMod\n\n";
    for (const auto& row : rows) {
        frame += row;
        frame += '\n';
    }

    std::fwrite(frame.data(), 1, frame.size(), stdout);
    std::fflush(stdout);
}

} // namespace

int main() {
    tml::Runtime runtime;
    runtime.registerMod(std::make_unique<tml::sim::MovementMod>());

    tml::GameContext& context = runtime.context();
    context.world.name = "TestWorld";
    spawnEntities(context, 6);

    runtime.start();

    constexpr duration<double> frameDuration{1.0 / 60.0};
    constexpr int totalFrames = 600; // 10 Sekunden bei 60 FPS

    for (int frame = 1; frame <= totalFrames; ++frame) {
        const auto frameStart = steady_clock::now();

        runtime.tick();
        renderFrame(context, frame);

        const auto elapsed = duration_cast<duration<double>>(steady_clock::now() - frameStart);
        const auto sleepTime = frameDuration - elapsed;
        if (sleepTime > duration<double>::zero()) {
            std::this_thread::sleep_for(sleepTime);
        }
    }

    runtime.shutdown();

    return 0;
}
