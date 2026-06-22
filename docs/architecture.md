# Sparrow-V architecture

## Current repository architecture

The repository contains a scalar RV32I baseline and a separate development pipeline. `rtl/core/rv32_core.sv` is the protected production/reference scalar implementation. It is a three-stage, single-issue in-order IF/DX/MW design with external instruction and data valid/ready interfaces, terminal simulation-oriented traps, and the directed integration test in `tb/integration/tb_scalar_core.sv`.

`rtl/core/rv32_core_pipe.sv` is an isolated experimental implementation. The human-approved production-readiness assessment selected **C. Do not promote**: its `retire_mem_*` ports are constant zero while the reference core emits store retirement data, so identical port names do not establish compatible trace semantics. `rv32_core.sv` remains the protected production/reference core.

The scalar decoder, immediate generator, ALU, and register file are in `rtl/core/`. The shared scalar package is `rtl/common/sparrowv_scalar_pkg.sv`. The documented production instruction and trap contract is in `docs/architecture/scalar_core.md`; fetch and memory protocols are in `fetch_frontend.md` and `memory_interface.md`.

The detailed production-readiness comparison and evidence limits are in
`docs/architecture/scalar_production_readiness.md`.

The reference scalar core uses terminal sticky trap state (`mepc`, `mcause`, `mtvec`, `trap_valid`). Its data interface is one outstanding request/response, byte-addressed, little-endian, with byte strobes. The frozen v1 scalar integration contract is `architecture/scalar_interface_freeze.md`.

## Verification and software boundary

Directed scalar simulation uses Icarus through `make test-scalar-directed`; Verilator lint is `make lint`; repository/documentation checks are `make check`. Python contains a small RV32I reference helper and repository tests. A scalar smoke assembly source and ELF conversion/build scripts exist, but the local environment has no RISC-V cross compiler, so compiled software execution is not established.

There is no vector RTL, scratchpad RTL, cache, randomized regression, scoreboard framework, formal flow, CI workflow, synthesis project, FPGA build, or OpenLane result in this repository snapshot.

## Approved long-term direction

The planning material proposes a compact RV32I scalar CPU coupled to a custom four-lane INT8/INT16 vector engine, vector loads/stores, arithmetic/dot/reduction/masks, 2:4 sparsity metadata, a banked scratchpad, bare-metal software, golden models, randomized verification, and FPGA/ASIC evaluation. The human-approved RTL-independent v1 command/completion and separate vector-memory boundary are defined in `architecture/scalar_vector_interface.md`; no vector RTL exists. Every ISA, interface, memory, vector, sparse, and implementation-flow feature requires an explicit milestone and any required ADR before work begins.
