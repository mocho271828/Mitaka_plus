#!/bin/bash
set -euo pipefail
cd /Users/kota/mitaka/repositories/Mitaka
mode=${1:?mode}
flags=(-std=c++17 -g -Wall -Wextra -Wpedantic -Werror -mmacosx-version-min=13.0 -Inative/core/include -Inative/gui/include)
case "$mode" in
normal) dir=native/gui/build-unit5-orbit-pipeline; flags+=(-O2 -arch arm64);;
san) dir=native/gui/build-unit5-orbit-pipeline-san; flags+=(-O1 -arch arm64 -fno-omit-frame-pointer -fsanitize=address,undefined);;
x86) dir=native/gui/build-unit5-orbit-pipeline-x86; flags+=(-O2 -arch x86_64);;
esac
mkdir -p "$dir"
objects=()
for name in astronomy catalog small_body_catalog small_body_text small_body_orbit small_body_orbit_path minor_planet_position; do
  clang++ "${flags[@]}" -c "native/core/src/$name.cpp" -o "$dir/$name.o"
  objects+=("$dir/$name.o")
done
for name in small_body_display small_body_orbit_model; do
  clang++ "${flags[@]}" -c "native/gui/src/$name.cpp" -o "$dir/$name.o"
  objects+=("$dir/$name.o")
done
for name in small_body_model SmallBodyOrbitController; do
  clang++ "${flags[@]}" -fobjc-arc -c "native/gui/src/$name.mm" -o "$dir/$name.o"
  objects+=("$dir/$name.o")
done
for test in test_small_body_orbit_model test_small_body_orbit_controller; do
  clang++ "${flags[@]}" -fobjc-arc "native/gui/tests/$test.mm" "${objects[@]}" -framework Foundation -Wl,-fatal_warnings -o "$dir/$test"
done
printf '%s orbit pipeline strict build PASS\n' "$mode"
