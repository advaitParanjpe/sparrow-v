# Sparrow-V: Sparse-Aware RISC-V Edge Processor

## Project purpose

Sparrow-V is a planned compact RV32I processor with a tightly coupled custom vector engine for sparse, quantized AI and IoT workloads. Its central research question is whether a programmable CPU/vector architecture can approach fixed-function accelerator efficiency while retaining flexible software control.

## Current phase

**Experimental scalar/vector evaluation.** The protected scalar reference core
remains the production/reference implementation. The experimental pipeline has
dense and 2:4 sparse vector execution, a 32-register vector file, and a
256-byte scratchpad. Generic-Yosys comparison evidence is available; it is not
physical timing, power, or tapeout evidence.

## Planned subsystems

- Single-issue in-order RV32I scalar core.
- Compact custom vector ISA, separate vector register state, and INT8/INT16 execution.
- Dense arithmetic, dot/reduction, masking, and later 2:4 sparse dot-product execution.
- Shared four-bank software-managed scratchpad for scalar and vector data access.
- Bare-metal runtime, assembly/intrinsic helpers, Python model/export tools, and an IoT inference demonstration.
- Layered directed, randomized, assertion, scoreboard, synthesis, and implementation flows.

Sparrow-V is a programmable CPU/vector architecture, not another fixed-function tinyNPU-style matrix accelerator.

## Repository layout

- `sparrow-v-project-plan/` — preserved original planning source material.
- `rtl/` — future synthesizable SystemVerilog, organized by core, vector, memory, interface, common, and top-level logic.
- `tb/` — future unit, integration, assertion, model, and test assets.
- `sw/`, `python/`, `scripts/` — future bare-metal software, reference-model/export code, and automation.
- `synth/`, `constraints/`, `fpga/`, `openlane/` — future implementation flows and constraints.
- `docs/` — architecture records, verification/software documentation, reports, and decision records.

## Expected toolchain

Checks require Python 3, GNU Make, Icarus Verilog, and Verilator. A RISC-V bare-metal compiler is needed to build `sw/tests/scalar_smoke.S`; this environment does not currently provide one. Later phases plan Vivado, Yosys, and OpenLane/OpenROAD.

## Initial commands

```sh
make check
make docs-check
make status
make test
make sim-scalar
make test-scalar-diff-subword-directed
make test-scalar-diff-subword-random
make test-scalar-pipe-store-retire
make test-scalar-diff-store-retire
make test-scalar-pipe-vec-stub-all
make test-full-regression
make ppa-all
make test-config-scalar
make test-config-dense
make test-config-sparse
```

`check-scalar-throughput-experiment` (legacy alias `test-scalar-pipeline`) is a non-blocking historical Phase 1.7 experiment. It instantiates the production/reference core and intentionally fails its sustained-throughput target; it is not a required correctness regression.

## Milestone workflow

Define a concise milestone externally, place it in
`docs/current_milestone.md`, and commit that definition. Run
`./scripts/run_milestone.sh` from the repository root for one primary Codex
implementation session. Review `docs/codex_milestone_result.md` and the Git diff;
ask for a focused repair only when there is a concrete finding. A separate
read-only Codex completion audit is not the normal path. Human review and a
manual commit remain required.

The planning source manifest is [docs/source_manifest.md](docs/source_manifest.md). Architectural choices that still require approval are tracked in [docs/architecture/open_questions.md](docs/architecture/open_questions.md) and `docs/decisions/`.

The reproducible generic synthesis comparison and its limitations are in
[docs/architecture/synthesis_ppa_evaluation.md](docs/architecture/synthesis_ppa_evaluation.md).
