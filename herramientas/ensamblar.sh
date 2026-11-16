#!/usr/bin/env bash
# Genera los .mem (una instruccion en hexadecimal por linea) a partir de los .s
# Uso: ensamblar.sh carpeta_de_programas
set -euo pipefail
cd "$1"
tmp=$(mktemp -d)
for src in *.s; do
    n=${src%.s}
    riscv64-unknown-elf-as -march=rv32i -mabi=ilp32 -mno-relax "$src" -o "$tmp/$n.o"
    riscv64-unknown-elf-ld -m elf32lriscv -Ttext=0 --no-relax -e 0 "$tmp/$n.o" -o "$tmp/$n.elf" 2>/dev/null
    riscv64-unknown-elf-objcopy -O binary -j .text "$tmp/$n.elf" "$tmp/$n.bin"
    od -An -tx4 -w4 -v "$tmp/$n.bin" | tr -d ' ' > "$n.mem"
    riscv64-unknown-elf-objdump -d -M no-aliases,numeric "$tmp/$n.elf" | grep -E '^\s+[0-9a-f]+:' > "$tmp/$n.dis"
    echo "$n: $(wc -l < "$n.mem") instrucciones"
done
rm -rf "$tmp"
