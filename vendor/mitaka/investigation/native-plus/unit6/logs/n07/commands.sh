#!/bin/bash
# 保存済み実行メモから組み立てた再現用コマンド。元の shell transcript ではない。
set -euo pipefail
cd /Users/kota/mitaka/repositories/Mitaka
n07_output=$(mktemp -d /tmp/mitaka-n07-reproduce.XXXXXX)
n07_plus='/Users/kota/mitaka/mitaka_plus/Contents/SharedSupport/prefix/drive_c/Program Files/mitaka/data'
n07_regular='/Users/kota/mitaka/mitaka/Contents/SharedSupport/prefix/drive_c/Program Files/mitaka/data'
n07_common=(-std=c++17 -mmacosx-version-min=13.0 -Wall -Wextra -Wpedantic -Werror -O2 -g -Inative/gui/include -Inative/core/include)
for n07_configuration in normal san x86; do
    n07_flags=()
    if [[ "$n07_configuration" == san ]]; then
        n07_flags=(-O1 -fno-omit-frame-pointer -fsanitize=address,undefined)
    elif [[ "$n07_configuration" == x86 ]]; then
        n07_flags=(-arch x86_64)
    fi
    clang++ "${n07_common[@]}" "${n07_flags[@]}" native/gui/tests/test_observer_places.cpp native/gui/src/observer_places.cpp native/core/src/place_catalog.cpp native/core/src/catalog.cpp -o "$n07_output/observer-$n07_configuration"
    "$n07_output/observer-$n07_configuration" > "$n07_output/$n07_configuration.log" 2>&1
    "$n07_output/observer-$n07_configuration" "$n07_plus" > "$n07_output/plus-$n07_configuration.log" 2>&1
    "$n07_output/observer-$n07_configuration" "$n07_regular" > "$n07_output/regular-$n07_configuration.log" 2>&1
    clang++ "${n07_common[@]}" "${n07_flags[@]}" native/core/tests/test_place_catalog.cpp native/core/src/place_catalog.cpp native/core/src/catalog.cpp -o "$n07_output/core-$n07_configuration"
    "$n07_output/core-$n07_configuration" "$n07_plus" > "$n07_output/core-$n07_configuration.log" 2>&1
done
