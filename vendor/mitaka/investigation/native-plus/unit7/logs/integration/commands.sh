#!/bin/sh
# 再現用コマンド。原実行の時刻順 transcript ではない。
# source リポジトリのルートで、原本の親を明示して実行する。
set -eu
: "${PLUS_ROOT:?Set to the local Plus directory containing data and textures}"
: "${REGULAR_ROOT:?Set to the local regular directory containing data and textures}"

for configuration in normal san x86; do
  set --
  case "$configuration" in
    san) set -- SANITIZE=address,undefined ;;
    x86) set -- ARCH=x86_64 ;;
  esac
  CF96_DATA="$PLUS_ROOT/data/cf96.dat" make -C native/core -j6 \
    BUILD_DIR="build-unit7-root-$configuration" "$@" all test reference-test \
    rotation-reference-test lunar-reference-test atmosphere-reference-test eclipse-reference-test
  make -C native/gui -j6 BUILD_DIR="build-unit7-root-$configuration" "$@" all test
done
# ウィンドウを使う試験を並行起動しない。
for configuration in normal san x86; do
  set --
  case "$configuration" in
    san) set -- SANITIZE=address,undefined ;;
    x86) set -- ARCH=x86_64 ;;
  esac
  make -C native/gui BUILD_DIR="build-unit7-root-$configuration" "$@" controller-test html-browser-test
  DATA_ROOT="$PLUS_ROOT/data" make -C native/gui BUILD_DIR="build-unit7-root-$configuration" "$@" smoke
done
DATA_ROOT="$REGULAR_ROOT/data" make -C native/gui BUILD_DIR=build-unit7-root-normal smoke
for data_parent in "$PLUS_ROOT" "$REGULAR_ROOT"; do
  DATA_ROOT="$data_parent" make -C native/core BUILD_DIR=build-unit7-root-normal data-test
  DATA_ROOT="$data_parent/data" make -C native/gui BUILD_DIR=build-unit7-root-normal data-test
done
gh repo view mocho271828/Mitaka --json nameWithOwner,visibility,isPrivate
gh repo view mocho271828/Mitaka_plus --json nameWithOwner,visibility,isPrivate
