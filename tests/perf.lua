#!/usr/bin/env lua5.2

effil = require "effil"

math.randomseed(15123)

local tables = {}
local iter = 0
local total_iter = 2000

while iter < total_iter do
    for i = 1, 100 do
        local t = effil.table( { lifetime = math.random() * (total_iter - iter) / 2 })
        table.insert(tables, t)
    end

    local removed = 0
    for i, t in ipairs(tables) do
        t.lifetime = t.lifetime - 1
        if t.lifetime <= 0 then
            removed = removed + 1
            table.remove(tables, i)
        end
    end
    collectgarbage()
    iter = iter + 1

    print("Iteration: " .. iter)
    print("Removed: " .. removed)
end

