#!/usr/bin/env bash
set -e

export DYLD_LIBRARY_PATH="$LUA_DIR/lib:$DYLD_LIBRARY_PATH"

for build_type in debug release; do
    mkdir -p $build_type
    (cd $build_type && cmake -DCMAKE_BUILD_TYPE=$build_type $@ .. && make -j4 install)
    (cd $build_type && ./tests && $LUA_BIN tests.lua)
done
