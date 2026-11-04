#!/bin/sh
set -eu

# このスクリプトは原本を読み取るだけで、生成物は既存の除外済み build へ置く。
if [ "$#" -ne 2 ]; then
    echo "usage: commands.sh PLUS_DATA_DIRECTORY REGULAR_DATA_DIRECTORY" >&2
    exit 2
fi
plus_data=$1
regular_data=$2
repo=$(cd "$(dirname "$0")/../../../../.." && pwd)
cd "$repo"
log_dir=investigation/native-plus/unit7/logs/n16-sdss

for variant in normal san x86; do
    case "$variant" in
        normal) set -- -O2 ;;
        san) set -- -O1 -fno-omit-frame-pointer -fsanitize=address,undefined ;;
        x86) set -- -O2 -arch x86_64 ;;
    esac
    build_dir="native/gui/build-unit7-n16-$variant"
    mkdir -p "$build_dir"
    xcrun clang++ -std=c++17 -g -Wall -Wextra -Wpedantic -Werror \
        -mmacosx-version-min=13.0 "$@" \
        -Inative/gui/include -Inative/core/include \
        native/gui/tests/test_sdss_spatial_model.cpp \
        native/gui/src/sdss_spatial_model.cpp native/core/src/astronomy.cpp \
        native/core/src/catalog.cpp native/core/src/extended_catalog.cpp \
        -o "$build_dir/test_sdss_spatial_model" > "$log_dir/build-$variant.log" 2>&1
    "$build_dir/test_sdss_spatial_model" > "$log_dir/synthetic-$variant.log" 2>&1
    /usr/bin/time -l "$build_dir/test_sdss_spatial_model" "$plus_data" \
        > "$log_dir/plus-$variant.log" 2>&1
    /usr/bin/time -l "$build_dir/test_sdss_spatial_model" "$regular_data" \
        > "$log_dir/regular-$variant.log" 2>&1
done

shasum -a 256 "$plus_data/SDSS_GAL.dat" "$plus_data/SDSS_QSO.dat" \
    "$regular_data/SDSS_GAL.dat" "$regular_data/SDSS_QSO.dat" \
    > "$log_dir/original-data-sha256.txt"
{
    date -u '+%Y-%m-%d %H:%M:%S UTC'
    sw_vers
    uname -m
    xcrun clang++ --version
    file native/gui/build-unit7-n16-normal/test_sdss_spatial_model \
        native/gui/build-unit7-n16-x86/test_sdss_spatial_model
} > "$log_dir/environment.txt"
