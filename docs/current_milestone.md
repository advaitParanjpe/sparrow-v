# Milestone: Signed INT8 Vector Dot Product

## Objective

Implement Sparrow-V’s first AI-oriented vector arithmetic operation:

```text
VDOT8 rd, vs1, vs2
```

`VDOT8` reads two 32-bit vector registers as four signed INT8 lanes, multiplies corresponding lanes, sums the four signed products into a signed 32-bit result, and writes that result to a scalar register.

The milestone must reuse the existing blocking scalar/vector command-completion protocol and preserve the existing VADD8 vector-register implementation and regression coverage.

## Baseline

The repository currently contains:

- `rtl/core/rv32_core.sv` as the unchanged scalar reference core;
- `rtl/core/rv32_core_pipe.sv` as the experimental scalar/vector integration core;
- a verified blocking, in-order, one-command-outstanding scalar/vector protocol;
- a 32 × 32-bit vector register file;
- four little-endian INT8 lanes per vector register;
- a verified wrapping `VADD8` operation;
- vector-register writes committed on completion handshake;
- command and completion backpressure handling;
- reset cancellation;
- wrong-path suppression;
- precise vector success and exception retirement;
- canonical vector and full-regression targets.

## Relevant Context

Read:

- `AGENTS.md`
- `docs/codex_context.md`
- `docs/current_milestone.md`
- `docs/architecture/scalar_vector_interface.md`
- `docs/architecture/vector_vadd8.md`
- `docs/decisions/004_scalar_vector_protocol.md`
- `rtl/core/rv32_core_pipe.sv`
- `rtl/vector/rv32_vec_vadd_engine.sv`
- `tb/integration/tb_vector_vadd.sv`
- relevant vector Makefile targets.

Read additional files only when a concrete implementation or verification need requires them.

## In Scope

### Signed INT8 dot product

Implement:

```text
VDOT8 rd, vs1, vs2
```

For each lane `i` from 0 through 3:

```text
a_i = signed(vs1[8*i +: 8])
b_i = signed(vs2[8*i +: 8])
p_i = a_i * b_i
```

The scalar result is:

```text
rd = p_0 + p_1 + p_2 + p_3
```

Requirements:

- four signed INT8 multiplications;
- each product represented with sufficient signed width;
- accumulation into a signed 32-bit result;
- no saturation;
- no truncation of the mathematically valid four-lane INT8 dot product;
- the result returned through the existing scalar completion-result path;
- scalar `rd` written exactly once;
- no vector-register write for `VDOT8`;
- exactly one successful retirement;
- no exception for a valid instruction.

The full possible result range fits comfortably in signed 32 bits.

### Existing vector state

Reuse the existing 32 × 32-bit vector register file.

`VDOT8` must:

- read `vs1` and `vs2` from vector architectural state;
- leave every vector register unchanged;
- support `vs1 == vs2`;
- correctly read `v0` and `v31`;
- preserve all existing `VADD8` behavior.

Do not duplicate the vector register file across separate architectural engines.

If the current VADD-specific engine structure would create duplicate state, refactor it into a shared vector execution engine or shared vector-register owner while preserving behavior and tests.

### Experimental encoding

Continue using Custom-0 opcode `0x0b`.

Assign an unused experimental operation encoding for `VDOT8`.

The chosen encoding must:

- not conflict with existing stub operations;
- not conflict with `VADD8` at `funct3=011`;
- identify two vector source indices;
- identify one scalar destination register;
- indicate scalar-result writeback;
- remain explicitly experimental rather than final ISA design.

Use the existing instruction-field mapping where practical:

- `rs1` field as `vs1`;
- `rs2` field as `vs2`;
- `rd` field as scalar destination `rd`.

Document the exact encoding.

Unsupported encodings must continue to follow the existing precise illegal-instruction behavior.

### Scalar-result completion

For a valid `VDOT8` completion:

- completion status indicates success;
- completion result-valid is asserted;
- completion result contains the signed 32-bit dot product;
- the scalar pipeline writes the result to `rd`;
- scalar `x0` remains zero if `rd == x0`;
- no vector-register write occurs;
- retirement occurs exactly once after completion acceptance.

## Out of Scope

Do not implement:

- vector multiply producing a vector destination;
- vector subtraction;
- multiply-accumulate with persistent accumulator state;
- vector accumulator registers;
- INT16 arithmetic;
- saturation;
- rounding;
- configurable vector length;
- masks or predicates;
- reductions other than this fixed four-lane dot product;
- vector loads or stores;
- vector memory interface;
- scratchpad memory;
- banked memory;
- sparse metadata;
- 2:4 sparse execution;
- compiler, assembler, or intrinsics;
- multiple outstanding vector commands;
- speculative or out-of-order vector execution;
- FPGA or ASIC implementation;
- promotion of `rv32_core_pipe`;
- changes to `rtl/core/rv32_core.sv`.

## Required Behavior

### Command acceptance

A `VDOT8` command is accepted only on:

```text
vec_cmd_valid && vec_cmd_ready
```

Verify:

- command payload stability while ready is low;
- `vs1`, `vs2`, scalar `rd`, issuing PC, operation identifier, and writeback intent are captured correctly;
- no duplicate command acceptance;
- no second command while one is outstanding;
- no command for a killed or wrong-path instruction.

### Arithmetic correctness

The implementation must use explicitly signed arithmetic.

Avoid relying on implicit SystemVerilog signedness across packed slices.

Each 8-bit lane should be converted deliberately to a signed value before multiplication.

Each product must be wide enough for:

```text
-128 × -128 = 16384
```

The four products must be sign-extended correctly before accumulation.

Directed cases must include:

- all-zero operands;
- positive × positive;
- positive × negative;
- negative × negative;
- `-128 × -128`;
- `127 × 127`;
- mixed signs across lanes;
- products that cancel to zero;
- all lanes at positive extremes;
- all lanes at negative/extreme combinations;
- `vs1 == vs2`;
- use of `v0`;
- use of `v31`.

Explicit expected examples should include:

```text
[1, 2, 3, 4] dot [5, 6, 7, 8] = 70
```

```text
[127, 127, 127, 127] dot [127, 127, 127, 127] = 64516
```

```text
[-128, -128, -128, -128] dot [-128, -128, -128, -128] = 65536
```

```text
[1, -1, 2, -2] dot [4, 4, 3, 3] = 0
```

### Completion and scalar writeback

Verify:

- completion payload is held stable under completion backpressure;
- no scalar writeback occurs before completion handshake;
- exactly one scalar write occurs after successful completion;
- scalar write destination equals instruction `rd`;
- scalar write data equals the golden dot-product result;
- exactly one successful retirement occurs;
- no vector-register write occurs;
- younger scalar instructions do not retire before the blocking vector operation completes;
- scalar execution resumes correctly afterward.

### Destination behavior

Cover:

- ordinary destination register;
- `rd == x0`, where completion and retirement occur but x0 remains zero;
- a following scalar instruction consuming the dot-product result;
- consecutive `VDOT8` instructions with different scalar destinations;
- scalar source/destination activity around the vector instruction without corruption.

### Reset

Verify reset while `VDOT8` is outstanding:

- clears pending execution and completion state;
- produces no stale completion;
- produces no scalar writeback;
- produces no retirement;
- produces no vector-register write;
- allows a fresh post-reset `VDOT8` to complete normally.

Vector-register contents should remain consistent with the existing VADD8 reset contract.

### Wrong-path suppression

Include a taken redirect with a wrong-path `VDOT8`.

Verify:

- zero command handshake for the wrong-path instruction;
- zero completion;
- zero scalar writeback;
- zero successful vector retirement;
- target-path execution proceeds;
- a valid target-path `VDOT8`, if used, completes exactly once.

Track the suppressed instruction by PC and expected destination where practical.

### Existing VADD8 preservation

All existing VADD8 behavior must remain valid:

- vector-register state;
- wrapping lane arithmetic;
- aliases;
- dependent chains;
- command/completion backpressure;
- reset;
- wrong-path suppression;
- unsupported encoding behavior;
- exact vector-register write accounting.

## Architecture Guidance

Prefer a single architectural owner for the vector register file.

A reasonable implementation is to evolve the VADD engine into a more general vector execution engine that supports:

- VADD8 with vector destination and no scalar result;
- VDOT8 with scalar destination and no vector write.

Do not introduce duplicate vector-register arrays in separate engines.

Keep operation-specific pending metadata explicit:

- operation type;
- destination kind;
- vector destination when applicable;
- scalar result when applicable;
- completion result-valid;
- pending result data.

Preserve the existing command/completion interface unless a small, clearly justified extension is necessary.

## Focused Development Tests

Add focused tests and canonical targets for:

### Directed arithmetic

- all required named arithmetic cases;
- explicit expected 32-bit signed results;
- positive and negative values;
- extreme values;
- cancellation;
- `vs1 == vs2`;
- `v0` and `v31`.

### Scalar writeback

- correct `rd`;
- correct result data;
- exactly one scalar write;
- no vector-register write;
- `rd == x0`;
- dependent scalar consumer immediately after completion.

### Backpressure

Command backpressure:

- hold command ready low for a fixed number of cycles;
- verify full payload stability;
- verify no completion, writeback, or retirement before acceptance;
- accept exactly once.

Completion backpressure:

- hold completion ready low;
- verify completion status, result-valid, result data, cause, and ID remain stable;
- verify no scalar writeback or retirement before handshake;
- verify exactly one writeback and retirement afterward.

### Reset

- accept `VDOT8`;
- reset before completion;
- verify zero completion/writeback/retirement;
- execute a fresh command successfully after reset.

### Wrong-path suppression

- place `VDOT8` behind a taken redirect;
- prove it generates no vector or scalar architectural event;
- prove target-path execution continues.

### Consecutive and dependent execution

Cover:

```text
VDOT8 x5, v1, v2
ADDI  x6, x5, 1
```

and at least two consecutive dot products writing different scalar registers.

### Deterministic randomized testing

Use an independent testbench golden model.

Randomize:

- all lane values;
- `vs1` and `vs2` indices;
- equal-source cases;
- scalar destination including occasional x0;
- positive, negative, and extreme patterns.

Use a fixed reported seed and a bounded but meaningful number of cases.

Compare:

- completion result;
- scalar retirement result;
- scalar register state;
- absence of vector-register writes.

## Event Accounting

Track directly:

- command handshakes;
- completion handshakes;
- scalar writeback events caused by `VDOT8`;
- successful `VDOT8` retirements;
- vector-register write events;
- traps.

For each successful non-x0 `VDOT8`:

```text
commands = 1
completions = 1
scalar writes = 1
successful retirements = 1
vector writes = 0
traps = 0
```

For successful `rd == x0`:

```text
commands = 1
completions = 1
scalar architectural writes = 0
successful retirements = 1
vector writes = 0
traps = 0
```

For reset-cancelled or wrong-path operations, require all applicable event counts to remain zero.

## Assertions

Add or preserve meaningful assertions for:

- no second command while busy;
- command payload stability under backpressure;
- completion payload stability under backpressure;
- no completion without an accepted command;
- no scalar writeback before completion handshake;
- no vector-register write for `VDOT8`;
- VADD8 never asserts scalar result-valid;
- VDOT8 always asserts scalar result-valid on successful completion;
- at most one architectural destination write per command;
- destination metadata stability while pending;
- reset clears pending completion/writeback state;
- no duplicate completion or retirement.

Avoid tautological assertions.

## Canonical Targets

Add clear targets following repository conventions, including equivalents of:

```text
test-vector-vdot-directed
test-vector-vdot-backpressure
test-vector-vdot-reset
test-vector-vdot-redirect
test-vector-vdot-random
test-vector-vdot-invalid
test-vector-vdot-all
```

Exact names may be adjusted to fit existing conventions.

Update:

```text
test-vector-regression
```

to include both:

- existing scalar/vector stub coverage;
- existing VADD8 coverage;
- new VDOT8 coverage.

Focused VDOT8 targets must not duplicate the full scalar regression.

## Final Acceptance Regression

During development, run only focused VDOT8 tests and affected vector tests.

After the implementation is stable, run once:

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

1. `VDOT8` performs four signed INT8 multiplications.
2. Products are represented with correct signed width.
3. Products are accumulated into an exact signed 32-bit result.
4. The existing vector register file is reused rather than duplicated.
5. `VDOT8` leaves all vector registers unchanged.
6. `VDOT8` returns its result through scalar completion writeback.
7. Scalar destination `rd` is correct.
8. `rd == x0` preserves x0 while still completing and retiring.
9. Exactly one command is accepted.
10. Exactly one completion is accepted.
11. Exactly one scalar write occurs for successful non-x0 operations.
12. Exactly one successful vector retirement occurs.
13. Zero vector-register writes occur for `VDOT8`.
14. Command backpressure preserves the complete payload.
15. Completion backpressure preserves the complete completion payload.
16. No writeback or retirement occurs before completion handshake.
17. Reset cancels an outstanding operation with no stale effects.
18. Wrong-path `VDOT8` does not issue or change architectural state.
19. A scalar consumer correctly observes the completed dot-product result.
20. Consecutive dot products execute correctly.
21. Directed arithmetic corner cases pass.
22. Deterministic randomized golden-model tests pass.
23. Unsupported encodings retain precise illegal behavior.
24. Existing VADD8 and adapter regressions remain passing.
25. Full scalar regression remains passing.
26. Documentation matches the implementation.
27. No vector memory, scratchpad, INT16, masks, sparsity, or compiler support is added.
28. `rtl/core/rv32_core.sv` remains unchanged.
29. Codex creates no commit or push.
30. `.codex/milestone_result.md` is written in compact format.

## Stop Conditions

Stop for human review only if:

- the existing command payload cannot represent two vector sources and a scalar destination;
- preserving one vector-register owner requires a major architecture redesign;
- signed dot-product writeback conflicts with the approved completion protocol;
- no unused experimental encoding is available;
- precise scalar writeback requires broad pipeline restructuring;
- reset cannot cancel pending scalar-result completion safely;
- multiple outstanding commands become necessary;
- a likely pre-existing scalar, adapter, or VADD8 correctness bug is discovered.

Ordinary signedness bugs, arithmetic-width errors, test failures, refactoring of the vector engine, and documentation updates are not stop conditions.

## Required Documentation

Update only materially affected files, normally:

- `docs/architecture/scalar_vector_interface.md`;
- the vector execution architecture document, either extending `vector_vadd8.md` or creating a concise shared vector execution document;
- `docs/implementation_status.md`;
- `docs/verification_plan.md`;
- `docs/milestone_history.md`;
- README only if stable user-facing test commands change.

Document:

- exact experimental encoding;
- signed lane interpretation;
- product widths;
- accumulation semantics;
- scalar result behavior;
- vector-state non-modification;
- completion and writeback timing;
- reset and wrong-path behavior;
- focused test targets;
- random seed and case count;
- remaining limitations.

Do not present `VDOT8` as a complete vector ISA or full AI accelerator.

## Result File

Write `.codex/milestone_result.md` using the repository’s compact format.

Include:

- completion status;
- architecture/refactor chosen;
- VDOT8 encoding;
- signed arithmetic implementation;
- scalar writeback behavior;
- vector-register non-write evidence;
- focused test commands and results;
- random seed and case count;
- final regression commands and results;
- bugs fixed;
- changed files;
- remaining limitations;
- confirmation that VADD8 remains passing;
- confirmation that `rtl/core/rv32_core.sv` is unchanged;
- confirmation that no commit or push occurred.