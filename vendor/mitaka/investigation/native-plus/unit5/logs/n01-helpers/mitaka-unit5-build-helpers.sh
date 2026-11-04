#!/bin/bash
set -eu
configuration="$1"
repo='/Users/kota/mitaka/repositories/Mitaka'
cd "$repo"
flags=(-std=c++17 -g -Wall -Wextra -Wpedantic -Werror -mmacosx-version-min=13.0)
case "$configuration" in
  normal) suffix=''; flags+=(-O2 -arch arm64) ;;
  san) suffix='-san'; flags+=(-O1 -arch arm64 -fno-omit-frame-pointer -fsanitize=address,undefined) ;;
  x86) suffix='-x86'; flags+=(-O2 -arch x86_64) ;;
  *) exit 2 ;;
esac
core_dir="native/core/build-unit5-orbit-path${suffix}"
gui_dir="native/gui/build-unit5-small-body-display${suffix}"
mkdir -p "$core_dir" "$gui_dir"
objects=()
for source in astronomy catalog small_body_catalog small_body_text small_body_orbit; do
  xcrun clang++ "${flags[@]}" -Inative/core/include -c "native/core/src/${source}.cpp" -o "$core_dir/$source.o"
  objects+=("$core_dir/$source.o")
done
xcrun clang++ "${flags[@]}" -Inative/core/include native/core/tests/test_small_body_orbit_path.cpp native/core/src/small_body_orbit_path.cpp "${objects[@]}" -Wl,-fatal_warnings -o "$core_dir/test_small_body_orbit_path"
xcrun clang++ "${flags[@]}" -Inative/core/include -Inative/gui/include native/gui/tests/test_small_body_display.cpp native/gui/src/small_body_display.cpp "${objects[@]}" -Wl,-fatal_warnings -o "$gui_dir/test_small_body_display"
printf '%s\n' "build $configuration succeeded (macOS 13 minimum)"
