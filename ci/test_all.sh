#!/usr/bin/env bash
set -e

checkdump() { # $1 - binary name
    COREFILE=$(find . -maxdepth 1 -name "core*" | head -n 1) # find core file
    if [ -f "$COREFILE" ] && [ $(which gdb) ]; then
        gdb -c "$COREFILE" ./tests -ex "thread apply all bt" -ex "set pagination 0" -batch
    fi
}

for build_type in debug release; do
    mkdir -p $build_type && cd $build_type
    cmake -DCMAKE_BUILD_TYPE=$build_type $@ .. && make -j4 install
    ./tests || checkdump ./tests
    lua run_tests.lua || checkdump lua
done
