#!/bin/sh
# リポジトリのルートから実行する。製品データを入力せず、窓を作らない局所試験。
set -eu
output_dir="${1:?usage: commands.sh OUTPUT_DIRECTORY}"
mkdir -p "$output_dir"
for configuration in normal san x86; do
    build="build-unit7-time/$configuration"
    case "$configuration" in
        normal) set -- ;;
        san) set -- SANITIZE=address,undefined ;;
        x86) set -- ARCH=x86_64 ;;
    esac
    make -C native/gui BUILD_DIR="$build" "$@" -j4 \
        "$build/AppScripting.o" "$build/test_playback_clock" \
        "$build/test_playback_controller" "$build/test_plus_time_step" script-test \
        > "$output_dir/$configuration-integration-build.log" 2>&1
    for test in plus_time_step playback_clock playback_controller; do
        case "$configuration" in
            normal) "native/gui/$build/test_$test" ;;
            san) ASAN_OPTIONS=detect_leaks=0 "native/gui/$build/test_$test" ;;
            x86) arch -x86_64 "native/gui/$build/test_$test" ;;
        esac > "$output_dir/$configuration-$test.log" 2>&1
    done
done
