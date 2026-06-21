# Phase 1 Scalar Baseline Report

## Implemented scope

Original SystemVerilog implements `rv32_core`, register file, decoder, immediate generator, ALU, fetch control, registered memory/writeback control, minimal traps, and counters. It implements the approved RV32I instruction classes: LUI, AUIPC, JAL/JALR, branches, OP-IMM, OP, loads/stores, FENCE, ECALL, and EBREAK.

Unsupported extensions and instructions trap as illegal: compressed, multiply/divide, floating-point, atomics, CSR operations, custom-0/vector operations, interrupts, and virtual memory.

## Pipeline and hazards

The core has IF, DX, and MW stages. It is single issue and in order. DX never overlaps a valid MW entry, so no forwarding path is required: RAW and load-use behavior is an explicit full interlock. One outstanding instruction request and one data request are permitted. Taken control flow is resolved in DX; because fetch is non-speculative, its documented penalty is one lost fetch opportunity.

## Traps, memory, and counters

`rst_n` is synchronous active-low. The reset PC and trap vector are parameters. Illegal, instruction-misaligned, load-misaligned, store-misaligned, ECALL, and EBREAK traps record `mepc`/`mcause`, redirect to `mtvec`, and do not retire. Instruction/data interfaces are valid/ready request and response channels with 32-bit byte addresses and little-endian byte strobes. Counters are debug outputs: `cycle_count` and `instret_count`.

## Verification

`make sim-scalar` runs a self-checking Icarus simulation with delayed responses and periodic request backpressure. It checks ALU classes, branches, JAL/JALR, loads/stores, extension, x0, traps, reset, and counters. `make lint` invokes Verilator lint. Exact command results are recorded in the delivery response for this phase.

## Software flow

`sw/tests/scalar_smoke.S` is a bare-metal source that writes a pass/fail signature and terminates through ECALL. `scripts/build_program.py` invokes a configured RV32I compiler, and `scripts/elf_to_mem.py` converts ELF32 little-endian loadable segments to byte-addressed hex records. Example: `RISCV_CC=riscv32-unknown-elf-gcc python3 scripts/build_program.py sw/tests/scalar_smoke.S --output build/scalar_smoke.elf`, then `python3 scripts/elf_to_mem.py build/scalar_smoke.elf --output build/scalar_smoke.mem`. No RISC-V cross compiler is installed locally, so compiler-based smoke validation was not run; the RTL test uses a documented hand-encoded fallback image.

## Known limitations and next task

The scalar implementation is a correctness-first baseline, not a performance claim or complete privileged RV32I platform. Phase 2 should add startup/linker support, a compiler invocation wrapper, ELF/image loading, and a compiled C smoke test after a supported RV32I toolchain is available. Do not start vector work yet.
