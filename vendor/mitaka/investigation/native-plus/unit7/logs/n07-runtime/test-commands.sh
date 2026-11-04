#!/bin/bash
set -euo pipefail
repository_root=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../../../../.." && pwd)
cd "$repository_root"
log_directory=investigation/native-plus/unit7/logs/n07-runtime
names=(earth_landscapes landscape_selection landscape_projection place_display_model
       landscape_geometry observer_places sky_model local_image HorizonLandscapeRenderer RendererQuality)
data_roots=(
    '/Users/kota/mitaka/mitaka_plus/Contents/SharedSupport/prefix/drive_c/Program Files/mitaka/data'
    '/Users/kota/mitaka/mitaka/Contents/SharedSupport/prefix/drive_c/Program Files/mitaka/data'
)
for configuration in normal sanitized x86_64; do
    build=build-place7-$configuration
    options=(ARCH= SANITIZE=)
    flags=(-O2)
    runner=(/usr/bin/env)
    case "$configuration" in
        sanitized) options=(SANITIZE=address,undefined); flags=(-O1 -fno-omit-frame-pointer -fsanitize=address,undefined) ;;
        x86_64) options=(ARCH=x86_64); flags=(-O2 -arch x86_64); runner=(arch -x86_64) ;;
    esac
    targets=()
    objects=()
    for name in "${names[@]}"; do
        targets+=("$build/$name.o")
        objects+=("native/gui/$build/$name.o")
    done
    make -C native/gui -j2 BUILD_DIR="$build" "${options[@]}" "${targets[@]}" core \
        > "$log_directory/build-$configuration.txt" 2>&1
    xcrun clang++ -Inative/gui/include -Inative/core/include -std=c++17 -Wall -Wextra -Wpedantic -Werror \
        -g -mmacosx-version-min=13.0 -fobjc-arc "${flags[@]}" native/gui/tests/test_earth_landscapes.mm \
        "${objects[@]}" "native/gui/$build/core/libmitaka_core.a" \
        -framework AppKit -framework ImageIO -framework CoreGraphics \
        -o "native/gui/$build/test_earth_landscapes" >> "$log_directory/build-$configuration.txt" 2>&1
    "${runner[@]}" "native/gui/$build/test_earth_landscapes" "${data_roots[@]}" \
        > "$log_directory/test-$configuration.txt" 2>&1
done
make -C native/gui BUILD_DIR=build-place7-normal ARCH= SANITIZE= build-place7-normal/test_planet_textures \
    > "$log_directory/planet-textures-build.txt" 2>&1
native/gui/build-place7-normal/test_planet_textures > "$log_directory/planet-textures-test.txt" 2>&1
