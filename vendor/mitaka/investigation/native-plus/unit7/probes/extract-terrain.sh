#!/bin/sh
set -eu
source_dir="${1:?pass the directory containing mitakaPlus.exe}"
output="${2:?pass a new directory for the measurements}"
binary="$source_dir/mitakaPlus.exe"
test -f "$binary"
mkdir -- "$output"
shasum -a 256 "$binary" > "$output/binary-sha256.txt"
/usr/bin/objdump -d --start-address=0x64f47e --stop-address=0x64f493 "$binary" > "$output/property-registration.txt"
/usr/bin/objdump -d --start-address=0x64ece0 --stop-address=0x64ed80 "$binary" > "$output/property-wrappers.txt"
/usr/bin/objdump -d --start-address=0x5cbc90 --stop-address=0x5cbcec "$binary" > "$output/property-accessors.txt"
/usr/bin/objdump -d --start-address=0x5cac89 --stop-address=0x5caca1 "$binary" > "$output/state-export.txt"
/usr/bin/objdump -d --start-address=0x485690 --stop-address=0x48569c "$binary" > "$output/mode-command.txt"
/usr/bin/objdump -d --start-address=0x548600 --stop-address=0x548628 "$binary" > "$output/mode-setter.txt"
# Apple objdump の -s は address 範囲を適用しないため、PE section から20 bytesだけ読む。
python3 - "$binary" > "$output/factor-table.txt" <<'PY'
import struct
import sys

with open(sys.argv[1], "rb") as binary_file:
    binary_file.seek(0x3C)
    pe_offset = struct.unpack("<I", binary_file.read(4))[0]
    binary_file.seek(pe_offset)
    assert binary_file.read(4) == b"PE\0\0"
    coff = binary_file.read(20)
    section_count = struct.unpack_from("<H", coff, 2)[0]
    optional_size = struct.unpack_from("<H", coff, 16)[0]
    optional = binary_file.read(optional_size)
    assert struct.unpack_from("<H", optional, 0)[0] == 0x10B
    image_base = struct.unpack_from("<I", optional, 28)[0]
    target_va = 0xC32D48
    target_rva = target_va - image_base
    table_offset = None
    for section_index in range(section_count):
        section = binary_file.read(40)
        virtual_size, virtual_address, raw_size, raw_offset = struct.unpack_from("<4I", section, 8)
        if virtual_address <= target_rva and target_rva + 20 <= virtual_address + raw_size:
            assert table_offset is None
            table_offset = raw_offset + target_rva - virtual_address
    assert table_offset is not None
    binary_file.seek(table_offset)
    table_bytes = binary_file.read(20)
    assert len(table_bytes) == 20
    print(f"VA=0x{target_va:x} file_offset=0x{table_offset:x} length=20")
    print(f"raw={table_bytes.hex()}")
    print(f"LE float32={struct.unpack('<5f', table_bytes)}")
PY
