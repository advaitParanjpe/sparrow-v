#!/usr/bin/env python3
"""Build one freestanding RV32I assembly source when a cross compiler exists."""
from __future__ import annotations
import argparse, os, shutil, subprocess
from pathlib import Path

def main() -> int:
    parser=argparse.ArgumentParser(); parser.add_argument("source",type=Path); parser.add_argument("--output",type=Path,required=True); args=parser.parse_args()
    compiler=os.environ.get("RISCV_CC", "riscv32-unknown-elf-gcc")
    if shutil.which(compiler) is None:
        raise SystemExit(f"RISC-V compiler not found: {compiler}; set RISCV_CC to a supported RV32I compiler")
    args.output.parent.mkdir(parents=True, exist_ok=True)
    subprocess.run([compiler,"-march=rv32i","-mabi=ilp32","-nostdlib","-Wl,-e,_start","-o",str(args.output),str(args.source)],check=True)
    return 0
if __name__ == "__main__": raise SystemExit(main())
