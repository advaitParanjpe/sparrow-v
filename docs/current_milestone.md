# Milestone: Vector Register File and 4-Lane INT8 VADD

## Objective

Implement the first genuine Sparrow-V vector execution path:

- an internal vector register file owned by the vector engine;
- a 4-lane, 32-bit vector datapath;
- one lane-wise wrapping INT8 vector-add operation;
- execution through the existing blocking scalar-to-vector command/completion protocol;
- focused verification with an independent golden model.

This milestone replaces the purely scalar-result stub as the only vector behavior with a real vector-register operation, while preserving the existing adapter and stub regression behavior.

## Baseline

The repository currently has:

- `rtl/core/rv32_core.sv` as the reference scalar core;
- `rtl/core/rv32_core_pipe.sv` as the experimental scalar/vector integration core;
- a verified Custom-0 command/completion interface;
- one blocking, in-order vector command outstanding;
- precise successful completion and exception handling;
- command and completion backpressure verification;
- reset cancellation and wrong-path suppression;
- `rtl/vector/rv32_vec_stub_engine.sv` for protocol verification;
- canonical scalar, vector, and full-regression targets.

The existing scalar/vector protocol must remain compatible.

## Relevant Context

Read:

- `AGENTS.md`
- `docs/codex_context.md`
- `docs/architecture/scalar_vector_interface.md`
- `docs/decisions/004_scalar_vector_protocol.md`
- `docs/current_milestone.md`
- `rtl/core/rv32_core_pipe.sv`
- `rtl/vector/rv32_vec_stub_engine.sv`
- `tb/integration/tb_scalar_pipe_vec_stub.sv`
- relevant Makefile targets and vector-test helpers.

Read additional files only when required by the implementation.

## In Scope

### Vector register file

Implement an internal vector register file with:

- 32 vector registers unless an existing approved specification requires another count;
- 32 bits per vector register;
- four 8-bit lanes per register;
- two logical read operands;
- one write destination;
- synchronous or combinational reads chosen deliberately and documented;
- one architectural write per completed vector operation;
- reset behavior defined and verified;
- vector register state owned entirely by the vector engine.

Vector register `v0` is a normal register unless an existing architecture decision explicitly reserves it.

Do not infer scalar `x0` semantics for vector registers.

### INT8 vector addition

Implement one genuine vector operation:

```text
VADD8 vd, vs1, vs2
```

Semantics for each lane `i`:

```text
vd[i] = (vs1[i] + vs2[i]) mod 256
```

Requirements:

- four independent 8-bit additions;
- wrapping two’s-complement arithmetic;
- no saturation;
- signed and unsigned interpretations produce the same stored 8-bit sum;
- source registers are read from the vector register file;
- result is written to the vector destination register;
- the operation produces no scalar register writeback;
- the instruction retires exactly once after vector-register write completion;
- the operation uses the existing command/completion protocol.

### Experimental encoding

Use the existing Custom-0 opcode `0x0b`.

Choose and document a currently unused `funct3` value for `VADD8`.

The command must carry:

- `vs1`;
- `vs2`;
- `vd`;
- operation identifier;
- issuing PC;
- fixed command ID and other protocol metadata already required.

Do not redesign the entire vector instruction encoding.

The encoding remains experimental and is not the final Sparrow-V ISA.

### Test-only vector-register access

Provide a bounded verification mechanism for initializing and observing vector registers.

Preferred approaches, in order:

1. testbench-visible debug ports on a development wrapper or vector engine;
2. clearly isolated simulation-only tasks or hierarchical access;
3. temporary experimental Custom-0 register-transfer operations only if necessary.

The mechanism must:

- not alter the scalar architectural interface;
- not be presented as part of the final vector ISA;
- not introduce vector memory behavior;
- be clearly documented as test-only.

Avoid adding a broad software-visible debug architecture.

### Existing stub behavior

Preserve the existing scalar/vector protocol regression path.

Either:

- retain `rv32_vec_stub_engine.sv` for adapter-focused tests and add a separate real vector engine module; or
- evolve the current vector module while keeping all existing adapter/stub tests working through a dedicated compatibility mode.

Prefer a clean separation if it avoids mixing protocol-test behavior with architectural vector state.

Do not delete useful adapter regression coverage.

## Out of Scope

Do not implement:

- vector loads or stores;
- scalar-to-vector data movement as a final ISA feature;
- vector memory interface;
- scratchpad memory;
- banked memory;
- INT16 execution;
- vector subtraction;
- vector multiplication;
- dot product;
- widening accumulation;
- reductions;
- masks or predicates;
- saturation;
- configurable vector length;
- tail or mask policies;
- sparse metadata;
- 2:4 sparsity;
- gather or scatter;
- compiler, assembler, or intrinsics;
- performance optimization;
- FPGA or ASIC implementation;
- promotion of `rv32_core_pipe`;
- changes to `rtl/core/rv32_core.sv`.

## Required Behavior

### Command acceptance

A `VADD8` command is accepted only on:

```text
vec_cmd_valid && vec_cmd_ready
```

Verify:

- command payload stability under backpressure;
- vector source and destination indices are captured once;
- no duplicate command is accepted;
- no command is accepted while another is outstanding;
- wrong-path `VADD8` instructions are not issued.

### Execution

After command acceptance:

- the vector engine reads `vs1` and `vs2`;
- computes four wrapping INT8 sums;
- writes the complete 32-bit result to `vd`;
- does not expose a partially updated destination;
- does not produce scalar result-valid or scalar writeback;
- produces one successful completion.

Source/destination aliasing must work correctly:

- `vd == vs1`;
- `vd == vs2`;
- `vs1 == vs2`;
- `vd == vs1 == vs2`.

Source values must reflect the pre-instruction architectural state.

### Completion and retirement

The vector-register write must become architecturally visible exactly once.

Completion requirements:

- no vector-register write before the operation is committed to complete;
- no scalar retirement before completion handshake;
- completion payload remains stable under completion backpressure;
- exactly one completion handshake;
- exactly one successful vector retirement;
- zero scalar register writes for `VADD8`;
- no trap for a valid `VADD8`;
- younger scalar instructions do not retire before the blocking vector instruction completes;
- scalar execution resumes correctly afterward.

Define clearly whether the vector-register write occurs:

- when completion becomes valid; or
- when completion handshakes.

Prefer completion-handshake commit semantics unless the existing protocol or implementation structure strongly requires another safe model.

If write visibility occurs before completion handshake, prove that reset and completion backpressure cannot expose an unretired architectural update.

### Reset

Verify reset:

- clears engine busy and pending-operation state;
- cancels an accepted but uncompleted `VADD8`;
- prevents a cancelled instruction from writing `vd`;
- prevents stale completion or retirement;
- allows a fresh post-reset `VADD8` to execute normally.

Do not require all vector registers to reset to zero unless deliberately chosen.

If vector registers are not reset, tests must initialize every register they observe.

### Invalid encoding

Unsupported Custom-0 vector-operation encodings must retain the existing defined behavior:

- precise illegal-instruction handling; or
- another already documented experimental exception path.

Do not silently treat unsupported vector operations as `VADD8`.

## Implementation Guidance

Use parameterization where it improves clarity without overengineering.

Suggested constants:

```text
VLEN = 32
LANES = 4
SEW = 8
VREG_COUNT = 32
```

Include elaboration-time checks where practical:

- `VLEN == LANES * SEW`;
- register-index width is sufficient;
- lane count and element width are positive.

Keep the arithmetic structurally clear enough that future `VSUB8`, `VMUL8`, INT16, and dot-product operations can be added without rewriting the register file.

Do not build a generic vector execution framework far beyond what `VADD8` needs.

## Focused Development Tests

Add focused tests and canonical targets covering at least:

### Register-file behavior

- independent initialization and observation;
- two-source read;
- one-destination write;
- no unintended register changes;
- highest and lowest register indices;
- vector-register zero is writable unless explicitly reserved.

### Basic VADD8

Use an independent testbench golden model.

Cover:

- ordinary positive lane values;
- zero inputs;
- per-lane carry and wrapping;
- `0x7f + 0x01 = 0x80`;
- `0xff + 0x01 = 0x00`;
- negative two’s-complement values;
- mixed independent lane values;
- all four lanes active.

### Aliasing

Cover:

- `vd == vs1`;
- `vd == vs2`;
- `vs1 == vs2`;
- all indices equal.

### Protocol integration

Cover:

- immediate command acceptance;
- command backpressure;
- completion backpressure;
- exactly one command;
- exactly one completion;
- exactly one vector retirement;
- zero scalar vector-result writes;
- scalar instruction before and after `VADD8`;
- no younger retirement before completion;
- wrong-path `VADD8` suppression;
- reset while `VADD8` is outstanding;
- no stale completion or vector-register write after reset.

### Sequential dependence

Cover at least one chain:

```text
VADD8 v3, v1, v2
VADD8 v4, v3, v1
```

Verify the second instruction observes the committed result of the first.

### Randomized arithmetic

Run deterministic randomized testing across:

- source values;
- vector register indices;
- destination aliases;
- lane overflow patterns.

Use a fixed seed or a reported deterministic seed set.

Compare every result against an independent software-style golden model in the testbench.

A modest bounded run is sufficient; broad ISA randomization is not required.

## Assertions

Add or preserve assertions for:

- no second command while busy;
- no completion without an outstanding command;
- command payload stability under backpressure;
- completion payload stability under backpressure;
- no vector-register write without a valid accepted operation;
- at most one vector-register write per command;
- destination index remains stable while an operation is pending;
- no scalar writeback for `VADD8`;
- no successful retirement before completion acceptance;
- reset cancels pending writeback;
- no duplicate completion or retirement.

Avoid assertions that depend on testbench-only hierarchy when a local module property is possible.

## Canonical Targets

Add clear targets following repository conventions, including equivalents of:

```text
test-vector-regfile
test-vector-vadd-directed
test-vector-vadd-alias
test-vector-vadd-backpressure
test-vector-vadd-reset
test-vector-vadd-random
test-vector-vadd-all
```

Exact target names may be adjusted to match existing conventions.

Update `test-vector-regression` to include the completed vector-register/VADD tests while preserving adapter/stub regression coverage.

Do not duplicate the entire scalar regression inside focused vector targets.

## Final Acceptance Regression

After focused tests are stable, run once:

```text
make test-vector-regression
make test-full-regression
make lint
make check
make docs-check
git diff --check
```

Do not repeatedly run the full regression during normal edit/debug cycles.

## Acceptance Criteria

The milestone is complete only when:

1. A real internal vector register file exists.
2. The register file contains 32-bit registers interpreted as four INT8 lanes.
3. Two vector sources and one vector destination are supported.
4. A real `VADD8` operation executes lane-wise wrapping addition.
5. The operation reads and writes vector architectural state.
6. Source/destination aliasing is correct.
7. `VADD8` uses the existing blocking command/completion protocol.
8. Exactly one command is accepted per instruction.
9. Exactly one completion is accepted per instruction.
10. Exactly one successful vector retirement occurs.
11. No scalar register writeback occurs for `VADD8`.
12. Completion backpressure does not duplicate or prematurely commit the operation.
13. Command backpressure preserves all relevant payload fields.
14. Reset cancels pending execution without changing the destination.
15. Wrong-path `VADD8` instructions do not issue or change vector state.
16. Sequential dependent vector operations observe committed results.
17. Directed arithmetic tests pass.
18. Deterministic randomized golden-model tests pass.
19. Existing scalar/vector adapter tests continue to pass.
20. Full scalar regression remains passing.
21. Unsupported vector encodings are not silently executed as `VADD8`.
22. Documentation is updated factually.
23. No vector memory, scratchpad, INT16, multiplication, dot product, masks, reductions, or sparsity is added.
24. `rtl/core/rv32_core.sv` remains unchanged.
25. No commit or push is performed by Codex.
26. `.codex/milestone_result.md` is written in the required compact format.

## Stop Conditions

Stop for human review only if:

- the existing command payload cannot represent `vs1`, `vs2`, and `vd`;
- implementing vector architectural state requires a material scalar-interface redesign;
- precise vector-register commit conflicts with the approved completion protocol;
- Custom-0 encoding conflicts with existing implemented instructions;
- reset semantics cannot prevent an unretired vector-register update;
- direct integration requires substantial scalar-pipeline restructuring;
- a likely pre-existing scalar or adapter correctness bug is discovered;
- the milestone would require vector memory or multiple outstanding commands.

Ordinary RTL bugs, test failures, encoding selection, alias handling, and documentation work are not stop conditions.

## Required Documentation

Update only materially affected files, normally:

- `docs/architecture/scalar_vector_interface.md`;
- the relevant vector architecture document, creating one concise document if none exists;
- `docs/implementation_status.md`;
- `docs/verification_plan.md`;
- `docs/milestone_history.md`;
- README only for stable user-facing commands.

Document:

- vector-register organization;
- VLEN, lane count, and element width;
- read/write behavior;
- `VADD8` semantics;
- experimental encoding;
- aliasing behavior;
- architectural commit point;
- reset behavior;
- test-only initialization/observation mechanism;
- verification targets;
- remaining limitations.

Do not present this milestone as a complete vector ISA or complete vector processor.

## Result File

Write `.codex/milestone_result.md` using the repository’s compact result format.

Include:

- completion status;
- architecture chosen;
- VADD8 encoding;
- register-file organization;
- commit semantics;
- focused test commands and results;
- randomized test seed/count;
- final regression commands and results;
- bugs fixed;
- changed files;
- remaining limitations;
- confirmation that no vector memory, scratchpad, INT16, multiplication, dot product, masks, reductions, or sparsity was implemented;
- confirmation that `rtl/core/rv32_core.sv` was unchanged;
- confirmation that no commit or push occurred.