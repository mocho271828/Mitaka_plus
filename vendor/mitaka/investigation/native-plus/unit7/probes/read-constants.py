"""Read only the cited PE constants and scan bounded .text for direct calls."""
from pathlib import Path
import struct
import sys

image = Path(sys.argv[1]).read_bytes()
pe_offset = struct.unpack_from("<I", image, 0x3C)[0]
section_count = struct.unpack_from("<H", image, pe_offset + 6)[0]
optional_size = struct.unpack_from("<H", image, pe_offset + 20)[0]
image_base = struct.unpack_from("<I", image, pe_offset + 24 + 28)[0]
sections: list[tuple[bytes, int, int, int, int]] = [
    struct.unpack_from("<8sIIII", image, pe_offset + 24 + optional_size + 40 * index)
    for index in range(section_count)
]


def bytes_at(address: int, count: int) -> bytes:
    for _, _, rva, raw_size, raw_pointer in sections:
        relative = address - image_base - rva
        if 0 <= relative and relative + count <= raw_size:
            return image[raw_pointer + relative:raw_pointer + relative + count]
    raise ValueError(f"Unmapped address {address:x}")


for address in (0xC31F40, 0xC31F30, 0xC29198, 0xC2B0E4, 0xC2B0EC, 0xC2B0F4, 0xC2B0FC):
    print(f"0x{address:x} string: {bytes_at(address, 32).split(bytes([0]), 1)[0]!r}")
for address in (0xC31EA8, 0xC31EB0, 0xC32768, 0xC3276C, 0xC31E84, 0xC31E7C,
                0xC31E6C, 0xC31E74, 0xC31E78):
    print(f"0x{address:x} float: {struct.unpack('<f', bytes_at(address, 4))[0]}")
for address in (0xC31DD8, 0xC31DF0, 0xC31DE8):
    print(f"0x{address:x} double: {struct.unpack('<d', bytes_at(address, 8))[0]}")
for index in range(8):
    address = 0xD71A88 + index * 4
    pointer = struct.unpack("<I", bytes_at(address, 4))[0]
    print(f"compass[{index}]: {bytes_at(pointer, 8).split(bytes([0]), 1)[0]!r}")
for name, _, rva, raw_size, raw_pointer in sections:
    if name.rstrip(bytes([0])) != b".text":
        continue
    text = image[raw_pointer:raw_pointer + raw_size]
    for index in range(len(text) - 4):
        if text[index] != 0xE8:
            continue
        call = image_base + rva + index
        if call + 5 + struct.unpack_from("<i", text, index + 1)[0] == 0x5336A0:
            print(f"direct E8 candidate -> landscape: 0x{call:x} (confirm instruction in disassembly)")
