#!/bin/bash
set -euo pipefail

repository_root=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../../../../.." && pwd)
cd "$repository_root"
binary_directory=/tmp/mitaka-unit7-place-landscape
log_directory=investigation/native-plus/unit7/logs/n07
mkdir -p "$binary_directory" "$log_directory"

common_flags=(-std=c++17 -Wall -Wextra -Wpedantic -Werror -g -mmacosx-version-min=13.0
              -I native/gui/include -I native/core/include)
model_sources=(native/gui/tests/test_place_display_model.cpp native/gui/src/place_display_model.cpp
               native/gui/src/observer_places.cpp native/core/src/place_catalog.cpp native/core/src/catalog.cpp)
mesh_sources=(native/gui/tests/test_landscape_geometry.cpp native/gui/src/landscape_geometry.cpp)
data_roots=(
    '/Users/kota/mitaka/mitaka_plus/Contents/SharedSupport/prefix/drive_c/Program Files/mitaka/data'
    '/Users/kota/mitaka/mitaka/Contents/SharedSupport/prefix/drive_c/Program Files/mitaka/data'
)

for configuration in normal sanitized x86_64; do
    runner=(/usr/bin/env)
    case "$configuration" in
        normal) flags=(-O2) ;;
        sanitized) flags=(-O1 -fno-omit-frame-pointer -fsanitize=address,undefined) ;;
        x86_64) flags=(-O2 -arch x86_64); runner=(arch -x86_64) ;;
    esac
    xcrun clang++ "${common_flags[@]}" "${flags[@]}" "${model_sources[@]}" \
        -o "$binary_directory/test_place_display_model_$configuration" \
        > "$log_directory/place-display-build-$configuration.txt" 2>&1
    "${runner[@]}" "$binary_directory/test_place_display_model_$configuration" "${data_roots[@]}" \
        > "$log_directory/place-display-$configuration.txt" 2>&1
    xcrun clang++ "${common_flags[@]}" "${flags[@]}" "${mesh_sources[@]}" \
        -o "$binary_directory/test_landscape_geometry_$configuration" \
        > "$log_directory/landscape-build-$configuration.txt" 2>&1
    "${runner[@]}" "$binary_directory/test_landscape_geometry_$configuration" \
        > "$log_directory/landscape-$configuration.txt" 2>&1
done
