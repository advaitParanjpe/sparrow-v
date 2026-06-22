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
- Pipeline store-retirement trace repair: `rv32_core_pipe` now holds stores until the sole data response handshakes and emits one retirement event with the effective byte address, unshifted scalar data, and lane-positioned strobe. `make test-scalar-pipe-store-retire` checks SB offsets 0–3, SH offsets 0/2, SW, response delay, request backpressure, reset, a killed wrong-path store with no request/retirement/memory effect, and a valid target-path store with one retirement and memory effect; the normalized differential harness compares retirement-store events separately from accepted requests in modes 0–3 and detects a controlled address corruption.
- Production-readiness conclusion: **C. Do not promote** `rv32_core_pipe`. The store-retirement interface blocker is repaired, but formal equivalence, coverage closure, synthesis/PPA evidence, and broad verification are still absent. `rv32_core.sv` remains production/reference.
- Scalar interface v1 and the human-approved vector command/completion and separate memory boundary are specified in `docs/architecture/scalar_interface_freeze.md` and `docs/architecture/scalar_vector_interface.md`. No scalar promotion was performed.
- Experimental scalar/vector protocol integration: `rv32_core_pipe` directly
  exposes the v1 command/completion ports and `rtl/vector/rv32_vec_stub_engine.sv`
  provides a latency-3 test endpoint. Custom-0 `funct3=000/001/010` exercise
  scalar-result success, vector-only success, and precise exception. Focused
  tests cover command/completion backpressure, one outstanding command,
  reset cancellation, wrong-path suppression, exact-once events, and scalar
  forward progress. `rtl/vector/rv32_vec_vadd_engine.sv` now adds a real
  32x32-bit vector register file and Custom-0 `funct3=011` four-lane wrapping
  INT8 `VADD8`, committing one vector write only on completion handshake.
  Directed, alias, command/completion-backpressure, reset, wrong-path, and
  deterministic 32-operation golden-model tests are available through
  `make test-vector-vadd-all`; the stub coverage is retained. There is still
  no vector-memory interface or sparse implementation; the pipe remains
  experimental and `rv32_core.sv` remains production/reference.

## Planned, not implemented

Vector ISA expansion, vector memory, INT16 lanes, masks/reductions/dot products, 2:4 sparse metadata, scratchpad, formal verification, compiled bare-metal execution, synthesis, FPGA, and ASIC/OpenLane flows.

## Important sources and commands

| Area | Sources | Current command |
| --- | --- | --- |
| Production scalar | `rtl/core/rv32_core.sv`, `tb/integration/tb_scalar_core.sv` | `make test-scalar-directed` |
| Development pipeline | `rtl/core/rv32_core_pipe.sv`, `tb/integration/tb_scalar_pipe_*.sv` | focused `make test-scalar-pipe-*` targets |
| Repository checks | `scripts/check_repo.py`, `tb/tests/` | `make check`, `make test-repo` |
| Lint | all `rtl/**/*.sv` | `make lint` |
| Subword differential verification | `tb/integration/tb_scalar_differential.sv` | `make test-scalar-diff-subword-directed`, `make test-scalar-diff-subword-random`, `make test-scalar-diff-subword-stall` |
| Pipeline store-retirement verification | `tb/integration/tb_scalar_pipe_store_retire.sv`, `tb/integration/tb_scalar_differential.sv` | `make test-scalar-pipe-store-retire`, `make test-scalar-diff-store-retire` |

## Environmental blockers

The repository documentation records that a RISC-V bare-metal cross compiler is unavailable locally. No CI configuration or physical-design tool flow is present to validate synthesis/timing/area claims.
