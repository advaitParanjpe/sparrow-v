# Implementation Status

## Implemented and verified

- Protected production/reference RV32I core: `rtl/core/rv32_core.sv`.
- Experimental `rv32_core_pipe` scalar/vector integration with a blocking,
  in-order command/completion boundary; it remains unpromoted.
- One vector-engine owner with 32 writable 32-bit vector registers and a
  separate 256-byte little-endian vector scratchpad.
- Experimental Custom-0 `VADD8`, signed `VDOT8`, compressed 2:4 signed
  `VSDOT8`, `VLOAD32`, and `VSTORE32`; successful effects commit on completion
  handshake, while reset and wrong-path work are suppressed.
- Deterministic scalar/dense/sparse fully connected workload and 16-sample
  dense/sparse sensor fixture export and execution, plus a fixed-shape,
  versioned external 16-input/four-output dense or 2:4 sparse sensor-workload
  interface that runs the existing RTL in an isolated workspace.
- Generic Yosys PPA flow with protected scalar, dense-vector, and sparse-vector
  configurations. Current reproducible totals are 14,029, 62,928, and 65,691
  cells; sparse is 2,763 cells (4.39%) over dense.

## Verification status

Focused tests cover scalar behavior, command and completion backpressure,
reset, redirects, precise errors, vector arithmetic, vector memory, sparse
metadata, deterministic random models, workload execution, and sensor
execution. Aggregate commands are `make test-scalar-regression`, `make
test-vector-regression`, and `make test-full-regression`. Seeds and case counts
are recorded in [verification_plan.md](verification_plan.md).

## Deliberate limits

`rv32_core_pipe` is experimental. Sparrow-V is not a full RVV processor and
has fixed 32-bit vectors, one outstanding vector command, fixed dense/sparse
latency, no compressed sparse-load instruction, no full compiler backend, no
SRAM macro mapping, no physical timing closure, and no measured power. Sensor
results are fixture accuracy only. The canonical metrics and claim boundary are
in [final_results.md](final_results.md).
