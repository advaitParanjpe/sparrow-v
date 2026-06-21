# Project Status

## Current phase

**Phase 1.8c — development integer/control-flow pipeline complete; production integration remains pending.**

## Completed work

- Phase 0 scaffold and documentation audit are complete.
- Approved scalar decisions are recorded in accepted ADRs.
- Original three-stage RV32I RTL, delayed/backpressured memory-model simulation, directed smoke test, and minimal ELF conversion utility are present.

## Active blockers

- A RISC-V cross compiler is unavailable locally, so the assembly smoke source has not been compiled through the repository flow.
- Audit found global scalar serialization and a stalled instruction-request cancellation hazard during attempted overlap; vector integration is not approved.
- The isolated `rv32_core_pipe` now sustains one retirement per cycle for independent and forwardable integer streams. It is a development implementation and has not replaced `rv32_core.sv`.
- The same development core now has generation-tagged redirect-safe branches, JAL, and JALR; production behavior remains unchanged.
- Vector protocol/state, sparse format, scratchpad, workload, and FPGA/ASIC decisions remain Proposed and block later phases only.

## Next approved task

Review the development-pipeline evidence and decide whether to integrate its vetted frontend/datapath changes into the production scalar core. Do not begin vector architecture work.

Future implementation work is gated by `docs/current_milestone.md`; the repository workflow in `AGENTS.md` requires bounded milestone execution and human review for architecture decisions.

## Tests currently available

- Repository/documentation checks and Python repository-check tests.
- Icarus directed scalar simulation with response delays and request backpressure.
- Verilator RTL lint.

No synthesis, timing, FPGA, ASIC, benchmark, or application tests exist yet.

## Known limitations

- The production scalar core remains deliberately conservative: no bypassing and no concurrent DX/MW instruction overlap. The separate development core has ALU bypassing only.
- Trap state is terminal/sticky and is not a complete privileged architecture.
- No compiled C program, vector/sparse RTL, scratchpad, cache, FPGA, ASIC, timing, power, or benchmark result exists.
