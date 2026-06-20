# Sparrow-V: Sparse-Aware RISC-V Edge Processor

## Project purpose

Sparrow-V is a planned compact RV32I processor with a tightly coupled custom vector engine for sparse, quantized AI and IoT workloads. Its central research question is whether a programmable CPU/vector architecture can approach fixed-function accelerator efficiency while retaining flexible software control.

## Current phase

**Phase 0 — repository and specification freeze.** RTL implementation has not started. There are no functional CPU, vector, sparse, memory, simulation, synthesis, FPGA, or ASIC results in this repository.

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

Phase 0 checks require Python 3 standard library and GNU Make. Later phases plan to use a RISC-V bare-metal toolchain, Verilator and/or Icarus Verilog, Vivado, Yosys, and OpenLane/OpenROAD; none is required or claimed usable yet.

## Initial commands

```sh
make check
make docs-check
make status
make test
```

The planning source manifest is [docs/source_manifest.md](docs/source_manifest.md). Architectural choices that still require approval are tracked in [docs/architecture/open_questions.md](docs/architecture/open_questions.md) and `docs/decisions/`.
