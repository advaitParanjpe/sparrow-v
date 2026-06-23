# Milestone: Scalar vs Dense-Vector vs Sparse-Vector Synthesis and PPA Evaluation

## Objective

Complete Sparrow-V’s hardware-cost evaluation by synthesizing and comparing three controlled processor configurations:

1. scalar baseline;
2. scalar core with dense-vector support;
3. scalar core with dense and 2:4 sparse-vector support.

The milestone must produce reproducible synthesis results and an honest comparison of:

- logic area or cell count;
- register count;
- memory contribution;
- estimated maximum frequency or critical path;
- timing slack at defined clock targets;
- estimated dynamic and leakage power where supported;
- workload latency in cycles;
- area-normalized throughput;
- sparse-feature hardware overhead.

The evaluation must preserve the current verified architecture and workload behavior.

This milestone is an implementation-cost study, not a tapeout claim.

## Baseline

The repository currently contains:

- `rtl/core/rv32_core.sv` as the unchanged scalar reference core;
- `rtl/core/rv32_core_pipe.sv` as the experimental scalar/vector integration core;
- shared scalar/vector command and completion handling;
- one shared vector register file;
- one 256-byte vector scratchpad;
- `VADD8`;
- signed dense `VDOT8`;
- signed compressed 2:4 `VSDOT8`;
- `VLOAD32` and `VSTORE32`;
- precise retirement, exception, reset, backpressure, and wrong-path behavior;
- deterministic synthetic fully connected workload;
- deterministic 16-sample sensor classification fixture;
- reproducible model and sample export;
- scalar, dense-vector, and sparse-vector workload measurements;
- passing scalar, vector, workload, sensor, lint, and repository checks.

Current sensor-workload results per sample are:

- dense: 484 cycles, 109 retired instructions, 16 `VDOT8`;
- sparse: 484 cycles, 109 retired instructions, 16 `VSDOT8`;
- sparse: 32 executed and 32 skipped multiplications;
- dense weight storage: 64 bytes;
- sparse weight plus metadata storage: 38 bytes.

## Relevant Context

Read:

- `AGENTS.md`
- `docs/codex_context.md`
- `docs/current_milestone.md`
- `docs/architecture/scalar_vector_interface.md`
- `docs/architecture/vector_vsdot8.md`
- `docs/architecture/sparse_fc_workload.md`
- `docs/architecture/sensor_workload_export.md`
- `docs/implementation_status.md`
- `docs/verification_plan.md`
- current Makefile synthesis targets;
- current source manifests;
- relevant RTL top-level and vector-engine files;
- any existing Yosys, OpenLane, or OpenROAD configuration.

Read additional files only when required by a concrete synthesis or reporting issue.

## Evaluation Configurations

Create three explicit, reproducible build configurations.

### Configuration A — Scalar baseline

Purpose:

- establish the scalar processor hardware baseline.

Requirements:

- use the repository’s scalar implementation intended for comparison;
- exclude vector register file;
- exclude vector scratchpad;
- exclude vector execution logic;
- exclude `VADD8`, `VDOT8`, `VSDOT8`, `VLOAD32`, and `VSTORE32`;
- include only infrastructure genuinely required by the scalar implementation.

Document which scalar core is used and why.

Do not silently compare unrelated microarchitectures without explaining the limitation.

### Configuration B — Dense vector

Purpose:

- measure the hardware cost of dense-vector execution without sparse-specific logic.

Include:

- scalar/vector interface;
- shared vector register file;
- vector scratchpad;
- `VADD8`;
- `VDOT8`;
- `VLOAD32`;
- `VSTORE32`.

Exclude or compile out:

- `VSDOT8`;
- sparse metadata decode;
- sparse executed/skipped accounting that exists solely for sparse execution.

The dense configuration must remain functionally valid and synthesizable.

### Configuration C — Sparse vector

Purpose:

- measure the complete current Sparrow-V architecture.

Include:

- everything in the dense-vector configuration;
- `VSDOT8`;
- 2:4 metadata decode;
- compressed sparse arithmetic;
- sparse executed/skipped accounting.

This configuration must correspond to the verified sparse workload implementation.

## Configuration Mechanism

Use one clean mechanism for selecting configurations.

Preferred options:

- SystemVerilog parameters;
- documented preprocessor defines;
- separate synthesis wrappers;
- explicit source manifests.

Requirements:

- configuration selection must be deterministic;
- synthesis commands must make the chosen configuration obvious;
- no manual RTL editing between runs;
- no duplicated architectural state;
- no copied and diverging RTL trees.

Do not weaken normal simulation defaults or regressions.

## Functional Preservation

Before collecting synthesis metrics, verify that each configuration is functionally appropriate.

### Scalar baseline

Run a bounded scalar regression.

### Dense vector

Run:

- dense instruction tests;
- vector-memory tests;
- dense workload tests;
- no sparse operation tests.

### Sparse vector

Run:

- complete vector regression;
- synthetic dense/sparse workload;
- sensor dense/sparse workload.

If configuration-specific tests are required, add bounded targets.

Do not claim comparable results from a configuration that does not pass its relevant tests.

## Synthesis Flow

Provide a reproducible open-source synthesis flow using Yosys.

At minimum:

- explicit top module;
- explicit ordered RTL source list;
- explicit configuration defines or parameters;
- consistent synthesis script;
- consistent target technology or generic-cell mapping;
- generated reports stored under a documented results directory.

Use the same synthesis strategy for all three configurations.

Do not compare one generic synthesis result against one technology-mapped result.

## Technology Basis

Choose and document one primary comparison basis.

Preferred:

### Primary comparison

Yosys generic synthesis:

- generic cell count;
- flop count;
- combinational cell count;
- inferred memory information;
- logic-depth or timing proxy where available.

### Secondary comparison

Sky130 or another already available open PDK flow, if practical:

- standard-cell area;
- utilization;
- setup timing;
- critical path;
- power estimate;
- DRC/LVS status if physical implementation is attempted.

If OpenLane/OpenROAD is unavailable, complete the generic synthesis comparison and clearly record the limitation.

Do not block the entire milestone solely because physical-design tools are not installed.

## Clock and Timing Evaluation

Evaluate timing under consistent constraints.

At minimum use:

- one nominal target, preferably 100 MHz or the repository’s established target;
- one relaxed target if the nominal target does not close.

Report:

- target clock period;
- worst slack;
- estimated critical path;
- pass/fail timing status;
- any unclocked or unconstrained path warnings.

Do not claim Fmax directly from one arbitrary target.

If supported, perform a bounded clock sweep to estimate the fastest passing target.

Use the same sweep methodology for dense and sparse configurations.

## Area and Cell Accounting

Report for each configuration:

- total synthesized cells;
- sequential cells;
- combinational cells;
- multiplier-related cells where identifiable;
- mux-related cells where identifiable;
- inferred memory count and width;
- vector register file contribution where identifiable;
- scratchpad contribution where identifiable;
- standard-cell area if mapped.

Also derive:

- dense-vector overhead relative to scalar;
- sparse-vector overhead relative to dense;
- full sparse-vector overhead relative to scalar.

Use both absolute and percentage values.

## Memory Accounting

The vector scratchpad and vector register file may synthesize differently depending on the tool and target.

Document whether each structure becomes:

- inferred memory;
- flip-flops and muxes;
- latch-based memory;
- technology memory macro;
- unsupported black box.

Do not present flip-flop-expanded memory area as equivalent to a realistic SRAM macro without qualification.

Where useful, report:

- logic excluding memory;
- memory bits;
- total mapped result.

## Power Evaluation

If the flow supports a credible estimate, report:

- total estimated power;
- dynamic power;
- leakage power;
- clock assumptions;
- switching-activity assumptions;
- whether activity is vectorless or workload-derived.

If only vectorless estimates are available, label them clearly.

Do not claim measured silicon power or workload energy.

If power estimation is unavailable or unreliable, state that and do not fabricate a value.

## Workload Performance Integration

Combine the existing measured cycle counts with synthesis results.

At minimum report for the synthetic FC workload and sensor workload:

- scalar cycles where available;
- dense-vector cycles;
- sparse-vector cycles;
- target or estimated clock frequency;
- estimated latency;
- retired instructions;
- multiplications executed;
- multiplications skipped;
- weight storage.

Clearly distinguish:

- measured RTL cycle counts;
- synthesis-derived frequency;
- calculated latency.

## Area-Normalized Metrics

Calculate bounded architecture-comparison metrics.

At minimum:

### Throughput proxy

```text
1 / workload latency
```

### Area-normalized throughput proxy

```text
throughput / synthesized area
```

If only generic cell count is available, use:

```text
throughput / generic cell count
```

and label it as a proxy.

Also report:

- cycle speedup relative to scalar;
- instruction reduction relative to scalar;
- sparse arithmetic reduction relative to dense;
- sparse storage reduction relative to dense;
- sparse area overhead relative to dense.

Do not combine incomparable technology or configuration results.

## Key Research Observation

The current dense and sparse workloads have equal cycle counts even though sparse execution halves multiplication work.

The milestone must report this honestly.

Investigate only enough to identify the current reason, such as:

- equal fixed execution latency;
- load count;
- command/completion latency;
- scalar accumulation;
- instruction schedule;
- vector-engine state-machine behavior.

Do not redesign the architecture in this milestone.

Record the finding as a limitation and a future experimental direction.

## Reproducible Commands

Add stable targets following repository conventions, including equivalents of:

```text
synth-scalar
synth-vector-dense
synth-vector-sparse
synth-compare
test-config-scalar
test-config-dense
test-config-sparse
ppa-report
ppa-all
```

Exact names may be adjusted.

One aggregate command must regenerate the final comparison reports.

Example:

```text
make ppa-all
```

The aggregate target must:

1. validate required tools;
2. synthesize all three configurations;
3. extract metrics;
4. generate a machine-readable report;
5. generate a human-readable comparison table;
6. fail clearly on missing or malformed results.

## Results Artifacts

Generate deterministic results under a documented directory, for example:

```text
results/ppa/
```

Include:

- raw Yosys reports;
- source manifests;
- synthesis logs or concise report extracts;
- machine-readable JSON or CSV summary;
- Markdown comparison report;
- tool-version information;
- configuration metadata;
- clock constraints.

Do not commit huge temporary tool directories or unnecessary intermediate files.

Choose and document which result artifacts are tracked.

## Machine-Readable Summary

Generate a JSON or CSV summary containing at least:

- configuration name;
- top module;
- defines or parameters;
- tool version;
- target technology;
- target clock;
- timing slack;
- cell count;
- sequential cells;
- combinational cells;
- memory bits;
- mapped area if available;
- estimated power if available;
- workload cycles;
- estimated latency;
- area-normalized throughput proxy.

Repository-relative paths only.

## Human-Readable Comparison

Produce one primary table:

| Metric | Scalar | Dense Vector | Sparse Vector |
|---|---:|---:|---:|
| Total cells or area | | | |
| Sequential cells | | | |
| Combinational cells | | | |
| Memory bits | | | |
| Target clock | | | |
| Worst slack | | | |
| Timing status | | | |
| Estimated power | | | |
| FC workload cycles | | | |
| Sensor workload cycles | | | |
| Retired instructions | | | |
| Multiplies executed | | | |
| Multiplies skipped | | | |
| Weight storage | | | |
| Area-normalized throughput | | | |

Use `N/A` rather than inventing unavailable values.

## Documentation Requirements

Add a synthesis and PPA evaluation document.

Document:

- all three configurations;
- exact source and define differences;
- synthesis flow;
- tool versions;
- technology assumptions;
- clock constraints;
- memory-inference behavior;
- area results;
- timing results;
- power assumptions;
- workload integration;
- area-normalized metrics;
- sparse overhead;
- limitations;
- future optimization opportunities.

Update:

- `docs/implementation_status.md`;
- `docs/verification_plan.md`;
- `docs/milestone_history.md`;
- README with stable commands and headline results only after validation.

Do not claim signoff readiness, tapeout readiness, or physical closure unless actually achieved.

## Out of Scope

Do not implement:

- new vector instructions;
- sparse-load instructions;
- fused operations;
- wider vectors;
- caches;
- DMA;
- AXI;
- operating system support;
- compiler backend;
- new ML models;
- new training pipeline;
- timing-driven RTL redesign;
- broad retiming;
- floorplan experimentation beyond one bounded baseline;
- signoff extraction;
- real silicon power;
- tapeout claims;
- changes to `rtl/core/rv32_core.sv`.

## Focused Validation

Add focused checks for:

### Configuration manifests

- scalar excludes vector logic;
- dense excludes sparse logic;
- sparse includes all intended logic;
- no testbench or simulation-only files enter synthesis;
- source order is deterministic.

### Synthesis reports

- all expected reports exist;
- no configuration silently uses the wrong top;
- no unintended black boxes;
- no latches unless deliberately documented;
- no synthesis fatal errors;
- metrics parse correctly.

### Comparison script

- handles all three configurations;
- rejects missing fields;
- preserves units;
- calculates percentages correctly;
- labels unavailable metrics as `N/A`;
- produces deterministic output.

### Functional preservation

- scalar configuration tests pass;
- dense configuration tests pass;
- sparse configuration tests pass;
- previous workload and sensor tests remain passing.

## Final Acceptance Regression

During development, run only focused configuration and synthesis targets.

After implementation is stable, run once:

```text
make test-config-scalar
make test-config-dense
make test-config-sparse
make ppa-all
make test-workload-all
make test-sensor-all
make test-vector-regression
make test-full-regression
make lint
make check
make docs-check
git diff --check
```

If physical-design tools are available, also run the documented bounded physical-flow target.

## Acceptance Criteria

The milestone is complete only when:

1. Three explicit hardware configurations exist.
2. Scalar, dense-vector, and sparse-vector configurations are reproducible.
3. No manual RTL editing is required between configurations.
4. Scalar excludes vector hardware.
5. Dense includes dense-vector hardware.
6. Dense excludes sparse-specific hardware.
7. Sparse includes complete VSDOT8 support.
8. Relevant functional tests pass for all configurations.
9. One consistent Yosys synthesis flow exists.
10. All configurations use the same synthesis methodology.
11. Source manifests are explicit and deterministic.
12. Simulation-only files are excluded.
13. Synthesis succeeds for all three configurations.
14. No unintended black boxes remain.
15. Total cell or area metrics are reported.
16. Sequential and combinational metrics are reported.
17. Memory bits and inference behavior are reported.
18. Dense overhead relative to scalar is calculated.
19. Sparse overhead relative to dense is calculated.
20. Sparse overhead relative to scalar is calculated.
21. One consistent clock constraint is used.
22. Timing results are reported for all configurations.
23. Timing failures are reported honestly.
24. Estimated Fmax is not overstated.
25. Power is reported only if credibly available.
26. Power assumptions are documented.
27. Existing workload cycles are integrated.
28. Estimated workload latency is calculated consistently.
29. Area-normalized throughput proxy is reported.
30. Measured and derived values are distinguished.
31. Equal dense/sparse cycle counts are reported honestly.
32. The reason for equal latency is identified at a bounded level.
33. Machine-readable summary exists.
34. Human-readable comparison exists.
35. Tool versions are recorded.
36. Reproduction commands are documented.
37. Previous synthetic workload remains passing.
38. Sensor workload remains passing.
39. Existing scalar and vector regressions remain passing.
40. No new ISA or broad RTL optimization is added.
41. `rtl/core/rv32_core.sv` remains unchanged.
42. Codex creates no commit or push.
43. `docs/codex_milestone_result.md` is finalized.

## Stop Conditions

Stop for human review only if:

- a clean scalar/dense/sparse configuration split requires major architectural restructuring;
- the dense and sparse implementations cannot be isolated without duplicating state;
- synthesis reveals an unintended latch or combinational loop requiring broad RTL redesign;
- all available synthesis flows fail on valid SystemVerilog despite bounded frontend fixes;
- timing analysis is impossible because the design lacks a definable clock boundary;
- the chosen scalar baseline is fundamentally incomparable to the vector configurations;
- a likely existing functional correctness issue is discovered;
- physical-flow work would require major RTL redesign.

Ordinary synthesis-script bugs, define problems, parser issues, report extraction bugs, and documentation work are not stop conditions.

## Required Result File

Update:

```text
docs/codex_milestone_result.md
```

throughout the run.

Finalize it with:

- `STATUS: COMPLETE`, `STATUS: FAILED`, or `STATUS: BLOCKED`;
- configuration definitions;
- synthesis tool and version;
- target technology;
- clock constraints;
- exact area or cell metrics;
- timing results;
- power results or explicit unavailability;
- workload latency calculations;
- sparse overhead;
- area-normalized metrics;
- exact commands and outcomes;
- changed files;
- remaining limitations;
- whether physical implementation was run;
- confirmation that previous workload and sensor regressions pass;
- confirmation that `rtl/core/rv32_core.sv` is unchanged;
- confirmation that no commit or push occurred.