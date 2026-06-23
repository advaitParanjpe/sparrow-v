# Milestone: Final Integration, Documentation, and Portfolio Release

## Objective

Finish Sparrow-V as a complete, reproducible, portfolio-ready processor project without adding new architectural features.

The milestone must consolidate the existing implementation, verification, software, workload, sensor-export, and synthesis results into one coherent final release.

The final repository must make it easy for a reviewer to understand:

- what Sparrow-V is;
- why it was built;
- how the scalar, dense-vector, and sparse-vector paths differ;
- what was implemented;
- how it was verified;
- how to reproduce the primary demonstrations;
- what the measured results are;
- what limitations remain;
- which claims are supported and which are not.

This milestone is for integration and polish.

Do not add new ISA operations, processor features, ML functionality, or speculative optimization work.

## Baseline

Sparrow-V currently includes:

- an RV32I scalar reference core;
- an experimental pipelined scalar/vector core;
- a blocking, in-order scalar/vector command-completion interface;
- a 32 × 32-bit vector register file;
- a 256-byte vector scratchpad;
- `VADD8`;
- signed dense `VDOT8`;
- compressed 2:4 signed `VSDOT8`;
- `VLOAD32` and `VSTORE32`;
- precise retirement, exceptions, reset cancellation, backpressure, and wrong-path suppression;
- deterministic instruction and workload generation;
- scalar, dense-vector, and sparse-vector fully connected workloads;
- 16-sample sensor-model deployment;
- dense and sparse storage and arithmetic accounting;
- scalar, dense, and sparse synthesis configurations;
- generic Yosys synthesis and PPA comparison;
- passing scalar, vector, workload, sensor, lint, documentation, and repository checks.

Verified headline results include:

### Functional workload

All scalar, dense-vector, and sparse-vector implementations produce:

```text
[382, -446, -246, 1054]
```

### Performance

| Metric | Scalar | Dense Vector | Sparse Vector |
|---|---:|---:|---:|
| Cycles | 7,399 | 484 | 484 |
| Retired instructions | 3,948 | 109 | 109 |
| Dot-product instructions | 0 | 16 VDOT8 | 16 VSDOT8 |
| Multiplications executed | 64 software multiplies | 64 | 32 |
| Multiplications skipped | 0 | 0 | 32 |

### Sensor fixture

- 16 deterministic samples;
- four classes: normal, inner, outer, ball;
- dense fixture accuracy: 16/16;
- sparse fixture accuracy: 16/16;
- prediction disagreements: 0.

These are fixture results, not general dataset-accuracy claims.

### Storage

- dense weights: 64 bytes;
- sparse compressed weights: 32 bytes;
- sparse metadata: 6 bytes;
- sparse total: 38 bytes;
- reduction including metadata: 40.625%.

### Generic synthesis

Using Yosys 0.66 with generic `cmos2` mapping:

| Configuration | Total Cells |
|---|---:|
| Scalar | 14,029 |
| Dense Vector | 62,928 |
| Sparse Vector | 65,691 |

Sparse-specific incremental overhead over dense:

```text
2,763 cells
4.39%
```

The vector register file and scratchpad are currently mapped as flip-flops and muxes rather than SRAM macros.

No standard-cell timing, physical implementation, signoff power, or tapeout claim exists.

## Relevant Context

Read:

- `AGENTS.md`
- `README.md`
- `docs/codex_context.md`
- `docs/current_milestone.md`
- `docs/implementation_status.md`
- `docs/verification_plan.md`
- `docs/milestone_history.md`
- `docs/source_manifest.md`
- `docs/architecture/scalar_vector_interface.md`
- `docs/architecture/vector_vadd8.md`
- `docs/architecture/vector_vsdot8.md`
- `docs/architecture/vector_memory.md`
- `docs/architecture/sparse_fc_workload.md`
- `docs/architecture/sensor_workload_export.md`
- `docs/architecture/synthesis_ppa_evaluation.md`
- relevant Makefile targets;
- relevant workload, sensor, and PPA scripts;
- repository tree and tracked files.

Read other files only when required to resolve a concrete documentation, reproducibility, or cleanup issue.

## Core Principle

The final repository must tell one coherent story:

> Sparrow-V is a compact RV32I-based edge processor with a tightly coupled INT8 vector engine and compressed 2:4 structured-sparse execution. It demonstrates exact bare-metal inference, multi-sample model deployment, and scalar-versus-dense-versus-sparse hardware evaluation.

The final polish must not exaggerate the project into:

- a full RVV processor;
- a production-ready CPU;
- a timing-closed ASIC;
- a tapeout-ready design;
- a full ML compiler;
- a general sparse inference framework;
- a measured-energy result.

## In Scope

### 1. Final README

Rewrite or substantially polish the README so that it functions as the primary project landing page.

It must include:

1. project title and one-sentence summary;
2. motivation and architectural question;
3. major implemented features;
4. architecture overview;
5. custom instruction summary;
6. verification summary;
7. software and workload flow;
8. headline results;
9. reproduction commands;
10. repository structure;
11. limitations;
12. future research directions.

The README must be readable by:

- RTL engineers;
- CPU/microarchitecture reviewers;
- hardware-acceleration reviewers;
- HW–SW co-design reviewers.

Avoid excessive implementation detail on the first screen.

### 2. Architecture Overview

Add or polish one final architecture overview document.

It must describe:

- scalar pipeline;
- scalar/vector interface;
- vector register file;
- scratchpad;
- dense dot-product path;
- sparse metadata decode;
- compressed two-weight representation;
- command/completion flow;
- scalar result writeback;
- architectural state ownership.

Use consistent naming across all documents.

### 3. Architecture Diagram

Create one repository-native architecture diagram.

Preferred formats:

- Mermaid embedded in Markdown;
- SVG generated from a checked-in source;
- another text-based reproducible diagram.

The diagram should show:

- scalar pipeline;
- command interface;
- vector engine;
- vector register file;
- scratchpad;
- VADD8;
- VDOT8;
- VSDOT8;
- scalar result path;
- memory/data movement.

Do not depend on a proprietary diagram source that cannot be regenerated.

### 4. Sparse Dataflow Diagram

Add one concise diagram or figure showing:

- four activation lanes;
- two compressed weights;
- 3-bit metadata;
- selected lane pair;
- two executed multiplications;
- two skipped multiplications;
- signed 32-bit scalar result.

The mapping between metadata and selected lanes must be clear.

### 5. Final Results Summary

Create one canonical final-results document.

It must consolidate:

- scalar/dense/sparse correctness;
- workload cycle counts;
- retired instruction counts;
- multiply accounting;
- sensor fixture results;
- storage accounting;
- generic synthesis counts;
- incremental sparse overhead;
- timing and power limitations.

Avoid duplicating conflicting metrics across many documents.

Where older documents contain stale values, correct them.

### 6. Reproduction Guide

Provide a concise reproducibility guide.

At minimum include:

```text
make check
make test-full-regression
make test-workload-all
make test-sensor-all
make ppa-all
```

Explain:

- prerequisites;
- expected tools;
- generated artifacts;
- ignored output directories;
- approximate purpose of each command;
- what successful output should contain.

Do not provide unsupported installation instructions.

### 7. Quick-Start Path

Add a minimal path for a reviewer who wants to validate the project quickly.

Preferred sequence:

1. repository checks;
2. one focused vector test;
3. workload comparison;
4. sensor comparison;
5. PPA report generation.

The quick-start should not require understanding the entire repository first.

### 8. Verification Summary

Create or polish a final verification summary including:

- directed tests;
- deterministic randomized tests;
- dense/sparse equivalence;
- invalid metadata;
- command backpressure;
- completion backpressure;
- reset cancellation;
- wrong-path suppression;
- scalar dependencies;
- vector memory;
- end-to-end bare-metal programs;
- sensor multi-sample execution;
- configuration-specific synthesis checks;
- full regressions.

Report actual deterministic seeds and case counts where available.

Do not claim formal verification unless formal tools were actually used.

### 9. Results Provenance

For every headline result, identify:

- source test or script;
- measurement definition;
- whether measured or derived;
- units;
- configuration;
- tool version where relevant.

At minimum cover:

- 7,399/484/484 cycles;
- 3,948/109/109 retired instructions;
- 32 executed and 32 skipped sparse multiplies;
- 64-byte dense versus 38-byte sparse storage;
- 14,029/62,928/65,691 generic cell counts;
- 4.39% sparse-over-dense overhead.

### 10. Repository Cleanup

Audit the repository for:

- obsolete temporary files;
- stale generated files;
- duplicate documentation;
- dead scripts;
- abandoned test artifacts;
- `.DS_Store`;
- untracked build outputs;
- broken relative links;
- stale `.codex/milestone_result.md` references;
- old result values;
- misleading comments;
- inconsistent terminology.

Do not delete files merely because they look old.

Delete or archive only files that are demonstrably obsolete and unreferenced.

### 11. Source Manifest

Update the source manifest so it accurately distinguishes:

- production/reference RTL;
- experimental pipeline RTL;
- vector RTL;
- synthesis wrappers;
- testbenches;
- workload scripts;
- sensor-model assets;
- documentation;
- generated/ignored outputs.

### 12. Stable Target Audit

Audit public Make targets.

Ensure stable targets have clear names and no accidental duplication.

At minimum preserve:

- scalar regression;
- vector regression;
- full regression;
- workload tests;
- sensor tests;
- PPA generation;
- lint;
- repository checks;
- documentation checks.

Add a concise help target only if it can be done cleanly without broad Makefile restructuring.

### 13. Final Limitations Section

Document:

- experimental status of `rv32_core_pipe`;
- no full RVV;
- fixed 32-bit vector width;
- one outstanding vector command;
- fixed-latency dense and sparse execution;
- no sparse latency reduction yet;
- no compressed sparse-load instruction;
- no SRAM macro mapping;
- generic synthesis only;
- no physical timing closure;
- no measured power;
- fixture accuracy rather than general model accuracy;
- no full compiler backend.

### 14. Future Research Directions

Include a bounded future-work section covering:

- compressed sparse data movement;
- packed sparse loads;
- fused sparse operations;
- latency crossover points;
- layer-adaptive structured sparsity;
- hardware-aware pruning;
- SRAM-backed physical implementation;
- real dataset expansion;
- SparrowML integration.

Do not implement these in this milestone.

### 15. Final CV-Ready Project Summary

Add one concise project-summary section suitable for later reuse.

It should state, truthfully:

- what was designed;
- what was verified;
- what workload was run;
- what was measured;
- the sparse arithmetic/storage benefits;
- the sparse hardware overhead;
- the main limitation.

Do not create a resume file unless one already exists in the repository.

## Out of Scope

Do not add:

- new ISA instructions;
- new RTL datapaths;
- new processor stages;
- sparse-load instructions;
- fused instructions;
- caches;
- DMA;
- AXI;
- wider vectors;
- new ML models;
- model training;
- ONNX support;
- compiler IR;
- GCC or LLVM support;
- OpenLane/OpenROAD implementation;
- timing-driven RTL optimization;
- power estimation;
- new benchmarks;
- research experiments;
- changes to `rtl/core/rv32_core.sv`.

Do not change validated architectural behavior merely to simplify documentation.

## Consistency Requirements

All final documents must agree on:

- instruction names;
- vector register count;
- lane ordering;
- scratchpad size;
- metadata encoding;
- workload dimensions;
- sample count;
- class names;
- cycle counts;
- retirement counts;
- multiplication counts;
- storage values;
- synthesis counts;
- sparse overhead;
- tool versions;
- limitations.

Search for stale or conflicting values before completion.

## Link Validation

Check every relative Markdown link in:

- README;
- architecture documents;
- implementation status;
- verification plan;
- final results documents.

Add a bounded link-checking script only if one does not exist and it can be implemented without external dependencies.

Broken links must fail the documentation check.

## Reproducibility Validation

From a clean or effectively clean working tree, verify:

```text
make check
make test-vector-regression
make test-workload-all
make test-sensor-all
make ppa-all
make test-full-regression
make lint
make docs-check
git diff --check
```

If generated PPA results are ignored, confirm regeneration does not modify tracked source files unexpectedly.

## Final Release Readiness

Create a release-readiness checklist covering:

- clean working tree before release;
- all stable targets passing;
- README complete;
- architecture diagrams render;
- final metrics consistent;
- no secrets or personal data;
- no generated junk;
- no broken links;
- limitations stated;
- reproducibility commands documented;
- repository ready for a version tag.

Do not create a Git tag or GitHub release.

## Acceptance Criteria

The milestone is complete only when:

1. README provides a coherent project overview.
2. README includes motivation, architecture, verification, results, reproduction, and limitations.
3. One final architecture overview exists.
4. One architecture diagram exists.
5. One sparse dataflow diagram exists.
6. Custom instructions are summarized accurately.
7. One canonical final-results document exists.
8. Workload metrics are consistent across all tracked files.
9. Sensor fixture metrics are consistent across all tracked files.
10. Storage metrics are consistent across all tracked files.
11. Synthesis metrics are consistent across all tracked files.
12. Sparse incremental overhead is reported as 4.39%.
13. Generic-memory mapping limitations are explicit.
14. Fixed-latency dense/sparse behavior is explicit.
15. Results provenance is documented.
16. Measured and derived metrics are distinguished.
17. Reproduction commands are documented.
18. Quick-start commands are documented.
19. Verification coverage is summarized.
20. Deterministic seeds and case counts are included where available.
21. Repository structure is documented.
22. Source manifest is accurate.
23. Public Make targets are consistent.
24. No stale milestone-result path remains.
25. No `.DS_Store` files remain.
26. No obsolete generated outputs are tracked unintentionally.
27. No broken documentation links remain.
28. No conflicting headline metrics remain.
29. Limitations are complete and honest.
30. Future research directions are documented but not implemented.
31. A release-readiness checklist exists.
32. The scalar reference core remains unchanged.
33. All workload and sensor tests pass.
34. All scalar and vector regressions pass.
35. PPA report regeneration passes.
36. Lint passes with only documented non-fatal warnings.
37. Repository checks pass.
38. Documentation checks pass.
39. `git diff --check` passes.
40. No new architectural functionality is added.
41. No commit or push occurs.
42. `docs/codex_milestone_result.md` is finalized.

## Stop Conditions

Stop for human review only if:

- tracked documents contain irreconcilable conflicting metrics;
- a headline result cannot be reproduced;
- a public command no longer works;
- final regression reveals a likely architectural correctness bug;
- repository cleanup would require deleting uncertain source material;
- diagrams cannot accurately represent the implemented design;
- source ownership or licensing is unclear;
- secret or personal data is discovered.

Ordinary documentation edits, broken links, stale metrics, and repository cleanup are not stop conditions.

## Required Documentation

Create or update, as appropriate:

- `README.md`;
- one final architecture overview;
- one canonical final-results document;
- one reproduction guide;
- one release-readiness checklist;
- `docs/implementation_status.md`;
- `docs/verification_plan.md`;
- `docs/milestone_history.md`;
- `docs/source_manifest.md`;
- `docs/codex_context.md`;
- `docs/codex_milestone_result.md`.

Avoid unnecessary document proliferation.

Prefer updating existing documents over adding duplicates.

## Required Result File

Update:

```text
docs/codex_milestone_result.md
```

throughout the run.

Finalize it with:

- `STATUS: COMPLETE`, `STATUS: FAILED`, or `STATUS: BLOCKED`;
- final project summary;
- exact headline metrics;
- documentation files created or updated;
- files removed and why;
- broken links fixed;
- stale metrics corrected;
- exact commands and outcomes;
- remaining limitations;
- release-readiness verdict;
- confirmation that no architectural feature was added;
- confirmation that `rtl/core/rv32_core.sv` is unchanged;
- confirmation that no commit or push occurred.