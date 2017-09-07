require "bootstrap-tests"

local basic_type_mismatch_test = function(err_msg, wrong_arg_num, expected_type, func_name , ...)
    local func_to_call = effil
    for word in string.gmatch(func_name, "[^%.]+") do
        func_to_call = func_to_call[word]
        test.is_not_nil(func_to_call)
    end

    local ret, err = pcall(func_to_call, ...)
    test.is_false(ret)
    print("Original error: '" .. err .. "'")

    -- because error may start with trace back
    local trunc_err = string.sub(err, string.len(err) - string.len(err_msg) + 1, string.len(err))
    test.equal(trunc_err, err_msg)
end

test.type_mismatch.input_types_mismatch = function(wrong_arg_num, expected_type, func_name, ...)
    local args = {...}
    local err_msg = "bad argument #" .. wrong_arg_num .. " to 'effil." .. func_name ..
        "' (" .. expected_type .. " expected, got " .. effil.type(args[wrong_arg_num]) .. ")"
    basic_type_mismatch_test(err_msg, wrong_arg_num, expected_type, func_name, ...)
end

test.type_mismatch.unsupported_type = function(wrong_arg_num, expected_type, func_name, ...)
    local args = {...}
    local err_msg = "effil." .. func_name .. ": unable to store object of " .. effil.type(args[wrong_arg_num]) .. " type"
    basic_type_mismatch_test(err_msg, wrong_arg_num, expected_type, func_name, ...)
end

do
    local func = function()end
    local stable = effil.table()
    local thread = effil.thread(func)()
    thread:wait()

    local all_types = { 22, "s", true, {}, func, thread, effil.channel(), coroutine.create(func) }

    for _, type_instance in ipairs(all_types) do
        -- effil.getmetatable
        test.type_mismatch.input_types_mismatch(1, "effil.table", "getmetatable", type_instance)
        -- effil.setmetatable
        if type(type_instance) ~= "table" then
            test.type_mismatch.input_types_mismatch(1, "table", "setmetatable", type_instance, 44)
            test.type_mismatch.input_types_mismatch(2, "table", "setmetatable", {}, type_instance)
        end
        -- effil.rawset
        test.type_mismatch.input_types_mismatch(1, "effil.table", "rawset", type_instance, 44, 22)
        if type(type_instance) == "thread" then
            test.type_mismatch.unsupported_type(2, "table", "rawset", stable, type_instance, 22)
            test.type_mismatch.unsupported_type(3, "table", "rawset", stable, 44, type_instance)
        end
        -- effil.rawget
        test.type_mismatch.input_types_mismatch(1, "effil.table", "rawget", type_instance, 44)
        if type(type_instance) == "thread" then
            test.type_mismatch.unsupported_type(2, "table", "rawget", stable, type_instance)
        end

        -- effil.thread
        if type(type_instance) ~= "function" then
            test.type_mismatch.input_types_mismatch(1, "function", "thread", type_instance)
        end

        -- effil.sleep
        if type(type_instance) ~= "number" then
            test.type_mismatch.input_types_mismatch(1, "number", "sleep", type_instance, "s")
        end
        if type(type_instance) ~= "string" then
            test.type_mismatch.input_types_mismatch(2, "string", "sleep", 1, type_instance)
        end

        -- effil.channel
        if type(type_instance) ~= "number" then
            test.type_mismatch.input_types_mismatch(1, "number", "channel", type_instance)
        end

        -- effil.gc.step
        if type(type_instance) ~= "number" then
            test.type_mismatch.input_types_mismatch(1, "number", "gc.step", type_instance)
        end
    end
end

--[[

test.type_mismatch.check_after_test = function ()
    collectgarbage()
    effil.gc.collect()
    test.equal(effil.gc.count(), 1)
end

]]
