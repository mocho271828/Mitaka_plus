#!/bin/sh
# 原本を読み取り、指定した出力先へ局所的な静的証拠だけを生成する。
set -eu
source_dir='/Users/kota/mitaka/mitaka_plus/Contents/SharedSupport/prefix/drive_c/Program Files/mitaka'
binary="$source_dir/mitakaPlus.exe"
output_dir="${1:?usage: commands.sh OUTPUT_DIRECTORY}"
mkdir -p "$output_dir"
while read -r name start stop; do
    /usr/bin/objdump -d --x86-asm-syntax=intel --start-address="$start" --stop-address="$stop" "$binary" > "$output_dir/$name.asm"
done <<'RANGES'
mitaka-n23-time-animation 0x5ec120 0x5ec3b0
mitaka-n23-time-calendar-adapters 0x5ea930 0x5ead30
mitaka-n23-time-calendar-conversion 0x41e180 0x41e800
mitaka-n23-time-calendar-wrappers 0x666030 0x666a70
mitaka-n23-time-clock-consumer 0x511804 0x51191f
mitaka-n23-time-local-adapters 0x5eb3f0 0x5eb760
mitaka-n23-time-local-wrappers 0x667560 0x667a10
mitaka-n23-time-realtime 0x5ec920 0x5ec9c0
mitaka-n23-time-registration 0x669070 0x6699e0
mitaka-n23-time-rewind-current 0x5ea326 0x5ea440
mitaka-n23-time-setjd 0x5ec040 0x5ec120
mitaka-n23-time-state-setters 0x485330 0x4853b0
mitaka-n23-time-state-wrappers-tail 0x6681a0 0x6683e0
mitaka-n23-time-state-wrappers 0x667e00 0x6683e0
mitaka-n23-time-step-adapters 0x5e8fc0 0x5ea500
mitaka-n23-time-step-custom 0x5e9746 0x5e97a0
mitaka-n23-time-step-speed 0x5ec3b0 0x5ec620
mitaka-n23-time-tracking-setter 0x5114b0 0x511660
mitaka-n23-time-tracking 0x4850c0 0x485200
julian-date-accessors 0x59c3a0 0x59c400
RANGES
shasum -a 256 "$binary" "$source_dir/doc/script_jp/time.html" "$source_dir/scripts/gui.lua" "$source_dir/scripts/shortcuts.lua" > "$output_dir/source-sha256.txt"
python3 - "$binary" > "$output_dir/constants.txt" <<'PY'
from pathlib import Path
import struct
import sys

data = Path(sys.argv[1]).read_bytes()
pe_offset = struct.unpack_from('<I', data, 0x3c)[0]
section_count = struct.unpack_from('<H', data, pe_offset + 6)[0]
optional_size = struct.unpack_from('<H', data, pe_offset + 20)[0]
image_base = struct.unpack_from('<I', data, pe_offset + 52)[0]
sections = []
for index in range(section_count):
    start = pe_offset + 24 + optional_size + index * 40
    _, address, size, offset = struct.unpack_from('<IIII', data, start + 8)
    sections.append((address + image_base, size, offset))

def file_offset(address: int) -> int:
    for start, size, offset in sections:
        if start <= address < start + size:
            return offset + address - start
    raise ValueError(f'address outside PE raw sections: {address:#x}')

print(f'PE32 image base: {image_base:#x}')
print('step day table VA 0x00d70660:')
for index, value in enumerate(struct.unpack_from('<12d', data, file_offset(0xd70660))):
    print(f'{index}: {value:.17g}')
for name, address in [('STEP_SEC', 0xcaa584), ('STEP_10SEC', 0xcaa590),
        ('STEP_MIN', 0xcaa59c), ('STEP_10MIN', 0xcaa5a8), ('STEP_HOUR', 0xcaa5b4),
        ('STEP_DAY', 0xcaa5c0), ('STEP_WEEK', 0xcaa5cc), ('STEP_MONTH', 0xcaa5d8),
        ('STEP_YEAR', 0xcaa5e4), ('STEP_10YEAR', 0xcaa5f0), ('STEP_100YEAR', 0xcaa5fc),
        ('STEP_VALUE', 0xcaa60c)]:
    start = file_offset(address)
    value = data[start:data.index(b'\0', start)]
    print(f'{name} VA {address:#010x}: {value!r}')
for name in ['backward', 'rewind']:
    print(f'{name} NUL-terminated occurrences: {data.count(name.encode() + bytes([0]))}')
PY
