require "bootstrap-tests"

test.metatable.tear_down = function (metatable)
    collectgarbage()
    effil.gc.collect()

    -- if metatable is shared_table - it counts as gr object
    -- and it will be destroyed after tear_down
    if type(metatable) == "table" then
        test.equal(effil.gc.count(), 1)
    else
        test.equal(effil.gc.count(), 2)
    end
end

local function run_test_with_different_metatables(name, ...)
    test.metatable[name]({}, ...)
    test.metatable[name](effil.table(), ...)
end

test.metatable.index = function (metatable)
    local share = effil.table()
    metatable.__index = function(t, key)
        return "mt_" .. effil.rawget(t, key)
    end
    effil.setmetatable(share, metatable)

    share.table_key = "table_value"
    test.equal(share.table_key, "mt_table_value")
end

test.metatable.new_index = function (metatable)
    local share = effil.table()
    metatable.__newindex = function(t, key, value)
        effil.rawset(t, "mt_" .. key, "mt_" .. value)
    end
    effil.setmetatable(share, metatable)

    share.table_key = "table_value"
    test.equal(share.mt_table_key, "mt_table_value")
end

test.metatable.call = function (metatable)
    local share = effil.table()
    metatable.__call = function(t, val1, val2, val3)
        return tostring(val1) .. "_" .. tostring(val2), tostring(val2) .. "_" .. tostring(val3)
    end
    effil.setmetatable(share, metatable)

    local first_ret, second_ret = share("val1", "val2", "val3")
    test.equal(first_ret, "val1_val2")
    test.equal(second_ret, "val2_val3")
end

run_test_with_different_metatables("index")
run_test_with_different_metatables("new_index")
run_test_with_different_metatables("call")

test.metatable.binary_op = function (metatable, metamethod, op, exp_value)
    local testTable, operand = effil.table(), effil.table()
    metatable['__' .. metamethod] = function(left, right)
        left.was_called = true
        return  left.value .. '_'.. right.value
    end
    effil.setmetatable(testTable, metatable)
    testTable.was_called = false
    testTable.value = "left"
    operand.value = "right"
    local left_operand, right_operand = table.unpack({testTable, operand})
    test.equal(op(left_operand, right_operand),
        exp_value == nil and "left_right" or exp_value)
    test.is_true(testTable.was_called)
end

local function test_binary_op(...)
    run_test_with_different_metatables("binary_op", ...)
end

test_binary_op("concat", function(a, b) return a .. b end)
test_binary_op("add", function(a, b) return a + b end)
test_binary_op("sub", function(a, b) return a - b end)
test_binary_op("mul", function(a, b) return a * b end)
test_binary_op("div", function(a, b) return a / b end)
test_binary_op("mod", function(a, b) return a % b end)
test_binary_op("pow", function(a, b) return a ^ b end)
test_binary_op("le", function(a, b) return a <= b end, true)
test_binary_op("lt", function(a, b) return a < b end, true)
test_binary_op("eq", function(a, b) return a == b end, true)


test.metatable.unary_op = function(metatable, metamethod, op)
    local share = effil.table()
    metatable['__' .. metamethod] = function(t)
        t.was_called = true
        return t.value .. "_suffix"
    end
    effil.setmetatable(share, metatable)

    share.was_called = false
    share.value = "value"
    test.equal(op(share), "value_suffix")
    test.is_true(share.was_called)
end

local function test_unary_op(...)
    run_test_with_different_metatables("unary_op", ...)
end

test_unary_op("unm",      function(a) return -a end)
test_unary_op("tostring", function(a) return tostring(a) end)
test_unary_op("len",      function(a) return #a end)

test.shared_table_with_metatable.tear_down = default_tear_down

if LUA_VERSION > 51 then

test.shared_table_with_metatable.iterators = function (iterator_type)
    local share = effil.table()
    local iterator = iterator_type
    effil.setmetatable(share, {
        ["__" .. iterator] = function(table)
            return function(t, key)
                local effil = require 'effil'
                local ret = (key and key * 2) or 1
                if ret > 2 ^ 10 then
                    return nil
                end
                return ret, effil.rawget(t, ret)
            end, table
        end
    })
    -- Add some values
    for i = 0, 10 do
        local pow = 2 ^ i
        share[pow] = math.random(pow)
    end
    -- Add some noise
    for i = 1, 100 do
        share[math.random(1000) * 10 - 1] = math.random(1000)
    end
    -- Check that *pairs iterator works
    local pow_iter = 1
    for k,v in _G[iterator](share) do
        test.equal(k, pow_iter)
        test.equal(v, share[pow_iter])
        pow_iter = pow_iter * 2
    end
    test.equal(pow_iter, 2 ^ 11)
end

test.shared_table_with_metatable.iterators("pairs")
test.shared_table_with_metatable.iterators("ipairs")

end -- LUA_VERSION > 51

test.shared_table_with_metatable.as_shared_table = function()
    local share = effil.table()
    local mt = effil.table()
    effil.setmetatable(share, mt)
    -- Empty metatable
    test.equal(share.table_key, nil)

    -- Only __index metamethod
    mt.__index = function(t, key)
        return "mt_" .. effil.rawget(t, key)
    end
    share.table_key = "table_value"
    test.equal(share.table_key, "mt_table_value")

    -- Both __index and __newindex metamethods
    mt.__newindex = function(t, key, value)
        effil.rawset(t, key, "mt_" .. value)
    end
    share.table_key = "table_value"
    test.equal(share.table_key, "mt_mt_table_value")

    -- Remove __index, use only __newindex metamethods
    mt.__index = nil
    share.table_key = "table_value"
    test.equal(share.table_key, "mt_table_value")
end

test.metatable_api.check_type_missmatch = function(wrong_arg_num, expected_type, func_name, ...)
    local args = {...}
    local ret, err = pcall(effil[func_name], table.unpack(args))
    if wrong_arg_num == nil then
        test.is_true(ret)
    else
        test.is_false(ret)
        test.equal(err, "bad argument #" .. wrong_arg_num .. " to 'effil." .. func_name ..
            "' (" .. expected_type .. " expected, got " .. effil.type(args[wrong_arg_num]) .. ")")
    end
end

do
    local func = function()end
    local thread = effil.thread(func)()
    thread:wait()

    local all_types = { 22, "s", true, func, effil.table(), thread, effil.channel(), coroutine.create(func) }

    local supports_stable = { [effil.type(effil.table())] = true }
    local supports_table_and_stable = { [effil.type({})] = true, [effil.type(effil.table())] = true }
    local supports_all = setmetatable({}, {_index = function() return true end})

    local funcs_to_test = {
        -- function name = { [param index] = { list of supported types } }
        setmetatable = { supports_table_and_stable, supports_table_and_stable },
        getmetatable = { supports_stable, supports_stable },
        rawset = { supports_stable, supports_all, supports_all },
        rawget = { supports_stable, supports_all }
    }

    for func_name, func_cfg in pairs(funcs_to_test) do
        local args_num = #func_cfg
        local args_state = {}
        for i = 1, args_num do
            args_state[i] = 1
        end

        local finish = false
        while not finish do
            local first_wrond_arg = nil
            local args = {}
            for i = 1, args_num do
                args[i] = all_types[args_state[i]]
                if func_cfg[i][effil.type(args[i])] == nil and first_wrond_arg == nil then
                    print("ASDASD: " .. effil.type(args[i]))
                    first_wrond_arg = i
                end
            end
            local expected_type = func_cfg[first_wrond_arg] == supports_stable and "effil.table" or "table"
            test.metatable_api.check_type_missmatch(first_wrond_arg, expected_type, func_name, table.unpack(args))

            for i = 1, args_num do
                if args_state[i] < #all_types then
                    args_state[i] = args_state[i] + 1
                    break
                end
                if i == args_num then
                    finish = true
                end
            end
        end
    end
end