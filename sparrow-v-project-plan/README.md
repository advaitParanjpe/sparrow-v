# Sparrow-V: Sparse-Aware RISC-V Edge Processor

Sparrow-V is a compact RV32I processor with a tightly coupled custom vector engine for sparse, quantized AI and IoT workloads.

The project investigates whether a small programmable vector CPU can approach the efficiency of a fixed-function accelerator while retaining software flexibility.

## Core idea

Sparrow-V combines:

- a compact RV32I scalar core;
- a small custom vector ISA rather than full RISC-V Vector Extension support;
- a four-lane INT8/INT16 vector execution engine;
- vector loads, stores, arithmetic, dot products, reductions, and masking;
- 2:4 structured-sparsity metadata decoding and sparse dot-product execution;
- a banked scratchpad memory;
- bare-metal C and lightweight assembly/intrinsic support;
- a Python quantization, pruning, export, and golden-model flow;
- an end-to-end IoT inference application;
- randomized RTL verification, assertions, scoreboards, and regression automation;
- FPGA synthesis and ASIC-style Yosys/OpenLane evaluation.

## Main research question

> Can a small sparse-aware vector CPU approach fixed-function accelerator efficiency while preserving programmability for edge AI and IoT workloads?

## Planned comparisons

1. Scalar RV32I execution.
2. Dense vector execution.
3. Sparse-aware vector execution.
4. Optional comparison against tinyNPU as a fixed-function accelerator baseline.

## Primary metrics

- execution cycles;
- retired scalar and vector instructions;
- vector-lane utilization;
- memory traffic;
- dense operations performed;
- sparse operations skipped;
- scratchpad bank-conflict stalls;
- area;
- maximum clock frequency;
- estimated power;
- throughput per unit area.

## Documentation map

- `docs/01_project_charter.md` — goals, scope, non-goals, success criteria.
- `docs/02_system_architecture.md` — top-level microarchitecture.
- `docs/03_scalar_core.md` — RV32I scalar-core requirements.
- `docs/04_vector_isa.md` — custom vector ISA proposal.
- `docs/05_vector_microarchitecture.md` — vector datapath and control.
- `docs/06_sparse_execution.md` — 2:4 sparsity format and execution rules.
- `docs/07_memory_system.md` — scratchpad and load/store architecture.
- `docs/08_extension_interface.md` — scalar-to-vector issue and completion interface.
- `docs/09_software_toolchain.md` — compiler, runtime, exporter, and model flow.
- `docs/10_verification_plan.md` — testbench, assertions, scoreboards, and coverage.
- `docs/11_benchmarks_and_evaluation.md` — workloads and evaluation methodology.
- `docs/12_repo_structure.md` — intended repository organization.
- `docs/13_build_roadmap.md` — phased implementation plan.
- `docs/14_coding_and_design_rules.md` — RTL and software conventions.
- `docs/15_acceptance_criteria.md` — completion gates for every phase.
- `docs/16_risks_and_tradeoffs.md` — major technical risks and fallback plans.
- `docs/17_open_questions.md` — decisions Codex must not silently invent.
- `prompts/codex_initial_build_prompt.md` — first implementation prompt.

## Recommended starting point

Do not begin by implementing the sparse vector unit. First establish:

1. repository skeleton and CI-style checks;
2. a minimal RV32I scalar core that runs hand-authored instruction tests;
3. a clean scalar-to-vector extension interface;
4. a standalone vector reference model and vector-unit testbench;
5. dense vector instructions;
6. sparse execution only after the dense path is stable.

## Project positioning

Sparrow-V should remain distinct from tinyNPU:

- **tinyNPU:** fixed-function matrix accelerator with memory-mapped control and ASIC flow.
- **Sparrow-V:** programmable CPU with custom vector and sparse execution for AI/IoT software.

