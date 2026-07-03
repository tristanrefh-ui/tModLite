#include <chrono>
#include <cstdio>
#include <memory>
#include <thread>

#include "EventBus.hpp"
#include "LoggerMod.hpp"
#include "Runtime.hpp"
#include "TestMod.hpp"

using namespace std::chrono;

int main() {
    tml::EventBus eventBus;
    eventBus.registerHandler("world.loaded", [](const tml::Event& event) {
        std::printf("[EventBus] Event empfangen: %s\n", event.name.c_str());
    });
    eventBus.emit(tml::Event{"world.loaded"});

    tml::Runtime runtime;
    runtime.registerMod(std::make_unique<tml::sim::TestMod>());
    runtime.registerMod(std::make_unique<tml::sim::LoggerMod>());

    runtime.start();

    constexpr duration<double> frameDuration{1.0 / 60.0};
    constexpr int totalFrames = 300; // 5 Sekunden bei 60 FPS

    for (int frame = 0; frame < totalFrames; ++frame) {
        const auto frameStart = steady_clock::now();

        runtime.tick();

        const auto elapsed = duration_cast<duration<double>>(steady_clock::now() - frameStart);
        const auto sleepTime = frameDuration - elapsed;
        if (sleepTime > duration<double>::zero()) {
            std::this_thread::sleep_for(sleepTime);
        }
    }

    runtime.shutdown();

    return 0;
}
