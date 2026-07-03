#include "Runtime.hpp"

namespace tml {

void Runtime::registerMod(std::unique_ptr<Mod> mod) {
    modLoader_.registerMod(std::move(mod));
}

void Runtime::start() {
    running_ = true;
    modLoader_.loadAll(context_);
}

void Runtime::tick() {
    if (!running_) {
        return;
    }
    modLoader_.updateAll(context_);
}

void Runtime::shutdown() {
    modLoader_.unloadAll(context_);
    running_ = false;
}

GameContext& Runtime::context() {
    return context_;
}

} // namespace tml
