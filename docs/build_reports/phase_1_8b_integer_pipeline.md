# Phase 1.8b: Integer Development Pipeline

`rtl/core/rv32_core_pipe.sv` is an isolated development implementation. It has not replaced or modified `rtl/core/rv32_core.sv`.

## Scope and datapath

Implemented instructions are LUI, AUIPC; ADDI, SLTI, SLTIU, XORI, ORI, ANDI, SLLI, SRLI, SRAI; and ADD, SUB, SLL, SLT, SLTU, XOR, SRL, SRA, OR, AND. ECALL is a terminal test event. Branches, jumps, loads, stores, vectors, sparse execution, and scratchpad behavior are deliberately unsupported.

The development core instantiates the existing `rv32_decoder`, `rv32_immediate`, `rv32_alu`, and `rv32_regfile`. A development gate accepts only the listed opcode classes and ECALL. Thus decoder-recognized memory/control operations, EBREAK, unknown opcodes, invalid OP/OP-IMM funct fields, and invalid immediate-shift funct7 encodings retire exactly once as illegal terminal events (cause 2) and cannot write a register.

DX retains PC, instruction, rs1/rs2 indices and captured values, immediate, source-use and immediate-select controls, ALU operation, rd, register-write control, upper-immediate selection, and illegal/ECALL metadata. MW retains PC, instruction, rd, write-enable, completed writeback value, terminal/illegal metadata, and cause. Retire reports the MW identity and writeback fields; terminal events also report cause.

## Forwarding and checks

For each used operand, MW forwarding is selected when `mw_v && mw_we && !mw_terminal && mw_rd != 0 && mw_rd == dx_rsN`. `rs2` forwarding is bypassed for OP-IMM and upper-immediate operations. A same-edge writeback-to-IF capture bypass covers a register-file read coincident with retirement. No dependency bubbles are added for these ALU results.

Active checks cover invalid MW writes, illegal-register writes, x0 integrity, and exclusion of x0 from forwarding. The existing pipeline handshakes preserve blocked IF/DX/MW payloads; memory ports remain tied off for this development-only pass.

## Tests and measurements

`make test-scalar-pipe-alu` checks every listed mnemonic, zero/one/negative-one, `0x80000000`, signed and unsigned comparisons, logical/arithmetic shifts, shift counts 0/1/31 plus register five-bit masking, LUI construction, and AUIPC PC use. Its 24-instruction mixed stream retires consecutively in 29 total cycles (CPI 1.208333 including startup and ECALL).

`make test-scalar-pipe-forward` checks ADDI-to-ADDI, ADD-to-SUB, rs1, rs2, both operands from one result, a three-step chain, alternating independent/dependent work, x0 writes/readback, and back-to-back writes to one rd. It retires 12 instructions on cycles 5 through 16, a maximum consecutive run of 12, in 17 cycles (CPI 1.416667 including startup and ECALL), with `dep_stall_cycles=0`.

`make test-scalar-pipe-dev` retains the 16-independent-ADDI regression: cycles 5 through 20, 16 instructions, maximum recorded consecutive run 15 under its legacy monitor, 21 total cycles, CPI 1.312500. `make test-scalar-pipe-alu` also runs the invalid-SLLI-funct7 regression; it observes cause 2, PC 0, no register write, and no normal retirement.

The remaining limitations are intentional: no control flow, data memory, complete traps, privileged state, or production-core integration.
