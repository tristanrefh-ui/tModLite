#pragma once

#include <functional>
#include <string>
#include <unordered_map>
#include <vector>

namespace tml {

struct Event {
    std::string name;
};

class EventBus {
public:
    using Handler = std::function<void(const Event&)>;

    // "register" ist ein reserviertes C++-Schluesselwort, daher registerHandler().
    void registerHandler(const std::string& eventName, Handler handler);
    void emit(const Event& event);

private:
    std::unordered_map<std::string, std::vector<Handler>> handlers_;
};

} // namespace tml
