# Milestone: Bare-Metal Sparse Kernel and Scalar vs Dense vs Sparse Evaluation

## Objective

Demonstrate Sparrow-V as a working sparse-aware processor by running one complete quantized inference-style kernel in three implementations:

1. scalar RV32I;
2. dense vector using `VDOT8`;
3. 2:4 sparse vector using `VSDOT8`.

All three implementations must produce identical signed 32-bit outputs for the same deterministic workload.

The milestone must measure:

- total cycles;
- retired instructions;
- dense and sparse dot-product instruction counts;
- multiplications executed;
- multiplications skipped;
- weight-storage bytes;
- vector scratchpad activity where observable.

This milestone should use the existing hardware rather than add major new RTL features.

## Baseline

The repository currently contains:

- `rtl/core/rv32_core.sv` as the unchanged scalar reference core;
- `rtl/core/rv32_core_pipe.sv` as the experimental scalar/vector integration core;
- one shared vector-register file;
- `VADD8`;
- dense signed `VDOT8`;
- compressed 2:4 signed `VSDOT8`;
- multiplication-executed and multiplication-skipped accounting;
- a 256-byte vector scratchpad;
- aligned `VLOAD32` and `VSTORE32`;
- precise completion, retirement, exceptions, reset cancellation, and wrong-path suppression;
- deterministic scalar, vector, memory, and sparse regressions.

## Relevant Context

Read:

- `AGENTS.md`
- `docs/codex_context.md`
- `docs/current_milestone.md`
- `docs/architecture/scalar_vector_interface.md`
- `docs/architecture/vector_vadd8.md`
- `docs/architecture/vector_memory.md`
- the sparse-execution architecture document;
- `rtl/core/rv32_core_pipe.sv`
- `rtl/vector/rv32_vec_vadd_engine.sv`
- the existing integration testbenches;
- relevant Makefile and simulation scripts.

Read additional files only when a concrete implementation need requires them.

## Workload

Implement one deterministic quantized fully connected layer:

```text
y[j] = bias[j] + Σ x[k] × w[j][k]
```

Use this initial bounded configuration:

- 16 signed INT8 input features;
- 4 output neurons;
- 4 groups of 4 weights per output;
- signed INT32 accumulation;
- deterministic fixed input vector;
- deterministic fixed dense weights;
- deterministic 2:4-pruned sparse weights;
- deterministic biases.

The dense and sparse forms must represent equivalent mathematical weights.

For every 4-weight group in the sparse form:

- exactly two weights are nonzero;
- two compressed INT8 weights are stored;
- one 3-bit metadata value selects their activation lanes;
- sparse execution uses `VSDOT8`.

Do not increase the workload size unless the initial configuration is clearly too small to produce meaningful measurements.

## Three Implementations

### 1. Scalar RV32I kernel

Implement the layer using supported scalar instructions only.

Requirements:

- signed INT8 values must be represented and sign-extended correctly;
- multiplication may use an existing supported scalar multiply path if available;
- if scalar multiply is not implemented, use a bounded software multiply routine;
- accumulation must be signed INT32;
- outputs must be stored in a known result region;
- no custom vector instructions may be used.

Document exactly how scalar multiplication is implemented.

### 2. Dense vector kernel

Implement the same layer using:

- `VLOAD32` for activation and dense-weight groups;
- `VDOT8` for four-lane signed dot products;
- scalar accumulation of partial dot products and bias;
- existing scalar instructions for loop/control and result storage.

Requirements:

- four dense dot-product groups per output neuron;
- no `VSDOT8`;
- outputs identical to the scalar kernel.

### 3. Sparse vector kernel

Implement the same layer using:

- `VLOAD32` for activation groups;
- `VLOAD32` for compressed two-weight groups;
- `VSDOT8` with 2:4 metadata;
- scalar accumulation of partial sparse dot products and bias;
- existing scalar instructions for loop/control and result storage.

Requirements:

- four sparse dot-product groups per output neuron;
- exactly two multiplications executed and two skipped per sparse group;
- outputs identical to the scalar and dense kernels.

## Program Representation

Provide a minimal bare-metal program-generation path.

Preferred implementation:

- a small Python instruction encoder or assembler helper;
- deterministic generation of instruction-memory and data-memory images;
- helpers for standard RV32I instructions used by the workload;
- helpers for `VLOAD32`, `VSTORE32`, `VDOT8`, and `VSDOT8`;
- no dependency on a full custom compiler backend.

The generator must:

- produce reproducible program images;
- validate immediate and register-field ranges;
- fail clearly on unsupported instructions;
- document the custom-instruction encodings it emits.

Do not hardcode raw instruction words throughout the testbench when a small reusable encoder would be clearer.

## Data Layout

Define and document a deterministic layout for:

- input activations;
- dense weights;
- compressed sparse weights;
- sparse metadata;
- biases;
- scalar outputs;
- dense-vector outputs;
- sparse-vector outputs.

The vector scratchpad is only 256 bytes, so confirm the proposed layout fits.

If all three datasets cannot coexist in the scratchpad simultaneously, use separate deterministic runs or reload phases rather than enlarging the memory without review.

Document:

- byte offsets;
- word organization;
- lane ordering;
- compressed-weight ordering;
- metadata association;
- output locations.

## Golden Model

Add an independent Python golden model.

It must compute:

- scalar dense outputs;
- equivalent dense-vector outputs;
- sparse compressed outputs;
- expected multiplication counts;
- expected skipped counts;
- dense and sparse weight-storage sizes.

The model must verify:

```text
scalar_output == dense_vector_output == sparse_vector_output
```

for all four output neurons.

Do not derive expected sparse results from RTL helper code.

## End-to-End Simulation Harness

Add an integration-level test that:

1. loads the generated program image;
2. initializes required scalar memory and vector scratchpad state;
3. runs until completion, trap, or timeout;
4. captures output values;
5. compares outputs against the Python-generated expected values;
6. records performance and activity metrics;
7. fails on any mismatch or unexpected trap.

Use the actual scalar/vector pipeline path.

Do not bypass instruction execution by directly calling vector modules.

## Completion Signalling

Use one deterministic program-completion mechanism.

Preferred options:

- write a known signature to a monitored scalar-memory address;
- execute an existing terminal instruction convention;
- use another already established integration-test completion mechanism.

The harness must distinguish:

- successful completion;
- timeout;
- unexpected trap;
- output mismatch.

## Performance Counters

Provide measured or testbench-observed counters for each kernel.

At minimum record:

- total cycles from program start to completion;
- retired instruction count;
- scalar multiply operations or software-multiply invocations;
- `VDOT8` instructions retired;
- `VSDOT8` instructions retired;
- multiplications executed;
- multiplications skipped;
- vector loads;
- vector stores;
- scratchpad writes where observable.

Counters may be implemented in the testbench if they are derived from real retirement and debug events.

Do not add architectural CSRs solely for this milestone unless the existing design already has a suitable counter interface.

## Weight-Storage Accounting

Report exact weight-storage bytes.

For the workload:

### Dense form

Count:

- all 16 INT8 weights per output;
- total across 4 outputs.

### Sparse form

Count:

- two compressed INT8 weights per 4-weight group;
- metadata storage;
- total across 4 outputs.

Be explicit about metadata packing assumptions.

Report both:

- raw weight bytes;
- weight plus metadata bytes.

Do not claim a 50% total-storage reduction if metadata overhead makes the measured reduction smaller.

## Required Measurements

Produce one comparison table:

| Metric | Scalar RV32I | Dense Vector | Sparse Vector |
|---|---:|---:|---:|
| Correct outputs | | | |
| Total cycles | | | |
| Retired instructions | | | |
| Scalar multiply operations | | | |
| Dense dot-product instructions | | | |
| Sparse dot-product instructions | | | |
| Multiplications executed | | | |
| Multiplications skipped | | | |
| Vector loads | | | |
| Vector stores | | | |
| Weight bytes | | | |
| Metadata bytes | | | |
| Weight + metadata bytes | | | |

Every value must be measured or deterministically derived and clearly labelled.

## Correctness Requirements

All three kernels must:

- produce exactly four signed INT32 outputs;
- match the independent Python golden model;
- use identical input values and equivalent mathematical weights;
- include bias exactly once;
- use correct signed INT8 interpretation;
- avoid overflow beyond signed INT32 for the chosen dataset;
- complete without unexpected trap;
- terminate within a bounded timeout.

The sparse kernel must additionally prove:

- every group obeys 2:4 structure;
- metadata matches the compressed-weight order;
- sparse output equals the equivalent dense output;
- executed multiplication count equals 2 per sparse group;
- skipped multiplication count equals 2 per sparse group.

## Directed Workload Cases

The primary workload must include a mixture of:

- positive activations;
- negative activations;
- zero activations;
- positive weights;
- negative weights;
- zero weights;
- at least one `-128` value where mathematically safe;
- at least one `127` value;
- cancellation across groups;
- nonzero biases;
- positive and negative final outputs where practical.

Keep all expected outputs within signed 32-bit range.

## Determinism

All generated images, inputs, weights, metadata, expected outputs, and measurements must be reproducible.

Use:

- a fixed seed if data is generated;
- checked-in deterministic configuration;
- stable program ordering;
- stable timeout;
- stable measurement definitions.

Report the seed if one is used.

## Assertions and Sanity Checks

Add checks for:

- program image bounds;
- scratchpad layout bounds;
- valid sparse metadata;
- exactly two nonzero weights per sparse group;
- dense/sparse mathematical equivalence before simulation;
- no unexpected vector-register or scratchpad writes;
- no sparse compute accounting for dense execution;
- expected sparse accounting for sparse execution;
- no unexpected exception;
- exactly one completion signature;
- no output write before the relevant computation completes.

## Existing Feature Preservation

Preserve all current regressions for:

- scalar directed and differential verification;
- scalar/vector adapter;
- `VADD8`;
- dense `VDOT8`;
- `VLOAD32` and `VSTORE32`;
- vector scratchpad;
- `VSDOT8`;
- reset, backpressure, redirect, and exception behavior.

Do not weaken or replace the existing focused tests.

## Out of Scope

Do not implement:

- a C compiler backend;
- GCC or LLVM changes;
- a full assembler;
- an operating system;
- interrupts;
- caches;
- external DRAM;
- DMA;
- convolution;
- multiple neural-network layers;
- activation functions beyond what is already trivial in scalar code;
- floating point;
- training;
- automatic pruning;
- quantization-aware training;
- configurable vector length;
- vectors wider than 32 bits;
- additional ISA operations unless strictly necessary and approved;
- FPGA or ASIC optimization;
- power estimates without a measured flow;
- changes to `rtl/core/rv32_core.sv`.

## Focused Development Tests

Add focused tests for:

### Program encoder

- known scalar instruction encodings;
- `VLOAD32`;
- `VSTORE32`;
- `VDOT8`;
- `VSDOT8`;
- positive and negative immediates;
- rejection of invalid register, immediate, and metadata values.

### Golden model

- scalar/dense/sparse equality;
- sparse metadata reconstruction;
- storage-byte calculations;
- multiplication-count calculations.

### End-to-end scalar kernel

- program completion;
- four correct outputs;
- no custom vector instruction retirement;
- stable cycle and retirement counts.

### End-to-end dense-vector kernel

- program completion;
- four correct outputs;
- expected `VDOT8` count;
- zero `VSDOT8` count;
- correct multiplication count.

### End-to-end sparse-vector kernel

- program completion;
- four correct outputs;
- expected `VSDOT8` count;
- exact executed/skipped multiplication counts;
- compressed storage accounting.

### Cross-kernel comparison

- identical outputs;
- all required metrics present;
- no unlabelled or fabricated measurements.

## Canonical Targets

Add targets following repository conventions, including equivalents of:

```text
test-workload-encoder
test-workload-golden
test-workload-scalar
test-workload-dense
test-workload-sparse
test-workload-compare
test-workload-all
```

Update `test-vector-regression` only if the new workload test is sufficiently bounded.

A larger workload comparison may instead be included only in `test-full-regression` or a dedicated workload regression target.

Avoid making every focused RTL edit rerun the full end-to-end workload.

## Final Acceptance Regression

During development, run only the relevant encoder, golden-model, and kernel tests.

After implementation is stable, run once:

```text
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

1. A deterministic fully connected workload exists.
2. It has 16 signed INT8 inputs and 4 outputs.
3. It includes equivalent dense and 2:4 sparse weights.
4. A Python golden model computes all expected outputs.
5. Scalar RV32I execution produces the expected outputs.
6. Dense-vector execution produces the expected outputs.
7. Sparse-vector execution produces the expected outputs.
8. All three output vectors are identical.
9. Bias is included correctly.
10. A reusable program encoder exists.
11. Custom vector instruction encodings are generated programmatically.
12. Program and data layouts are documented.
13. The layout fits existing memories or uses clearly separated runs.
14. End-to-end execution uses the actual pipeline.
15. Completion and timeout behavior are deterministic.
16. Total cycles are measured for each kernel.
17. Retired instructions are measured for each kernel.
18. Dense `VDOT8` retirements are counted.
19. Sparse `VSDOT8` retirements are counted.
20. Sparse executed multiplications are counted.
21. Sparse skipped multiplications are counted.
22. Dense conceptual or measured multiplications are reported.
23. Scalar multiply work is reported honestly.
24. Dense weight-storage bytes are reported.
25. Sparse compressed-weight bytes are reported.
26. Metadata bytes are reported.
27. Combined sparse storage is reported.
28. Every sparse group has exactly two nonzero weights.
29. Sparse metadata reconstructs the equivalent dense weights.
30. No unexpected trap occurs.
31. No output mismatch occurs.
32. Existing scalar/vector regressions remain passing.
33. Documentation includes the final comparison table.
34. Claims distinguish measured values from derived values.
35. No compiler backend, OS, cache, DMA, wider vector, or unrelated ISA work is added.
36. `rtl/core/rv32_core.sv` remains unchanged.
37. Codex creates no commit or push.
38. `.codex/milestone_result.md` is finalized in compact format.

## Stop Conditions

Stop for human review only if:

- the scalar ISA cannot execute the workload without a major new instruction;
- the program cannot access required scalar or vector data without broad memory redesign;
- the 256-byte scratchpad cannot support even separated deterministic runs;
- end-to-end completion cannot be detected using existing integration mechanisms;
- cycle or retirement measurement requires invasive architectural redesign;
- dense and sparse kernels cannot be represented with the existing instruction encodings;
- a likely existing CPU/vector correctness bug is discovered;
- the milestone would require a compiler backend or external memory system.

Ordinary encoder bugs, testbench bugs, data-layout changes, program-generation issues, and documentation work are not stop conditions.

## Required Documentation

Update only materially affected files, normally:

- a new workload and evaluation document;
- `docs/implementation_status.md`;
- `docs/verification_plan.md`;
- `docs/milestone_history.md`;
- README if stable commands or headline results are added.

Document:

- workload dimensions;
- deterministic input, weights, sparsity, and biases;
- program-generation method;
- scalar multiply method;
- scratchpad and memory layout;
- dense and sparse kernel structure;
- golden-model methodology;
- completion detection;
- measurement definitions;
- final comparison table;
- storage accounting;
- limitations and non-claims.

Do not claim general ML inference, compiler support, or energy efficiency.

## Result File

Update `.codex/milestone_result.md` throughout the run.

Finalize it with:

- `STATUS: COMPLETE`, `STATUS: BLOCKED`, or `STATUS: FAILED`;
- workload dimensions;
- generator and golden-model summary;
- exact output values;
- scalar, dense, and sparse metrics;
- multiplication and storage accounting;
- focused and final test commands;
- changed files;
- bugs fixed;
- remaining limitations;
- confirmation that existing sparse/vector tests remain passing;
- confirmation that `rtl/core/rv32_core.sv` is unchanged;
- confirmation that no commit or push occurred.