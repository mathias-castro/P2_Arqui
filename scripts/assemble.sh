#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
AS=${AS_RISCV:-riscv64-unknown-elf-as}
LD=${LD_RISCV:-riscv64-unknown-elf-ld}
OBJCOPY=${OBJCOPY_RISCV:-riscv64-unknown-elf-objcopy}
OBJDUMP=${OBJDUMP_RISCV:-riscv64-unknown-elf-objdump}
mkdir -p build
for source in programs/*.s; do
    name=$(basename "$source" .s)
    "$AS" -march=rv32i -mabi=ilp32 -mno-relax "$source" -o "build/$name.o"
    "$LD" -m elf32lriscv -Ttext=0 --no-relax -e 0 "build/$name.o" -o "build/$name.elf"
    "$OBJCOPY" -O binary -j .text "build/$name.elf" "build/$name.bin"
    "$OBJDUMP" -d -M no-aliases,numeric "build/$name.elf" > "build/$name.dis"
    python3 - "$name" <<'PY'
import struct
import sys
from pathlib import Path
name = sys.argv[1]
data = Path(f'build/{name}.bin').read_bytes()
words = [word[0] for word in struct.iter_unpack('<I', data)]
assert len(words) <= 256
words.extend([0x00000013] * (256 - len(words)))
Path(f'programs/{name}.mem').write_text(''.join(f'{word:08x}\n' for word in words))
PY
done
