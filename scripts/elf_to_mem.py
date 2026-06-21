#!/usr/bin/env python3
"""Convert ELF32 little-endian PT_LOAD segments to byte-addressed hex images."""
from __future__ import annotations
import argparse, struct
from pathlib import Path

def main() -> int:
    p=argparse.ArgumentParser(); p.add_argument("elf", type=Path); p.add_argument("--output", type=Path, required=True); args=p.parse_args()
    data=args.elf.read_bytes()
    if data[:4] != b"\x7fELF" or data[4] != 1 or data[5] != 1: raise SystemExit("expected ELF32 little-endian input")
    _, phoff, _, _, _, phentsize, phnum, _, _, _ = struct.unpack_from("<16sIIIIHHHHHH", data, 0)
    image: dict[int,int] = {}
    for i in range(phnum):
        p_type, p_off, p_vaddr, _, p_filesz, p_memsz, _, _ = struct.unpack_from("<IIIIIIII", data, phoff+i*phentsize)
        if p_type == 1:
            for off in range(p_memsz): image[p_vaddr+off] = data[p_off+off] if off < p_filesz else 0
    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.output.write_text("\n".join(f"{addr:08x} {value:02x}" for addr,value in sorted(image.items()))+"\n", encoding="utf-8")
    return 0
if __name__ == "__main__": raise SystemExit(main())
