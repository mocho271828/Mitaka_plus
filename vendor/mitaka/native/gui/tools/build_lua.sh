#!/bin/bash
set -euo pipefail

# Homebrew の実行OS要件に依存せず、アプリと同じ13.0/CPU向けに固定版をビルドする。
output_dir="${1:?Usage: build_lua.sh OUTPUT_DIR [ARCH] [SANITIZE]}"
target_arch="${2:-$(uname -m)}"
sanitizers="${3:-}"
case "$target_arch" in arm64|x86_64) ;; *) echo "Unsupported Lua architecture: $target_arch" >&2; exit 2;; esac
case "$sanitizers" in ''|address|undefined|address,undefined) ;; *) echo "Unsupported sanitizer: $sanitizers" >&2; exit 2;; esac
version=5.4.9
checksum=2335b6c582a52654f94612bf10d2f4672805d05329aa6568b1d8cd9e5c6fb8e6
mkdir -p "$output_dir"
output_dir="$(cd "$output_dir" && pwd)"
script_dir="$(cd "$(dirname "$0")" && pwd)"
archive="$script_dir/../vendor/lua-$version.tar.gz"
actual_checksum="$(shasum -a 256 "$archive")"
if [[ "${actual_checksum%% *}" != "$checksum" ]]; then
    echo "Lua archive SHA256 mismatch: $archive" >&2
    exit 1
fi
source_dir="$output_dir/lua-$version"
if [[ ! -f "$source_dir/src/lua.h" ]]; then tar -xzf "$archive" -C "$output_dir"; fi
signature="$version/$target_arch/$sanitizers/macos13"
if [[ -f "$output_dir/liblua.a" && -f "$output_dir/build.signature" && "$(cat "$output_dir/build.signature")" == "$signature" ]]; then exit 0; fi
object_dir="$output_dir/objects-$target_arch"
mkdir -p "$object_dir" "$output_dir/include"
flags=(-std=c99 -O2 -g -mmacosx-version-min=13.0 -arch "$target_arch" -DLUA_USE_MACOSX -fPIC)
if [[ -n "$sanitizers" ]]; then flags+=(-O1 -fno-omit-frame-pointer "-fsanitize=$sanitizers"); fi
objects=()
for source_file in "$source_dir"/src/*.c; do
    basename="${source_file##*/}"
    case "$basename" in lua.c|luac.c) continue;; esac
    object_file="$object_dir/${basename%.c}.o"
    xcrun clang "${flags[@]}" -c "$source_file" -o "$object_file"
    objects+=("$object_file")
done
xcrun libtool -static -o "$output_dir/liblua.a" "${objects[@]}"
for header in lua.h luaconf.h lauxlib.h lualib.h lua.hpp; do cp "$source_dir/src/$header" "$output_dir/include/$header"; done
printf '%s\n' "$signature" > "$output_dir/build.signature"
