#!/bin/sh
# 再現用コマンド。原実行の時刻順 transcript ではない。
# source リポジトリのルートで、原本の親を明示して実行する。
set -eu
: "${PLUS_ROOT:?Set to the local Plus directory containing data and textures}"
: "${REGULAR_ROOT:?Set to the local regular directory containing data and textures}"

make -C native/core -j6 BUILD_DIR=build-unit6-root all test
make -C native/core -j6 BUILD_DIR=build-unit6-root-san SANITIZE=address,undefined all test
make -C native/core -j6 BUILD_DIR=build-unit6-root-x86 ARCH=x86_64 all test
make -C native/gui -j6 BUILD_DIR=build-unit6-root all test
make -C native/gui -j6 BUILD_DIR=build-unit6-root-san SANITIZE=address,undefined all test
make -C native/gui -j6 BUILD_DIR=build-unit6-root-x86 ARCH=x86_64 all test
# ウィンドウを使う試験を並行起動しない。
make -C native/gui BUILD_DIR=build-unit6-root controller-test
make -C native/gui BUILD_DIR=build-unit6-root-san SANITIZE=address,undefined controller-test
make -C native/gui BUILD_DIR=build-unit6-root-x86 ARCH=x86_64 controller-test
DATA_ROOT="$PLUS_ROOT/data" make -C native/gui BUILD_DIR=build-unit6-root smoke
DATA_ROOT="$PLUS_ROOT/data" make -C native/gui BUILD_DIR=build-unit6-root-san SANITIZE=address,undefined smoke
DATA_ROOT="$PLUS_ROOT/data" make -C native/gui BUILD_DIR=build-unit6-root-x86 ARCH=x86_64 smoke
DATA_ROOT="$REGULAR_ROOT/data" make -C native/gui BUILD_DIR=build-unit6-root smoke
for data_parent in "$PLUS_ROOT" "$REGULAR_ROOT"; do
  DATA_ROOT="$data_parent" make -C native/core BUILD_DIR=build-unit6-root data-test
  DATA_ROOT="$data_parent/data" make -C native/gui BUILD_DIR=build-unit6-root data-test
done
CF96_DATA="$PLUS_ROOT/data/cf96.dat" make -C native/core BUILD_DIR=build-unit6-root reference-test rotation-reference-test lunar-reference-test
# 新規 local clone: UNIT5 基点へ git diff --binary -- native と clean-files.txt の
# 新規ファイルを適用し、clone 内で次を実施した。元の build はコピーしない。
# make -C native/core -j6 all test
# make -C native/gui -j6 all test
gh repo view mocho271828/Mitaka --json nameWithOwner,visibility,isPrivate
gh repo view mocho271828/Mitaka_plus --json nameWithOwner,visibility,isPrivate
