# Phase 1 Scalar Core Contract

## Implemented baseline

`rv32_core` is original Sparrow-V RTL: a three-stage, single-issue, in-order RV32I baseline with active-low synchronous `rst_n`.

1. **IF** issues one instruction-memory request and holds it until accepted; it then holds the request context until a response is accepted.
2. **DX** decodes one fetched instruction, reads the integer register file, executes ALU/branch/address logic, and creates a memory/writeback entry.
3. **MW** completes writeback or a single data-memory transaction and retires the instruction.

The conservative Phase 1 interlock permits no overlapping DX/MW work. There is therefore no bypass network: every RAW, including load-use, is resolved by holding fetch/decode until the older instruction has committed. This is intentionally simple and correct under arbitrary finite request backpressure and response delay.

Branches and jumps resolve in DX. Fetch is non-speculative, so no already-issued younger instruction exists to squash; redirect explicitly clears fetch state and installs the target PC. A taken branch/jump incurs one lost fetch opportunity before target fetch starts.

## ISA and traps

Implemented: LUI, AUIPC, JAL, JALR, all six conditional branches, all RV32I register-immediate and register-register ALU operations, LB/LH/LW/LBU/LHU, SB/SH/SW, FENCE, ECALL, and EBREAK. RV32I custom-0 (`0001011`) and all unsupported encodings trap as illegal.

Not implemented: compressed, M, F/D/Q, atomics, privilege software, virtual memory, interrupts, caches, prediction, or custom-vector execution.

The minimal trap state is `mepc`, `mcause`, `mtvec`, and `trap_valid`. `mtvec` resets from parameter `MTVEC_RESET`; `mepc` records the trapping instruction PC. Causes: instruction-address misalignment=0, illegal=2, breakpoint=3, load-address misalignment=4, store-address misalignment=6, ECALL=11. A trap does not retire or write a destination register. `trap_valid` is sticky until reset; this is a simulation-oriented terminal model, not a complete privilege implementation.

Reset sets PC to `RESET_PC`, clears IF/DX/MW valid state, clears all integer registers, trap state, and both counters. Memories are external and are not reset by core RTL.

## Counters and memory

`cycle_count` increments each non-reset clock. `instret_count` increments once when a non-trapping instruction completes MW; memory instructions retire only after their response. Both are exposed as debug outputs, not CSR reads in Phase 1.

Instruction and data ports use request valid/ready plus response valid/ready. At most one request and response is outstanding per port. Addresses are 32-bit byte addresses, data is 32-bit little-endian, and stores use byte strobes. Data requests are word-aligned on the port; the core selects or shifts byte/halfword lanes. Halfword and word fetch/data misalignment trap rather than split accesses.
