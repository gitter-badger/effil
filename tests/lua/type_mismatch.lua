require "bootstrap-tests"

local basic_type_mismatch_test = function(err_msg, wrong_arg_num, func_name , ...)
    local func_to_call = func_name
    if type(func_name) == "string" then
        func_to_call = effil
        for word in string.gmatch(func_name, "[^%.]+") do
            func_to_call = func_to_call[word]
            test.is_not_nil(func_to_call)
        end
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
    local err_msg = "bad argument #" .. wrong_arg_num .. " to " ..
            (type(func_name) == "string" and "'effil." .. func_name or func_name.name) ..
            "' (" .. expected_type .. " expected, got " .. effil.type(args[wrong_arg_num]) .. ")"
    basic_type_mismatch_test(err_msg, wrong_arg_num, func_name, ...)
end

test.type_mismatch.unsupported_type = function(wrong_arg_num, func_name, ...)
    local args = {...}
    local err_msg = (type(func_name) == "string" and "effil." ..  func_name or func_name.name)
            .. ": unable to store object of " .. effil.type(args[wrong_arg_num]) .. " type"
    basic_type_mismatch_test(err_msg, wrong_arg_num, func_name, ...)
end

do
    local function create_object_generator(name, func)
        return setmetatable({ name = name }, { __call = func })
    end

    local channel_push_generator = create_object_generator("effil.channel:push",
        function(_, ...)
            return effil.channel():push(...)
        end
    )

    local thread_runner_generator = create_object_generator("effil.thread",
        function(_, ...)
            return effil.thread(function()end)(...)
        end
    )

    local table_set_value_generator = create_object_generator("effil.table",
        function(_, key, value)
            effil.table()[key] = value
        end
    )

    local table_get_value_generator = create_object_generator("effil.table",
        function(_, key)
            return effil.table()[key]
        end
    )

    local func = function()end
    local stable = effil.table()
    local thread = effil.thread(func)()
    thread:wait()

    local all_types = { 22, "s", true, {}, stable, func, thread, effil.channel(), coroutine.create(func) }

    for _, type_instance in ipairs(all_types) do
        local typename = effil.type(type_instance)

        -- effil.getmetatable
        if typename ~= "effil.table" then
            test.type_mismatch.input_types_mismatch(1, "effil.table", "getmetatable", type_instance)
        end

        -- effil.setmetatable
        if typename ~= "table" and typename ~= "effil.table" then
            test.type_mismatch.input_types_mismatch(1, "table", "setmetatable", type_instance, 44)
            test.type_mismatch.input_types_mismatch(2, "table", "setmetatable", {}, type_instance)
        end

        -- effil.rawset
        if typename ~= "effil.table" then
            test.type_mismatch.input_types_mismatch(1, "effil.table", "rawset", type_instance, 44, 22)
        end
        if typename == "thread" then
            test.type_mismatch.unsupported_type(2, "rawset", stable, type_instance, 22)
            test.type_mismatch.unsupported_type(3, "rawset", stable, 44, type_instance)
        end

        -- effil.rawget
        if typename ~= "effil.table" then
            test.type_mismatch.input_types_mismatch(1, "effil.table", "rawget", type_instance, 44)
        end
        if typename == "thread" then
            test.type_mismatch.unsupported_type(2, "rawget", stable, type_instance)
        end

        -- effil.thread
        if typename ~= "function" then
            test.type_mismatch.input_types_mismatch(1, "function", "thread", type_instance)
        end

        -- effil.sleep
        if typename ~= "number" then
            test.type_mismatch.input_types_mismatch(1, "number", "sleep", type_instance, "s")
        end
        if typename ~= "string" then
            test.type_mismatch.input_types_mismatch(2, "string", "sleep", 1, type_instance)
        end

        if typename ~= "number" then
            -- effil.channel
            test.type_mismatch.input_types_mismatch(1, "number", "channel", type_instance)

            -- effil.gc.step
            test.type_mismatch.input_types_mismatch(1, "number", "gc.step", type_instance)
        end

        if typename == "thread" then
            -- effil.channel:push()
            test.type_mismatch.unsupported_type(1, channel_push_generator, type_instance)

            -- effil.thread()()
            test.type_mismatch.unsupported_type(1, thread_runner_generator, type_instance)

            -- effil.table[key] = value
            test.type_mismatch.unsupported_type(1, table_set_value_generator, type_instance, 2)
            test.type_mismatch.unsupported_type(2, table_set_value_generator, 2, type_instance)
            -- effil.table[key]
            test.type_mismatch.unsupported_type(1, table_get_value_generator, type_instance)
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
