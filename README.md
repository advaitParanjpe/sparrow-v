# Sparrow-V: Sparse-Aware RISC-V Edge Processor

Sparrow-V is a compact RV32I-based edge processor project that couples an experimental scalar pipeline to a four-lane INT8 vector engine with 2:4 structured-sparse dot products.

## Project purpose

The project asks a focused hardware/software co-design question: for a small
fully connected INT8 workload, what changes when scalar software is replaced
by dense vector dot products and then by compressed 2:4 sparse dot products?
It demonstrates exact bare-metal inference and reports functional, storage,
arithmetic, and generic-synthesis evidence without presenting itself as a full
RVV implementation or a production ASIC.

## Current phase

**Final experimental integration release.** `rtl/core/rv32_core.sv` is the
protected production/reference RV32I core. `rtl/core/rv32_core_pipe.sv` is the
separately verified but experimental scalar/vector integration core. The latter
owns a 32 x 32-bit vector register file and a 256-byte vector scratchpad
through its vector endpoint; neither is scalar data memory.

## Planned subsystems

The implemented scope is intentionally bounded: RV32I scalar execution,
Custom-0 experimental vector commands, four INT8 lanes, a vector scratchpad,
and deterministic workload/export tooling. Future work, not current features,
includes compressed data movement, fused sparse operations, SRAM mapping,
physical implementation, wider vectors, and compiler integration.

## Why the three paths matter

The same 16-input, four-output fully connected layer produces
`[382, -446, -246, 1054]` in all paths. Scalar code takes 7,399 cycles and
3,948 retired instructions; both vector paths take 484 cycles and 109 retired
instructions. Sparse execution preserves the fixed command latency of dense
execution, so it does not reduce cycle count yet; it executes 32 rather than
64 INT8 multiplies and reduces weight-plus-metadata storage from 64 to 38
bytes (40.625%). See the canonical [results](docs/final_results.md).

## Architecture

The reference scalar core remains independent. The experimental pipe issues a
single blocking, in-order vector command and resumes only after its completion.
The vector engine is the sole owner of vector registers and scratchpad state.
`VADD8` writes a vector register; `VDOT8` and `VSDOT8` return a signed 32-bit
scalar result at completion. `VLOAD32` and `VSTORE32` move aligned words
between scalar-addressed operands and the vector-only scratchpad.

The [architecture overview](docs/architecture.md) includes a repository-native
Mermaid diagram and the sparse dataflow figure. Interface, instruction, and
memory details remain in the linked architecture documents.

## Custom instruction summary

All encodings use RISC-V Custom-0 (`opcode 0x0b`) and are experimental, not a
final ISA or RVV subset.

| Operation | `funct3` | Effect |
| --- | ---: | --- |
| `VADD8 vd, vs1, vs2` | `011` | Four wrapping INT8 lane adds; vector result. |
| `VDOT8 rd, vs1, vs2` | `100` | Four signed INT8 products accumulated to scalar `rd`. |
| `VLOAD32 vd, off(rs1)` | `101` | Aligned little-endian word from vector scratchpad. |
| `VSTORE32 vs, off(rs1)` | `110` | Aligned little-endian word to vector scratchpad. |
| `VSDOT8 rd, va, vw, pattern` | `111` | Two selected signed INT8 products from one 2:4 group. |

## Verification summary

Directed and deterministic randomized tests cover scalar behavior, vector
arithmetic, sparse metadata exceptions, command and completion backpressure,
reset cancellation, wrong-path suppression, scalar dependencies, vector
memory, workloads, and sensor fixtures. The final aggregate command is
`make test-full-regression`; detailed coverage, seeds, and case counts are in
the [verification summary](docs/verification_plan.md).

## Software and workload flow

`scripts/workload_fc.py` independently encodes and models the fixed fully
connected workload in scalar, dense, and sparse forms. `scripts/sensor_workload.py`
validates checked-in model/sample JSON, projects sparse weights deterministically,
and emits ignored simulation images. Each of 16 sensor samples runs separately
through dense and sparse RTL; both paths classify all 16 fixture samples
correctly, with zero disagreements. This is fixture accuracy, not a dataset
accuracy claim.

## Headline implementation-cost result

Generic Yosys 0.66 `cmos2` mapping reports 14,029 scalar, 62,928 dense-vector,
and 65,691 sparse-vector cells. Sparse support adds 2,763 cells (4.39%) over
dense. The vector file and scratchpad map to generic flip-flops and muxes, not
SRAM macros; no standard-cell timing, physical implementation, or power result
is claimed.

## Quick start

Prerequisites are GNU Make, Python 3, Icarus Verilog, Verilator, and Yosys for
PPA generation. Run this reviewer path from the repository root:

```sh
make check
make test-vector-vsdot-all
make test-workload-all
make test-sensor-all
make ppa-all
```

For the complete reproducibility path, expected outputs, generated-artifact
policy, and final regression command, read the [reproduction guide](docs/reproduction.md).

## Expected toolchain

GNU Make, Python 3, Icarus Verilog, and Verilator are required for the normal
checks. Yosys is additionally required for `make ppa-all`. The documented
flows do not require a RISC-V cross compiler.

## Initial commands

```sh
make help
make check
make test-vector-vsdot-all
make test-workload-all
make test-sensor-all
make ppa-all
```

Use `make test-full-regression` for final aggregate validation. The complete
sequence and expected outputs are in the [reproduction guide](docs/reproduction.md).

## Repository layout

- `rtl/core/` — reference scalar core and experimental scalar/vector pipe.
- `rtl/vector/` — vector engine, register file, scratchpad, and stub endpoint.
- `rtl/top/`, `synth/`, `config/` — synthesis wrappers, manifests, and PPA configuration.
- `tb/` — directed, deterministic randomized, differential, workload, and sensor testbenches.
- `scripts/`, `python/` — encoders, golden models, sensor export, repository checks, and PPA flow.
- `docs/` — architecture, verification, final results, reproduction, and release-readiness records.
- `sparrow-v-project-plan/` — preserved original planning material.

The categorized [source manifest](docs/source_manifest.md) is the definitive
tracked-file map.

## Limitations

The scalar/vector pipe is experimental; Sparrow-V is not full RVV. Vectors are
fixed at 32 bits, only one command may be outstanding, and dense/sparse
commands have the same fixed latency. There is no compressed sparse-load
instruction, full compiler backend, SRAM macro implementation, physical timing
closure, or measured power. See [final results](docs/final_results.md) for the
complete claim boundary.

## Future research directions

Useful next studies are packed sparse loads and compressed data movement,
fused sparse operations, latency crossover analysis, layer-adaptive structured
sparsity and hardware-aware pruning, SRAM-backed physical implementation,
larger real datasets, and SparrowML integration. None are implemented here.

## CV-ready project summary

Designed and verified an RV32I edge-processor research prototype with a
tightly coupled INT8 vector engine and compressed 2:4 sparse dot product;
ran exact scalar/dense/sparse bare-metal inference and a 16-sample sensor
fixture; measured 32 skipped sparse multiplies and 40.625% weight-plus-metadata
storage reduction, alongside a 4.39% generic sparse-over-dense cell overhead.
The primary limitation is that the vector pipeline remains experimental and
the PPA study is generic synthesis rather than physical implementation.
