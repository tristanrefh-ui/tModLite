#include "EventBus.hpp"

namespace tml {

void EventBus::registerHandler(const std::string& eventName, Handler handler) {
    handlers_[eventName].push_back(std::move(handler));
}

void EventBus::emit(const Event& event) {
    auto it = handlers_.find(event.name);
    if (it == handlers_.end()) {
        return;
    }
    for (const auto& handler : it->second) {
        handler(event);
    }
}

} // namespace tml
