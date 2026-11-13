#!/bin/bash
set -eu
source_dir="${1:?pass the directory containing mitakaPlus.exe}"
landscape_output="${2:?pass a new directory for the measurements}"
landscape_exe="$source_dir/mitakaPlus.exe"
test -f "$landscape_exe"
mkdir -- "$landscape_output"
script_dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
while read -r name first last; do
    /usr/bin/objdump -d --x86-asm-syntax=intel --start-address="$first" --stop-address="$last" \
        "$landscape_exe" > "$landscape_output/$name.txt"
done <<'RANGES'
image-loader 0x51df30 0x51e700
texture-cache 0x43e6f0 0x43eeb0
landscape-caller 0x544500 0x544950
image-decode 0x44e480 0x44e780
image-upload 0x43d800 0x43d928
png-reader 0x44d5b0 0x44dda0
bmp-reader 0x44cb40 0x44d1f0
tga-reader 0x44dda0 0x44e310
body-pose 0x5491f0 0x549420
fallback 0x533825 0x533a80
fallback-planet 0x53425c 0x534648
glu-thunks 0xa9d9e0 0xa9da10
RANGES
python3 "$script_dir/read-constants.py" "$landscape_exe" > "$landscape_output/constants.txt"
xcrun clang -fobjc-arc "$script_dir/image-types.m" -framework Foundation -framework ImageIO \
    -o "$landscape_output/image-types"
"$landscape_output/image-types" > "$landscape_output/image-types.txt"
xcrun --show-sdk-path > "$landscape_output/sdk-path.txt"
landscape_sdk=$(xcrun --show-sdk-path)
sed -n '608,623p' "$landscape_sdk/System/Library/Frameworks/UniformTypeIdentifiers.framework/Headers/UTCoreTypes.h" \
    > "$landscape_output/sdk-bmp-uti.txt"
