# Milestone: Hardware-Aware Model Exporter and Multi-Sample Sensor Inference

## Objective

Extend Sparrow-V from a single synthetic fully connected benchmark into a reproducible model-deployment flow for a small edge-sensor classification workload.

The milestone must implement a bounded hardware-aware exporter that:

1. accepts a deterministic quantized fully connected model and sensor-feature samples;
2. validates signed INT8 and 2:4 sparsity requirements;
3. emits dense and compressed sparse Sparrow-V data images;
4. emits or reuses a Sparrow-V bare-metal program image;
5. runs multiple samples through dense and sparse RTL execution;
6. compares RTL outputs against an independent Python reference;
7. reports correctness, predicted class, cycles, retired instructions, vector operations, multiplication accounting, and storage.

This is a Sparrow-V deployment milestone, not the full SparrowML project.

## Baseline

The repository currently contains:

- `rtl/core/rv32_core.sv` as the unchanged scalar reference core;
- `rtl/core/rv32_core_pipe.sv` as the experimental scalar/vector core;
- a blocking, in-order scalar/vector command-completion interface;
- one shared vector register file;
- a 256-byte vector scratchpad;
- `VADD8`;
- signed dense `VDOT8`;
- signed compressed 2:4 `VSDOT8`;
- `VLOAD32` and `VSTORE32`;
- precise retirement, exception, reset, backpressure, and wrong-path behavior;
- deterministic bare-metal scalar, dense-vector, and sparse-vector fully connected workloads;
- a Python instruction and workload generator;
- a Python golden model;
- measured scalar, dense, and sparse execution metrics;
- full scalar and vector regressions.

The previous workload produced identical outputs:

```text
[382, -446, -246, 1054]
```

with:

- scalar: 7399 cycles, 3948 retired instructions;
- dense: 484 cycles, 109 retired instructions;
- sparse: 484 cycles, 109 retired instructions;
- sparse: 32 multiplications executed and 32 skipped;
- dense weights: 64 bytes;
- sparse compressed weights plus metadata: 38 bytes.

## Relevant Context

Read:

- `AGENTS.md`
- `docs/codex_context.md`
- `docs/current_milestone.md`
- `docs/architecture/sparse_fc_workload.md`
- `docs/architecture/vector_vsdot8.md`
- `docs/architecture/vector_memory.md`
- `docs/architecture/scalar_vector_interface.md`
- `scripts/workload_fc.py`
- `tb/integration/tb_workload_fc.sv`
- relevant Makefile targets
- current implementation-status and verification-plan documents.

Read additional files only when required by a concrete implementation or verification issue.

## Scope Summary

Implement a reusable deployment path for a small vibration-fault or sensor-anomaly classifier represented as:

```text
signed INT8 input features
→ one fully connected output layer
→ signed INT32 logits
→ argmax predicted class
```

Use:

- 16 signed INT8 input features;
- 4 output classes;
- 64 dense signed INT8 weights;
- 4 signed INT32 biases;
- equivalent dense and 2:4 sparse model forms;
- at least 16 deterministic evaluation samples;
- one expected class label per sample.

The model may be a compact checked-in deployment fixture rather than a newly trained state-of-the-art model.

It must be clearly labelled as a deterministic sensor-classification fixture unless its provenance from a real public dataset is already available and documented.

Do not fabricate claims about model quality or dataset accuracy.

## Input Model Format

Define one stable machine-readable model format.

Preferred format:

```text
JSON
```

The model description must include:

- model name;
- version;
- input feature count;
- output class count;
- class names;
- signed INT8 dense weight matrix;
- signed INT32 bias vector;
- optional feature scaling metadata;
- optional provenance note;
- explicit data-layout version.

Example conceptual structure:

```json
{
  "model_name": "sparrow_vibration_fixture",
  "format_version": 1,
  "input_features": 16,
  "output_classes": 4,
  "class_names": ["normal", "inner", "outer", "ball"],
  "weights_int8": [
    [0, 0, 0, 0],
    [0, 0, 0, 0]
  ],
  "bias_int32": [0, 0, 0, 0]
}
```

The actual weight layout must be documented unambiguously.

The exporter must reject:

- wrong matrix dimensions;
- missing fields;
- values outside signed INT8 or signed INT32 range;
- inconsistent class counts;
- malformed metadata;
- unsupported format versions.

## Sensor Sample Format

Define one stable sample format.

Preferred format:

```text
CSV or JSON
```

Each sample must include:

- sample ID;
- 16 signed INT8 input features;
- expected class label;
- optional source or fixture note.

At least 16 deterministic samples must be checked in.

The sample set must include:

- positive values;
- negative values;
- zeros;
- at least one `-128` where mathematically safe;
- at least one `127`;
- samples from all four classes where practical.

The exporter must reject:

- incorrect feature count;
- values outside signed INT8;
- unknown labels;
- duplicate sample IDs where uniqueness is required.

## Dense Model Export

Export the dense model into the existing Sparrow-V workload representation.

Requirements:

- preserve the exact mathematical dense weight matrix;
- use four groups of four weights per output class;
- preserve little-endian INT8 lane ordering;
- emit deterministic scratchpad or data-memory images;
- emit deterministic expected-logit files;
- emit any required manifest describing addresses and sizes.

Dense storage must report:

```text
64 weight bytes
```

Bias storage must be reported separately.

## 2:4 Sparse Conversion

Implement deterministic 2:4 structured pruning or projection.

For every consecutive four-weight group:

- retain exactly two weights;
- set exactly two weights to zero;
- retain the two weights with largest absolute magnitude;
- use a deterministic tie-breaking rule based on lower lane index;
- encode one of the six legal Sparrow-V metadata patterns;
- order compressed weights according to the existing VSDOT8 contract;
- reconstruct the sparse dense-equivalent matrix for validation.

Document the tie-breaking rule.

The exporter must verify for every sparse group:

- exactly two retained values;
- exactly two zeroed values;
- legal metadata;
- lower selected lane maps to compressed weight 0;
- higher selected lane maps to compressed weight 1;
- decompression reproduces the sparse dense-equivalent group exactly.

Do not use invalid metadata encodings.

## Sparse Storage Packing

Export:

- compressed INT8 weights;
- 3-bit metadata;
- a documented metadata packing format;
- deterministic memory images;
- a manifest describing byte offsets and group association.

Report:

- compressed weight bytes;
- metadata bits;
- packed metadata bytes;
- padding bits;
- total sparse model bytes;
- percentage reduction relative to dense weights.

Do not claim a full 50% storage reduction when metadata and padding are included.

## Python Reference Inference

Add or extend an independent Python reference model.

For each sample compute:

1. dense INT32 logits;
2. sparse dense-equivalent INT32 logits;
3. compressed sparse INT32 logits;
4. dense predicted class;
5. sparse predicted class.

Require:

```text
sparse dense-equivalent logits == compressed sparse logits
```

Dense and sparse logits are allowed to differ because pruning changes the mathematical model.

The exporter must report:

- dense logits;
- sparse logits;
- dense predicted class;
- sparse predicted class;
- expected label;
- whether each prediction is correct.

Do not require dense and sparse logits to be identical after pruning.

## Accuracy Reporting

For the checked-in sample set, report:

- dense correct predictions;
- dense accuracy;
- sparse correct predictions;
- sparse accuracy;
- number of dense/sparse prediction disagreements;
- per-class sample counts;
- per-class correct counts where practical.

Clearly label this as:

- fixture accuracy;
- deployment-set accuracy;
- or dataset-subset accuracy,

depending on the actual provenance.

Do not present it as general model accuracy unless evaluated on a documented dataset split.

## Sparrow-V Program Generation

Reuse the existing bare-metal workload infrastructure where practical.

The exporter or generator must create deterministic artifacts for:

- dense execution;
- sparse execution;
- each selected sensor sample or a bounded batch sequence.

Preferred approach:

- reuse one parameterized program structure;
- regenerate data images per sample;
- avoid producing a large unrelated program for every sample when one reusable program is sufficient.

The generated program must:

- load 16 activation features;
- compute four output logits;
- add each bias once;
- write four signed INT32 outputs;
- write one completion signature;
- optionally write the predicted class if cleanly supported.

Do not add new ISA instructions unless a genuine existing capability gap blocks the milestone.

## RTL End-to-End Execution

Run dense and sparse inference through:

```text
rtl/core/rv32_core_pipe.sv
```

Requirements:

- actual instruction fetch and execution;
- actual VLOAD32 operations;
- actual VDOT8 or VSDOT8 operations;
- actual scalar accumulation and result storage;
- deterministic completion detection;
- bounded timeout;
- no direct calls into the vector engine from the workload testbench.

For every sample verify:

- four RTL logits;
- exact agreement with the corresponding Python reference;
- predicted class agreement with Python;
- no unexpected trap;
- exactly one completion signature.

## Multi-Sample Execution Strategy

Use one of these bounded strategies:

### Preferred

Run each sample as an independent deterministic simulation invocation.

### Acceptable

Run multiple samples sequentially in one simulation only if:

- state is reset or explicitly reinitialized;
- counters are separated per sample;
- output attribution remains unambiguous.

Do not introduce complex batching infrastructure.

## Required Metrics

For dense and sparse RTL execution, report per sample:

- cycles;
- retired instructions;
- VLOAD32 retirements;
- VDOT8 retirements;
- VSDOT8 retirements;
- sparse executed multiplications;
- sparse skipped multiplications;
- completion status;
- predicted class.

Also report aggregate values:

- minimum cycles;
- maximum cycles;
- mean cycles;
- total retired instructions;
- total dense dot products;
- total sparse dot products;
- total sparse executed multiplications;
- total sparse skipped multiplications.

If deterministic program paths make cycle counts identical across samples, report that explicitly.

## Expected Operation Counts

For a 16-input, 4-output single fully connected layer:

```text
4 groups per output × 4 outputs = 16 dot-product instructions
```

Dense execution must report per sample:

- 16 VDOT8 operations;
- 64 conceptual signed INT8 multiplications;
- 0 VSDOT8 operations.

Sparse execution must report per sample:

- 16 VSDOT8 operations;
- 32 executed signed INT8 multiplications;
- 32 skipped multiplications;
- 0 VDOT8 operations.

Any deviation must fail the test unless the program structure is intentionally changed and documented.

## Correctness Requirements

For every checked-in sample:

- Python dense logits are deterministic;
- Python sparse logits are deterministic;
- RTL dense logits equal Python dense logits;
- RTL sparse logits equal Python sparse logits;
- RTL dense prediction equals Python dense prediction;
- RTL sparse prediction equals Python sparse prediction;
- no unexpected trap occurs;
- outputs remain within signed INT32;
- completion occurs before timeout.

## Export Manifest

Generate one deterministic manifest containing:

- model name and version;
- sample-set name and version;
- feature count;
- class count;
- dense weight bytes;
- compressed sparse weight bytes;
- metadata bytes;
- bias bytes;
- memory image paths;
- scratchpad offsets;
- output addresses;
- program image paths;
- expected operation counts;
- optional content hashes.

Preferred format:

```text
JSON
```

Paths must be repository-relative where practical.

Do not include machine-specific absolute paths.

## Reproducibility

The full export must be reproducible from checked-in source inputs.

One command must regenerate all generated workload artifacts.

Example target:

```text
make generate-sensor-workload
```

After regeneration:

- `git diff --exit-code` should remain clean for checked-in generated artifacts;
- or generated artifacts must be ignored and compared through deterministic tests.

Choose one policy and document it.

## Validation of Existing Benchmark

Preserve the previous synthetic FC benchmark and its verified metrics.

Do not replace or silently alter:

- the `[382, -446, -246, 1054]` reference workload;
- scalar, dense, or sparse benchmark definitions;
- existing cycle-count scope;
- existing regressions.

The sensor deployment flow must be additive.

## Out of Scope

Do not implement:

- full SparrowML;
- model training framework;
- neural-network architecture search;
- quantization-aware training;
- knowledge distillation;
- ONNX import;
- compiler IR;
- LLVM or GCC backend;
- full C runtime;
- convolution;
- recurrent networks;
- multi-layer inference unless trivially supported without new RTL;
- activation functions requiring new ISA support;
- automatic dataset download;
- internet-dependent tests;
- floating point;
- dynamic tensor shapes;
- configurable vector length;
- wider vector registers;
- new architectural CSRs;
- DMA, caches, or external memory;
- FPGA or ASIC flow;
- changes to `rtl/core/rv32_core.sv`.

## Focused Tests

Add focused tests for:

### Model parser

- valid model;
- invalid dimensions;
- signed INT8 overflow;
- signed INT32 bias overflow;
- unsupported format version;
- class-name mismatch.

### Sample parser

- valid samples;
- wrong feature count;
- out-of-range values;
- unknown labels;
- duplicate IDs if disallowed.

### 2:4 conversion

- all six metadata patterns;
- deterministic tie-breaking;
- positive and negative weights;
- zero-valued weights;
- `-128`;
- `127`;
- exact decompression;
- exactly two retained values per group.

### Storage accounting

- dense bytes;
- compressed bytes;
- metadata bits;
- packed metadata bytes;
- padding;
- total sparse bytes;
- percentage reduction.

### Python inference

- dense logits;
- sparse logits;
- compressed/decompressed sparse equality;
- argmax;
- label comparison;
- deterministic accuracy summary.

### Artifact generation

- deterministic program images;
- deterministic data images;
- deterministic manifest;
- valid memory bounds;
- no machine-specific paths.

### RTL dense inference

For all selected samples:

- exact logits;
- correct predicted class;
- 16 VDOT8;
- 0 VSDOT8;
- expected VLOAD32 count;
- no sparse executed/skipped events;
- one completion signature.

### RTL sparse inference

For all selected samples:

- exact logits;
- correct predicted class;
- 0 VDOT8;
- 16 VSDOT8;
- 32 executed multiplications;
- 32 skipped multiplications;
- expected VLOAD32 count;
- one completion signature.

### Aggregate comparison

Report:

- dense and sparse accuracy;
- disagreement count;
- dense and sparse cycle summaries;
- storage comparison;
- operation comparison.

## Canonical Targets

Add targets following repository conventions, including equivalents of:

```text
generate-sensor-workload
test-sensor-model-parser
test-sensor-sparsify
test-sensor-golden
test-sensor-export
test-sensor-dense
test-sensor-sparse
test-sensor-compare
test-sensor-all
```

Exact names may be adjusted to match the repository.

Do not force the full multi-sample workload into every focused RTL test.

Include it in:

- a dedicated sensor-workload aggregate target;
- and the final full regression if runtime remains reasonable.

## Final Acceptance Regression

During development, run focused parser, exporter, golden-model, and sample-level tests.

After implementation is stable, run once:

```text
make test-sensor-all
make test-workload-all
make test-vector-regression
make test-full-regression
make lint
make check
make docs-check
git diff --check
```

## Acceptance Criteria

The milestone is complete only when:

1. A stable model input format exists.
2. A stable sensor-sample format exists.
3. The model uses 16 signed INT8 input features.
4. The model produces 4 signed INT32 logits.
5. At least 16 deterministic samples exist.
6. Every model and sample input is range-validated.
7. Dense weights export deterministically.
8. Deterministic 2:4 pruning or projection exists.
9. Tie-breaking is documented.
10. Every sparse group retains exactly two weights.
11. Every sparse group uses legal metadata.
12. Compressed-weight ordering matches VSDOT8.
13. Sparse decompression is exact.
14. Dense storage bytes are reported.
15. Compressed weight bytes are reported.
16. Metadata bits and packed bytes are reported.
17. Total sparse storage is reported honestly.
18. Python dense inference works.
19. Python sparse inference works.
20. Compressed sparse inference equals decompressed sparse inference.
21. Dense predicted classes are reported.
22. Sparse predicted classes are reported.
23. Expected labels are reported.
24. Dense and sparse accuracy are reported with correct scope.
25. A deterministic export manifest exists.
26. Dense program/data artifacts are generated.
27. Sparse program/data artifacts are generated.
28. Artifacts use repository-relative paths.
29. Generation is reproducible.
30. Dense RTL execution runs through the real pipeline.
31. Sparse RTL execution runs through the real pipeline.
32. Dense RTL logits equal Python dense logits for every sample.
33. Sparse RTL logits equal Python sparse logits for every sample.
34. Dense predicted classes match Python for every sample.
35. Sparse predicted classes match Python for every sample.
36. No unexpected trap occurs.
37. Every sample completes before timeout.
38. Dense execution reports 16 VDOT8 operations per sample.
39. Sparse execution reports 16 VSDOT8 operations per sample.
40. Sparse execution reports 32 executed multiplications per sample.
41. Sparse execution reports 32 skipped multiplications per sample.
42. Dense execution reports no sparse accounting events.
43. Per-sample cycles and retired instructions are reported.
44. Aggregate cycle statistics are reported.
45. Dense/sparse prediction disagreements are reported.
46. Previous synthetic workload remains passing.
47. Existing scalar and vector regressions remain passing.
48. Documentation distinguishes fixture results from real dataset claims.
49. No internet-dependent test is added.
50. No new ISA, cache, DMA, compiler backend, or broad RTL redesign is added.
51. `rtl/core/rv32_core.sv` remains unchanged.
52. Codex creates no commit or push.
53. `.codex/milestone_result.md` is finalized.

## Stop Conditions

Stop for human review only if:

- the existing FC program cannot accept regenerated model data without major RTL changes;
- the 256-byte scratchpad cannot support one sample using separated deterministic runs;
- accurate multi-sample execution requires new ISA operations;
- model dimensions cannot fit existing memory or instruction encoding;
- dense or sparse logits cannot be reproduced by the existing arithmetic semantics;
- adding the exporter requires a compiler framework rather than a bounded script;
- a likely existing CPU, vector, or workload correctness bug is discovered;
- the only available route requires internet-dependent tests.

Ordinary parser bugs, packing bugs, memory-layout changes, testbench issues, and documentation work are not stop conditions.

## Required Documentation

Update only materially affected files, normally:

- a new sensor deployment architecture document;
- `docs/implementation_status.md`;
- `docs/verification_plan.md`;
- `docs/milestone_history.md`;
- README only if stable public commands are added.

Document:

- model and sample formats;
- fixture or dataset provenance;
- class names;
- quantized tensor layout;
- 2:4 pruning rule;
- tie-breaking;
- compressed-weight layout;
- metadata packing;
- memory map;
- exporter command;
- manifest format;
- Python inference methodology;
- RTL execution methodology;
- per-sample and aggregate results;
- dense and sparse accuracy scope;
- storage accounting;
- operation accounting;
- limitations and non-claims.

Do not describe the fixture as a trained production model unless that is genuinely true and documented.

## Result File

Update `.codex/milestone_result.md` throughout the run.

Finalize it with:

- `STATUS: COMPLETE`, `STATUS: BLOCKED`, or `STATUS: FAILED`;
- model and sample-set names;
- provenance description;
- sample count;
- class names;
- dense and sparse accuracy;
- disagreement count;
- dense and sparse storage;
- per-sample operation counts;
- aggregate cycle and retirement metrics;
- exact test commands;
- changed files;
- bugs fixed;
- remaining limitations;
- confirmation that the previous FC benchmark still passes;
- confirmation that existing scalar/vector regressions pass;
- confirmation that `rtl/core/rv32_core.sv` is unchanged;
- confirmation that no commit or push occurred.