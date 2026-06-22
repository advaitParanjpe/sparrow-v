# Milestone: 2:4 Sparse Signed INT8 Dot Product

## Objective

Implement Sparrow-V’s defining sparse-compute operation:

```text
VSDOT8 rd, va, vw, pattern
```

`VSDOT8` performs a signed INT8 dot product using:

- one four-lane activation vector;
- two compressed nonzero INT8 weights;
- 3-bit metadata selecting two active activation lanes from a group of four;
- two signed multiplications instead of four;
- signed 32-bit scalar accumulation and writeback.

The milestone must demonstrate functional equivalence with the existing dense `VDOT8` operation while directly measuring executed and skipped multiplications.

## Baseline

The repository currently contains:

- `rtl/core/rv32_core.sv` as the unchanged scalar reference core;
- `rtl/core/rv32_core_pipe.sv` as the experimental scalar/vector integration core;
- a blocking, in-order, one-command-outstanding scalar/vector protocol;
- one shared 32 × 32-bit vector register file;
- four little-endian INT8 lanes per vector register;
- `VADD8`;
- signed dense `VDOT8`;
- one 256-byte byte-addressed vector scratchpad;
- aligned `VLOAD32` and `VSTORE32`;
- precise completion, retirement, scalar writeback, reset cancellation, redirect suppression, and error handling;
- canonical vector and full-regression targets.

## Relevant Context

Read:

- `AGENTS.md`
- `docs/codex_context.md`
- `docs/current_milestone.md`
- `docs/architecture/scalar_vector_interface.md`
- `docs/architecture/vector_vadd8.md`
- `docs/architecture/vector_memory.md`
- `docs/decisions/004_scalar_vector_protocol.md`
- `rtl/core/rv32_core_pipe.sv`
- `rtl/vector/rv32_vec_vadd_engine.sv`
- `tb/integration/tb_vector_vdot.sv`
- `tb/integration/tb_vector_vmem.sv`
- relevant vector Makefile targets.

Read additional files only when required by a concrete implementation or verification issue.

## Sparse Data Representation

Use a compressed two-weight representation.

For:

```text
VSDOT8 rd, va, vw, pattern
```

- `va` contains four signed INT8 activation lanes.
- `vw[7:0]` contains compressed nonzero weight 0.
- `vw[15:8]` contains compressed nonzero weight 1.
- `vw[31:16]` is reserved for this milestone and must not affect the result.
- `pattern` selects the two activation lanes receiving those weights.

For selected lane pair `{i, j}`:

```text
result =
    signed(va[i]) * signed(vw[7:0]) +
    signed(va[j]) * signed(vw[15:8])
```

The first compressed weight always maps to the lower-numbered selected lane and the second compressed weight maps to the higher-numbered selected lane.

Document this ordering explicitly.

## Valid Metadata Patterns

Use six legal 2-of-4 patterns:

| Pattern value | Selected activation lanes |
|---|---|
| `3'b000` | `{0,1}` |
| `3'b001` | `{0,2}` |
| `3'b010` | `{0,3}` |
| `3'b011` | `{1,2}` |
| `3'b100` | `{1,3}` |
| `3'b101` | `{2,3}` |

Reserve:

- `3'b110`
- `3'b111`

as invalid metadata encodings.

Invalid metadata must complete through the existing precise exception path and must not produce scalar or vector architectural writes.

## In Scope

### Sparse dot-product operation

Implement one experimental operation:

```text
VSDOT8 rd, va, vw, pattern
```

Requirements:

- two explicitly signed INT8 activation values;
- two explicitly signed INT8 compressed weights;
- two signed multiplications;
- each product represented with sufficient signed width;
- exact signed 32-bit accumulation;
- scalar completion result;
- one scalar destination register;
- no vector-register write;
- no scratchpad write;
- exactly one successful retirement;
- precise exception for invalid metadata.

### Existing architectural state

Reuse:

- the existing shared vector register file;
- the existing scalar/vector command-completion interface;
- the existing vector execution owner.

Do not create:

- a second vector-register array;
- a second architectural vector engine with copied state;
- a second scratchpad.

### Experimental encoding

Continue using Custom-0 opcode `0x0b`.

Assign an unused operation encoding for `VSDOT8`.

The encoding must carry:

- activation vector index;
- compressed-weight vector index;
- scalar destination register;
- 3-bit pattern metadata;
- issuing PC;
- scalar-result writeback intent.

Prefer to use existing instruction fields cleanly:

- `rs1` field for `va`;
- `rs2` field for `vw`;
- `rd` field for scalar destination;
- unused function or immediate bits for the 3-bit pattern.

The exact field mapping must be documented.

Do not conflict with existing operations:

- adapter stub operations;
- `VADD8`;
- `VDOT8`;
- `VLOAD32`;
- `VSTORE32`.

Unsupported operation encodings must remain precise illegal instructions.

## Dense Equivalence Model

For every legal sparse input, construct an equivalent dense four-lane weight vector:

- unselected lanes contain zero;
- the first compressed weight is placed in the lower-numbered selected lane;
- the second compressed weight is placed in the higher-numbered selected lane.

The sparse result must equal:

```text
VDOT8(activation, equivalent_dense_weight)
```

The testbench golden model must independently construct this equivalent dense vector.

Do not implement sparse correctness by merely calling the same RTL helper used for dense execution.

## Arithmetic Requirements

Use deliberate SystemVerilog signed conversions.

For each selected lane:

- activation is signed 8-bit;
- compressed weight is signed 8-bit;
- product is signed and at least 16 bits;
- products are sign-extended before 32-bit addition.

Required directed values include:

- zero activations;
- zero compressed weights;
- positive × positive;
- positive × negative;
- negative × positive;
- negative × negative;
- `-128 × -128`;
- `127 × 127`;
- cancellation to zero;
- mixed-sign result;
- maximum and minimum meaningful two-product cases;
- identical activation and weight vector indices;
- `v0` and `v31`.

## Compute Accounting

Expose or maintain direct event accounting for sparse compute.

For every successful `VSDOT8`:

- executed multiplication count increases by exactly 2;
- skipped multiplication count increases by exactly 2.

The accounting may be:

- per-operation debug outputs;
- cumulative debug counters;
- another bounded test-only mechanism.

Requirements:

- counters/events update exactly once per successful operation;
- no update before architectural completion;
- no update for invalid metadata;
- no update for reset-cancelled operations;
- no update for wrong-path instructions;
- no update for dense `VDOT8`, unless dense accounting is deliberately added and separately documented.

Prefer a test-only debug mechanism over a new architectural CSR in this milestone.

## Dense Baseline Comparison

Provide direct test evidence comparing sparse and dense behavior.

For each of the six legal metadata patterns:

1. Initialize one activation vector.
2. Initialize compressed sparse weights.
3. Build the equivalent dense weight vector.
4. Execute dense `VDOT8`.
5. Execute sparse `VSDOT8`.
6. Require identical scalar results.
7. Require dense conceptual multiply count of 4.
8. Require sparse executed count of 2.
9. Require sparse skipped count of 2.

The dense conceptual multiply count may be represented in the testbench if the dense RTL has no hardware counter.

The sparse hardware counts must be observed directly.

## Completion and Scalar Writeback

For a valid `VSDOT8`:

- completion status indicates success;
- completion result-valid is asserted;
- completion result contains the signed 32-bit sparse dot product;
- scalar `rd` is written once when `rd != x0`;
- `rd == x0` produces no scalar architectural write but still completes and retires;
- no vector-register write occurs;
- no scratchpad write occurs;
- successful retirement occurs exactly once.

Completion backpressure must preserve:

- result data;
- result-valid;
- status;
- cause;
- command ID;
- scalar destination metadata.

No scalar writeback, retirement, or compute-counter update may occur before completion handshake.

## Invalid Metadata Behavior

For patterns `3'b110` and `3'b111`:

- command may be accepted normally;
- completion must report a documented exception cause;
- issuing PC must be preserved;
- no scalar writeback;
- no vector-register write;
- no scratchpad write;
- no compute-counter update;
- exactly one trap;
- zero successful retirement.

Use a dedicated experimental cause or the existing vector-operation error convention, and document it.

Do not silently remap invalid patterns.

## Reset Behavior

Verify reset:

- after sparse command acceptance;
- during execution;
- while completion is valid but backpressured.

For cancelled operations require:

- no stale completion;
- no scalar writeback;
- no successful retirement;
- no vector-register write;
- no scratchpad write;
- no executed/skipped counter update.

A fresh post-reset `VSDOT8` must complete normally.

## Wrong-Path Suppression

Include a taken redirect containing a wrong-path `VSDOT8`.

Verify:

- zero command handshake attributable to the killed instruction;
- zero completion;
- zero scalar writeback;
- zero successful retirement;
- zero vector-register write;
- zero scratchpad write;
- zero compute-counter update;
- target-path execution continues correctly.

Track the wrong-path instruction by PC and destination where practical.

## Ordering and Dependencies

Cover:

```text
VSDOT8 x5, va, vw, pattern
ADDI   x6, x5, 1
```

The scalar consumer must immediately follow the sparse dot product in program order and observe the completed result.

Also cover:

- two consecutive sparse dot products;
- sparse followed by dense dot product;
- dense followed by sparse dot product;
- sparse operation after vector loads populate `va` and `vw`.

## Existing Feature Preservation

Preserve all behavior and regressions for:

- scalar/vector adapter stub;
- `VADD8`;
- dense `VDOT8`;
- `VLOAD32`;
- `VSTORE32`;
- scratchpad errors and commit semantics;
- reset cancellation;
- redirect suppression;
- scalar reference-core behavior.

## Out of Scope

Do not implement:

- more than one 2:4 group per instruction;
- vectors wider than 32 bits;
- general N:M sparsity;
- automatic pruning;
- sparse vector loads or stores;
- packed metadata in scratchpad memory;
- multiple sparse groups per register;
- persistent accumulators;
- vector result from sparse multiply;
- masks or predicates;
- INT16 sparse arithmetic;
- saturation or rounding;
- compiler, assembler, intrinsics, or model exporter;
- multiple outstanding commands;
- speculative or out-of-order execution;
- performance optimization;
- FPGA or ASIC implementation;
- changes to `rtl/core/rv32_core.sv`.

## Focused Development Tests

### Pattern coverage

Test all six legal patterns explicitly.

For every pattern verify:

- correct lane selection;
- correct compressed-weight ordering;
- correct sparse result;
- equality with equivalent dense result;
- exactly two executed multiplications;
- exactly two skipped multiplications.

### Invalid metadata

Test both invalid patterns:

- `3'b110`;
- `3'b111`.

Verify exact exception cause, PC, and zero architectural updates.

### Directed arithmetic

Cover:

- all zeros;
- one zero compressed weight;
- both zero compressed weights;
- positive values;
- negative values;
- mixed signs;
- `-128`;
- `127`;
- cancellation;
- identical `va` and `vw` indices;
- `v0`;
- `v31`;
- `rd == x0`.

### Backpressure

Command backpressure:

- hold ready low for a fixed number of cycles;
- verify complete sparse command payload stability;
- verify no completion or architectural event before acceptance;
- accept once.

Completion backpressure:

- hold completion ready low;
- verify complete completion payload stability;
- verify no scalar writeback, retirement, or compute-accounting update before handshake;
- commit once after readiness rises.

### Reset

Cover:

- reset while sparse operation is executing;
- reset while sparse completion is stalled;
- fresh post-reset operation.

### Redirect

Cover:

- wrong-path sparse instruction;
- valid target-path sparse instruction.

### Dependency and mixed execution

Cover:

- immediate dependent scalar ADDI;
- consecutive sparse operations;
- dense/sparse result comparison;
- sparse execution using activation and compressed weights loaded from scratchpad.

### Deterministic randomized equivalence

Use an independent testbench golden model.

Randomize:

- all four activation lanes;
- both compressed weights;
- all six valid patterns;
- activation and weight vector indices;
- scalar destination, including occasional x0;
- positive, negative, zero, and extreme lane values.

For each case:

- construct equivalent dense weight vector;
- compare sparse golden result with dense golden result;
- execute `VSDOT8`;
- compare completion and scalar architectural result;
- verify zero vector and scratchpad writes;
- verify executed count 2 and skipped count 2.

Use a fixed reported seed and at least 96 deterministic randomized cases, unless runtime becomes unreasonable. A smaller count requires documented justification.

## Event Accounting

Track directly:

- command handshakes;
- completion handshakes;
- successful sparse retirements;
- scalar writeback events;
- vector-register writes;
- scratchpad writes;
- traps;
- executed multiplications;
- skipped multiplications.

For successful non-x0 `VSDOT8`:

```text
commands = 1
completions = 1
successful retirements = 1
scalar writes = 1
vector writes = 0
scratchpad writes = 0
traps = 0
executed multiplications = 2
skipped multiplications = 2
```

For successful `rd == x0`:

```text
commands = 1
completions = 1
successful retirements = 1
scalar writes = 0
vector writes = 0
scratchpad writes = 0
traps = 0
executed multiplications = 2
skipped multiplications = 2
```

For invalid, reset-cancelled, or wrong-path operations, require zero compute-accounting and architectural write events.

## Assertions

Add or preserve meaningful assertions for:

- no second command while busy;
- command payload stability under backpressure;
- completion payload stability under backpressure;
- no completion without an accepted command;
- valid metadata selects exactly two distinct lanes;
- invalid metadata produces no architectural update;
- no vector-register write for `VSDOT8`;
- no scratchpad write for `VSDOT8`;
- scalar result-valid is asserted for successful `VSDOT8`;
- no scalar writeback before completion handshake;
- exactly two executed and two skipped multiplications per successful operation;
- no compute-accounting update before completion handshake;
- no compute-accounting update after reset cancellation;
- destination and pattern metadata remain stable while pending;
- at most one scalar architectural write per command;
- no duplicate completion or retirement.

Avoid tautological assertions.

## Canonical Targets

Add targets following repository conventions, including equivalents of:

```text
test-vector-vsdot-patterns
test-vector-vsdot-directed
test-vector-vsdot-backpressure
test-vector-vsdot-reset
test-vector-vsdot-redirect
test-vector-vsdot-invalid
test-vector-vsdot-random
test-vector-vsdot-all
```

Exact names may be adjusted to match existing conventions.

Update `test-vector-regression` to include:

- adapter/stub coverage;
- VADD8;
- dense VDOT8;
- vector memory;
- sparse VSDOT8.

Focused sparse tests must not duplicate the full scalar regression.

## Final Acceptance Regression

During development, run focused sparse tests only.

After implementation is stable, run once:

```text
make test-vector-regression
make test-full-regression
make lint
make check
make docs-check
git diff --check
```

## Acceptance Criteria

The milestone is complete only when:

1. One `VSDOT8` instruction exists.
2. It uses one four-lane activation vector.
3. It uses two compressed INT8 weights.
4. It supports all six legal 2-of-4 patterns.
5. It rejects both invalid metadata patterns precisely.
6. The first compressed weight maps to the lower selected lane.
7. The second compressed weight maps to the higher selected lane.
8. Exactly two signed INT8 multiplications execute.
9. Exactly two dense-equivalent multiplications are skipped.
10. Products use sufficient signed width.
11. Accumulation produces an exact signed 32-bit result.
12. Sparse results equal equivalent dense `VDOT8` results.
13. The existing shared vector-register file is reused.
14. No vector-register write occurs.
15. No scratchpad write occurs.
16. Scalar completion writeback is correct.
17. `rd == x0` completes without modifying x0.
18. Exactly one command is accepted.
19. Exactly one completion is accepted.
20. Exactly one successful retirement occurs.
21. Exactly one scalar write occurs for successful non-x0 operations.
22. Compute accounting updates exactly once on successful completion.
23. Command backpressure preserves the full payload.
24. Completion backpressure causes no early write or accounting update.
25. Reset cancels execution and stalled completion without stale effects.
26. Wrong-path sparse instructions produce no architectural or accounting effects.
27. Immediate scalar dependency works.
28. Consecutive sparse operations work.
29. Dense-to-sparse and sparse-to-dense ordering works.
30. Scratchpad-loaded inputs work.
31. All six valid patterns pass directed dense-equivalence tests.
32. Both invalid patterns pass precise exception tests.
33. Deterministic randomized equivalence testing passes.
34. Existing adapter, VADD8, VDOT8, vector-memory, and scalar regressions pass.
35. Documentation matches the implementation.
36. No wider vectors, general sparsity, sparse memory format, compiler support, masks, or INT16 logic is added.
37. `rtl/core/rv32_core.sv` remains unchanged.
38. Codex creates no commit or push.
39. `.codex/milestone_result.md` is written in compact format.

## Stop Conditions

Stop for human review only if:

- the current command payload cannot represent two vector indices, scalar destination, and 3-bit pattern;
- no unused experimental encoding is available;
- preserving one vector-register owner requires a major redesign;
- compute accounting requires architectural CSRs rather than bounded debug visibility;
- precise invalid-metadata exceptions conflict with the existing completion protocol;
- scalar writeback requires broad pipeline restructuring;
- multiple outstanding commands become necessary;
- a likely pre-existing scalar, vector, or memory correctness bug is discovered.

Ordinary metadata decode bugs, signedness errors, counter bugs, test failures, and documentation work are not stop conditions.

## Required Documentation

Update only materially affected files, normally:

- `docs/architecture/scalar_vector_interface.md`;
- a new sparse-execution architecture document;
- existing vector execution documentation where needed;
- `docs/implementation_status.md`;
- `docs/verification_plan.md`;
- `docs/milestone_history.md`;
- README only if stable user-facing commands change.

Document:

- exact `VSDOT8` encoding;
- compressed-weight layout;
- all six metadata patterns;
- invalid patterns;
- lane-to-weight ordering;
- signed arithmetic widths;
- scalar result behavior;
- compute-accounting semantics;
- reset and wrong-path behavior;
- dense-equivalence methodology;
- random seed and case count;
- remaining limitations.

Do not claim general sparse-vector support or complete 2:4 workload support beyond one four-lane group.

## Result File

Write `.codex/milestone_result.md` using the compact repository format.

Include:

- completion status;
- architecture chosen;
- exact encoding;
- metadata mapping;
- compressed-weight representation;
- signed arithmetic widths;
- scalar writeback behavior;
- multiplication executed/skipped accounting;
- all six legal-pattern results;
- both invalid-pattern results;
- randomized seed and case count;
- focused and final regression commands;
- changed files;
- bugs fixed;
- remaining limitations;
- confirmation that dense VDOT8 and vector memory remain passing;
- confirmation that `rtl/core/rv32_core.sv` is unchanged;
- confirmation that no commit or push occurred.