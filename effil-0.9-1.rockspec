package = "effil"
version = "0.9-1"

source = {
    url = "gitrec+http://github.com/loud-hound/effil",
    branch="rockspec"
}

description = {
    summary  = "Multithreading library for Lua.",
    detailed = [[
       Effil is a library provides multithreading support for Lua.
       *luarocks install luarocks-fetch-gitrec*
    ]],
    homepage = "http://github.com/loud-hound/effil",
    license  = "MIT"
}

dependencies = {
    "lua >= 5.1"
}

local function get_unix_build(lib_extension)
    return {
        type = "cmake",
        variables = {
            CMAKE_BUILD_TYPE     = "Release",
            CMAKE_PREFIX_PATH    = "$(LUA_BINDIR)/..",
            CMAKE_INSTALL_PREFIX = "$(PREFIX)",
            CMAKE_LIBRARY_PATH   = "$(LUA_LIBDIR)",
            LUA_INCLUDE_DIR      = "$(LUA_INCDIR)",
            BUILD_ROCK           = "yes"
        },
      install = {
          lua = {
              "effil.lua"
          },
          lib = {
              "libeffil." .. lib_extension
          }
      }
    }
end

build = {
    platforms = 
    {
        linux = get_unix_build("so"),
        macosx = get_unix_build("dylib")
    }
}
