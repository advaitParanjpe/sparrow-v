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
- The same sole vector-register owner implements experimental Custom-0
  `funct3=100` `VDOT8 rd, vs1, vs2`: four explicitly signed INT8 products
  accumulate exactly into a scalar 32-bit completion result. It never writes a
  vector register; scalar writeback occurs only after completion acceptance.
  `make test-vector-vdot-all` covers signed extremes, x0, dependent scalar
  use, command/completion backpressure, reset, redirect suppression, invalid
  encoding, and 32 deterministic golden-model cases (seed `0x2468ace1`).
- Experimental vector memory is implemented in that same owner: a 256-byte
  little-endian scratchpad and Custom-0 `VLOAD32`/`VSTORE32` (`funct3=101/110`).
  Addressing is scalar base plus signed 12-bit offset; aligned words from 0 to
  252 succeed, and misalignment/range-or-wrap complete precisely with causes
  16/17. Loads and stores commit only at successful completion handshake.
  `make test-vector-vmem-all` covers directed ordering/dependencies, command
  and completion backpressure, reset, redirect, misalignment, and a 24-case
  deterministic golden-model sequence (seed `0x1234abcd`).

- Experimental `VSDOT8` uses Custom-0 `funct3=111`, two compressed signed
  INT8 weights, six 2-of-4 patterns, precise cause 18 invalid metadata, and
  completion-gated two-executed/two-skipped debug accounting. `make
  test-vector-vsdot-all` covers directed dense equivalence, stalls, reset,
  redirect, invalid patterns, and 96 deterministic random cases (seed
  `0x5a17c0de`).
- A generated bare-metal 16-input/four-output quantized fully connected
  workload now executes through the experimental pipeline in scalar software
  multiply, dense `VDOT8`, and 2:4 `VSDOT8` forms. All report
  `[382,-446,-246,1054]`; exact layout, encodings, and measured counters are
  in `docs/architecture/sparse_fc_workload.md`, with focused targets
  `make test-workload-{encoder,golden,scalar,dense,sparse,compare,all}`.
- A separate deterministic sensor-classification deployment fixture validates a
  stable JSON model/sample format, projects dense INT8 weights to legal 2:4
  `VSDOT8` groups, emits ignored reproducible data/program images and JSON
  manifest/report artifacts, and runs 16 samples independently in dense and
  sparse modes through `rv32_core_pipe`. `make test-sensor-workload` verifies
  logits, predictions, completion, vector retirement counts, and sparse
  execute/skip events. This is fixture accuracy only; it is not a public
  dataset or general model-quality claim.

## Planned, not implemented

Vector ISA expansion, INT16 lanes, masks, configurable reductions beyond fixed
VDOT8, scratchpad banking, external memory interfaces, DMA, vector lengths
beyond 32 bits, gather/scatter, formal verification, synthesis, FPGA, and
ASIC/OpenLane flows. Generic Yosys PPA comparison is now implemented; physical
area, STA, power, FPGA, and ASIC/OpenLane evidence remain unavailable.

## Generic synthesis evaluation

- `make ppa-all` runs one deterministic Yosys generic `cmos2` mapping flow for
  protected scalar, dense-vector, and sparse-vector synthesis tops. Ordered
  manifests, machine-readable JSON, and a Markdown comparison are generated
  under ignored `results/ppa/`.
- Current generic counts are scalar 14,029, dense 62,928, and sparse 65,691
  cells. Sparse adds 2,763 cells (4.39%) over dense. The vector file and
  scratchpad total 3,072 bits and are flip-flop/mux mapped, not SRAM macros.
- No characterized library or switching activity is installed. Slack, Fmax,
  mapped area, and power remain explicitly unavailable; logic depth is only a
  Yosys structural proxy. See
  [synthesis PPA evaluation](architecture/synthesis_ppa_evaluation.md).

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
