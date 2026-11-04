#!/bin/sh
# ローカル原本を変更せず、対象の逆アセンブル範囲を再取得する。
set -eu
label_runtime_exe='/Users/kota/mitaka/mitaka_plus/Contents/SharedSupport/prefix/drive_c/Program Files/mitaka/mitakaPlus.exe'
label_runtime_output=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
while read -r label_runtime_name label_runtime_start label_runtime_stop; do
  /usr/bin/objdump -d --x86-asm-syntax=intel --start-address="$label_runtime_start" --stop-address="$label_runtime_stop" "$label_runtime_exe" > "$label_runtime_output/$label_runtime_name.txt"
done <<'RANGES'
callers 0x54a000 0x54e180
billboard 0x5279c0 0x528210
surface-position 0x457f40 0x458230
camera-accessors 0x49a710 0x49a7b0
body-orientation 0x53ac70 0x53ae00
screen-values 0x5abfe0 0x5ac270
screen-wrappers 0x633140 0x633340
math-thunks 0xa8ee00 0xa8ee70
RANGES
