#pragma once

#include <sol.hpp>
#include "lua-helpers.h"

namespace effil {

// Lua this thread API
std::string threadId();
void yield();
void sleep(const sol::optional<int>&, const sol::optional<std::string>&);

class ThreadHandle;

class Thread {
public:
    Thread(const std::string& path,
           const std::string& cpath,
           int step,
           const sol::function& function,
           const sol::variadic_args& args);

    static void getUserType(sol::state_view& lua);

    std::pair<sol::object, sol::object> status(const sol::this_state& state);
    std::pair<sol::object, sol::object> wait(const sol::this_state& state,
                                             const sol::optional<int>& duration,
                                             const sol::optional<std::string>& period);
    StoredArray get(const sol::optional<int>& duration,
                   const sol::optional<std::string>& period);
    bool cancel(const sol::this_state& state,
                const sol::optional<int>& duration,
                const sol::optional<std::string>& period);
    bool pause(const sol::this_state&,
               const sol::optional<int>& duration,
               const sol::optional<std::string>& period);
    void resume();

private:
    std::shared_ptr<ThreadHandle> handle_;

private:
    Thread(const Thread&) = delete;
    Thread& operator=(const Thread&) = delete;
};

} // effil
