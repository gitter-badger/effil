#include "garbage-collector.h"

#include "utils.h"

#include <vector>
#include <cassert>

namespace effil {

GC::GC()
        : enabled_(true)
        , lastCleanup_(0)
        , step_(1000)
        , objects_(1)
        , generation_(0) {}

std::shared_ptr<GCObject> GC::findObject(GCObjectHandle handle) const {
    for (const auto& iter: objects_)
    {
        auto it = iter.find(handle);
        if (it != iter.end()) {
            return it->second;
        }
    }
    return nullptr;
}

bool GC::has(GCObjectHandle handle) const {
    std::lock_guard<std::mutex> g(lock_);
    return findObject(handle).get() != nullptr;
}

size_t logn(double base, double x) {
    return (size_t)(log(x) / log(base));
}

// Here is the naive tri-color marking
// garbage collecting algorithm implementation.
void GC::collect() {
    std::lock_guard<std::mutex> g(lock_);

    size_t removed = 0;
    size_t genNum = 0;
    for (auto gen = objects_.begin(); genNum <= logn(2, generation_ + 1); ++gen, ++genNum)
    {
        std::vector<GCObjectHandle> grey;
        std::map<GCObjectHandle, std::shared_ptr<GCObject>> black;

        for (const auto& handleAndObject : *gen)
            if (handleAndObject.second->instances() > 1)
                grey.push_back(handleAndObject.first);

        while (!grey.empty()) {
            GCObjectHandle handle = grey.back();
            grey.pop_back();

            auto object = findObject(handle);
            black[handle] = object;
            for (GCObjectHandle refHandle : object->refers())
                if (black.find(refHandle) == black.end())
                    grey.push_back(refHandle);
        }

        removed += gen->size() - black.size();
        *gen = std::move(black);
    }
    std::cout << "Remove: " << removed << std::endl;

    lastCleanup_.store(0);
    objects_.push_front(std::map<GCObjectHandle, std::shared_ptr<GCObject>>());
    if (objects_.size() > 4)
    {
        (----objects_.end())->insert(objects_.back().begin(), objects_.back().end());
        objects_.pop_back();
    }
    generation_++;
    if (logn(2, generation_ + 1) >= objects_.size())
        generation_ = 0;
    for (const auto& iter: objects_)
    {
        std::cout << "Gen: " << iter.size() << ", ";
    }
    std::cout << std::endl;
}

size_t GC::size() const {
    std::lock_guard<std::mutex> g(lock_);
    return objects_.size();
}

size_t GC::count() {
    std::lock_guard<std::mutex> g(lock_);
    return objects_.size();
}

GC& GC::instance() {
    static GC pool;
    return pool;
}

sol::table GC::getLuaApi(sol::state_view& lua) {
    sol::table api = lua.create_table_with();
    api["collect"] = [=] {
        instance().collect();
    };
    api["pause"] = [] { instance().pause(); };
    api["resume"] = [] { instance().resume(); };
    api["enabled"] = [] { return instance().enabled(); };
    api["step"] = [](sol::optional<int> newStep){
        auto previous = instance().step();
        if (newStep) {
            REQUIRE(*newStep <= 0) << "gc.step have to be > 0";
            instance().step(static_cast<size_t>(*newStep));
        }
        return previous;
    };
    api["count"] = [] {
        return instance().count();
    };
    return api;
}

} // effil
