# Implementation status

## Implemented and verified

- Production/reference scalar core: `rtl/core/rv32_core.sv`, with the directed integration regression invoked by `make test-scalar-directed`.
- Reusable scalar decoder, immediate generator, ALU, register file, package, directed testbench, Python repository checks, and reference helper.
- Repository documentation checks (`make check`) and Verilator lint (`make lint`) are defined.

## Implemented but incompletely verified

- `rtl/core/rv32_core_pipe.sv` and focused development testbenches document ALU/control-flow behavior, forwarding, fetch generations, and backpressure experiments. This implementation is isolated and has not replaced the production core.
- Development memory behavior is experimental. The focused `make test-scalar-pipe-memory` regression passed in this checkpoint after its test data was corrected, but it is not production integration evidence.
- Focused pipeline terminal-trap verification is available as `make test-scalar-pipe-trap`. It directly covers control-target, LH/LW, and SH/SW misalignment causes, fault PCs, suppressed load/store side effects, terminal retirement, and x0 preservation.
- Differential verification covers the shared normal subset, including LB/LBU/LH/LHU/LW and SB/SH/SW. The harness checks normalized retirement/register/store traces, final register/memory/terminal state, directed extension and partial-store effects, including an immediate LHU-dependent ADDI, and memory-focused controlled-negative detection. At commit `5850b698`, immediate seeds 1–500 passed in 18.4 seconds; seeds 1–16 passed in each request-backpressured, delayed-response, and mixed mode; seed 17 was rerun in modes 0–3. The pipeline remains experimental; this is not formal equivalence.
- Production-readiness conclusion: **C. Do not promote** `rv32_core_pipe`. Its `retire_mem_*` outputs are hardwired zero, unlike the reference core's accepted-store retirement trace. The differential harness compares accepted stores rather than those pipe outputs, so interface equivalence is unproven and currently false for that bundle. `rv32_core.sv` remains production/reference.
- Scalar interface v1 and the human-approved RTL-independent vector command/completion and separate memory boundary are specified in `docs/architecture/scalar_interface_freeze.md` and `docs/architecture/scalar_vector_interface.md`. No vector RTL or scalar promotion was performed.

## Planned, not implemented

Vector engine/ISA, vector memory, INT8/INT16 lanes, masks/reductions/dot products, 2:4 sparse metadata, scratchpad, randomized scoreboards, formal verification, compiled bare-metal execution, synthesis, FPGA, and ASIC/OpenLane flows.

## Important sources and commands

| Area | Sources | Current command |
| --- | --- | --- |
| Production scalar | `rtl/core/rv32_core.sv`, `tb/integration/tb_scalar_core.sv` | `make test-scalar-directed` |
| Development pipeline | `rtl/core/rv32_core_pipe.sv`, `tb/integration/tb_scalar_pipe_*.sv` | focused `make test-scalar-pipe-*` targets |
| Repository checks | `scripts/check_repo.py`, `tb/tests/` | `make check`, `make test-repo` |
| Lint | all `rtl/**/*.sv` | `make lint` |
| Subword differential verification | `tb/integration/tb_scalar_differential.sv` | `make test-scalar-diff-subword-directed`, `make test-scalar-diff-subword-random`, `make test-scalar-diff-subword-stall` |

## Environmental blockers

The repository documentation records that a RISC-V bare-metal cross compiler is unavailable locally. No CI configuration or physical-design tool flow is present to validate synthesis/timing/area claims.
