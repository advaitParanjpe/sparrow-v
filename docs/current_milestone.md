# Milestone: Vector Load/Store and Tightly Coupled Scratchpad

## Objective

Add the first software-visible vector data-movement path to Sparrow-V:

- a small tightly coupled vector scratchpad;
- aligned 32-bit vector loads into the existing vector register file;
- aligned 32-bit vector stores from the existing vector register file;
- execution through the existing blocking scalar/vector command-completion protocol;
- precise completion, reset, redirect, and error behavior.

This milestone must preserve the existing VADD8 and VDOT8 implementation and keep a single architectural owner for the vector register file.

## Baseline

The repository currently contains:

- `rtl/core/rv32_core.sv` as the unchanged scalar reference core;
- `rtl/core/rv32_core_pipe.sv` as the experimental scalar/vector integration core;
- a verified blocking, in-order, one-command-outstanding scalar/vector interface;
- one shared 32 × 32-bit vector register file;
- four little-endian INT8 lanes per vector register;
- `VADD8` with vector destination;
- signed `VDOT8` with scalar destination;
- command and completion backpressure;
- precise retirement and scalar writeback;
- reset cancellation and wrong-path suppression;
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
- `tb/integration/tb_vector_vdot.sv`
- relevant Makefile targets.

Read additional files only when required by a concrete implementation or verification issue.

## In Scope

### Vector scratchpad

Implement one small vector scratchpad owned by the vector subsystem.

Initial required configuration:

- byte-addressed architectural address space;
- 32-bit data words;
- at least 256 bytes of storage;
- naturally aligned 32-bit accesses only;
- one blocking access at a time;
- deterministic access latency;
- synthesizable RTL;
- parameterized depth where useful;
- no duplicated scratchpad instances across operations.

The exact default depth may be larger than 256 bytes if an existing architecture decision supports it, but keep the implementation bounded.

Define and document:

- valid address range;
- alignment requirements;
- little-endian byte organization;
- read latency;
- write commit point;
- reset behavior;
- out-of-range behavior.

Scratchpad contents do not need to reset to zero. Tests must initialize all locations they inspect.

### Vector load

Implement an experimental instruction:

```text
VLOAD32 vd, offset(rs1)
```

Semantics:

1. Read scalar base address from `rs1`.
2. Add the instruction immediate.
3. Require a naturally aligned 32-bit address.
4. Read one 32-bit word from the vector scratchpad.
5. Write the complete word into vector register `vd`.
6. Complete and retire exactly once.
7. Produce no scalar register writeback.

The loaded 32-bit word maps directly to the existing vector lane organization:

- lane 0: bits `[7:0]`;
- lane 1: bits `[15:8]`;
- lane 2: bits `[23:16]`;
- lane 3: bits `[31:24]`.

### Vector store

Implement an experimental instruction:

```text
VSTORE32 vs, offset(rs1)
```

Semantics:

1. Read scalar base address from `rs1`.
2. Add the instruction immediate.
3. Require a naturally aligned 32-bit address.
4. Read the complete 32-bit value from vector register `vs`.
5. Write that value to the vector scratchpad.
6. Complete and retire exactly once.
7. Produce no scalar register writeback.
8. Produce no vector-register write.

### Experimental encoding

Continue using Custom-0 opcode `0x0b`.

Assign unused experimental encodings for `VLOAD32` and `VSTORE32`.

The encoding must represent:

- operation type;
- scalar base register;
- vector source or destination register;
- signed address immediate;
- issuing PC;
- no scalar destination writeback.

Prefer an encoding that reuses ordinary RISC-V instruction fields cleanly.

Document the exact field mapping. Do not redesign the entire vector ISA.

Existing encodings must remain intact:

- adapter stub operations;
- `VADD8`;
- `VDOT8`.

Unsupported encodings must retain precise illegal-instruction behavior.

## Architectural Ownership

Preserve exactly one architectural vector-register array.

The vector execution subsystem must coordinate:

- arithmetic operations;
- vector loads;
- vector stores;
- scratchpad accesses.

Do not create a separate load/store engine with a duplicated vector register file.

A separate scratchpad module and a bounded internal load/store controller are acceptable.

## Address Generation

Use explicit 32-bit address generation:

```text
effective_address = scalar_base + sign_extended_immediate
```

Verify:

- positive offsets;
- negative offsets;
- zero offset;
- lowest valid address;
- highest valid aligned address;
- arithmetic wrap is not silently treated as a valid in-range address.

The effective byte address, not a word index, is architectural.

## Alignment and Range Errors

Define precise failure behavior for:

- address not divisible by four;
- address outside the implemented scratchpad range.

Preferred behavior:

- complete through the existing exceptional-completion path;
- produce a documented cause code;
- preserve the issuing PC;
- perform no vector-register write for a failed load;
- perform no scratchpad write for a failed store;
- produce no scalar writeback;
- trap exactly once.

If existing project conventions require another bounded behavior, document and verify it.

Do not silently align addresses or wrap out-of-range accesses.

## Commit Semantics

### Load commit

A vector load must write `vd` only on successful completion handshake.

Before completion handshake:

- destination vector register remains unchanged;
- completion payload remains stable under backpressure;
- reset can cancel the operation without updating `vd`.

### Store commit

A vector store must update scratchpad memory only at a clearly defined architectural commit point.

Prefer successful completion handshake.

Before the commit point:

- scratchpad contents remain unchanged;
- completion backpressure must not duplicate the store;
- reset can cancel an outstanding store without changing memory.

If the scratchpad write occurs earlier internally, the design must provide rollback or prove that the write is not architecturally visible before completion. Avoid this complexity by committing at completion handshake.

## Existing Operation Preservation

Preserve all existing behavior for:

- adapter stub operations;
- `VADD8`;
- `VDOT8`;
- vector register aliases;
- signed dot-product arithmetic;
- scalar writeback;
- reset;
- wrong-path suppression;
- unsupported encoding;
- exact event accounting.

Existing arithmetic operations must not unintentionally access the scratchpad.

## Out of Scope

Do not implement:

- scalar access to the vector scratchpad as a final architectural feature;
- shared scalar/vector data memory;
- caches;
- AXI, AHB, APB, TileLink, or other external buses;
- DMA;
- bursts;
- multiple outstanding accesses;
- unaligned accesses;
- byte or halfword vector transfers;
- vector lengths larger than 32 bits;
- gather or scatter;
- masks or predicates;
- bank conflicts or multi-bank scheduling;
- dual-port memory;
- arbitration between multiple clients;
- INT16 arithmetic;
- vector multiply producing a vector result;
- persistent accumulators;
- sparse metadata;
- 2:4 sparse execution;
- compiler or assembler support;
- FPGA or ASIC optimization;
- promotion of `rv32_core_pipe`;
- changes to `rtl/core/rv32_core.sv`.

## Test-Only Scratchpad Access

Provide a bounded verification mechanism for initializing and observing scratchpad contents.

Preferred options:

1. test/debug ports on the vector subsystem;
2. isolated testbench hierarchical access;
3. simulation-only helper tasks.

The mechanism must:

- be clearly test-only;
- not become a software-visible production interface;
- allow deterministic memory initialization;
- allow observation of committed stores;
- expose write events if useful for exact accounting.

Do not add a broad debug bus.

## Required Behavior

### Command acceptance

For both load and store:

- accept only on `vec_cmd_valid && vec_cmd_ready`;
- preserve the complete payload under command backpressure;
- accept exactly one command;
- prevent a second command while busy;
- never issue a killed or wrong-path instruction.

### Scratchpad read

For a valid load:

- use the accepted effective address;
- return the expected 32-bit word;
- write exactly one vector destination;
- leave all other vector registers unchanged;
- produce zero scalar writes;
- retire exactly once.

### Scratchpad write

For a valid store:

- use the accepted effective address;
- capture the source vector value correctly;
- perform exactly one memory write;
- leave all vector registers unchanged;
- produce zero scalar writes;
- retire exactly once.

### Ordering

Because execution is blocking and in order:

- a store followed by a load from the same address must return the stored value;
- a load followed immediately by `VADD8` or `VDOT8` must observe the loaded value;
- younger scalar or vector instructions must not retire before the outstanding memory operation completes;
- a completed operation must allow execution to resume normally.

### Reset cancellation

Verify reset:

- while a load is pending;
- while a store is pending;
- while completion is being backpressured.

Required results:

- no stale completion;
- no retirement;
- no vector write from a cancelled load;
- no scratchpad write from a cancelled store;
- no scalar writeback;
- fresh post-reset operations complete correctly.

### Wrong-path suppression

Include taken redirects around both:

- wrong-path `VLOAD32`;
- wrong-path `VSTORE32`.

Verify zero command, completion, retirement, vector write, and scratchpad write for the killed instructions.

## Focused Development Tests

### Scratchpad unit behavior

Cover:

- deterministic read/write;
- lowest valid address;
- highest valid aligned address;
- independent locations;
- little-endian word organization;
- no unintended neighboring-word changes;
- reset preserving or leaving contents unspecified according to the documented contract.

### Directed load tests

Cover:

- zero offset;
- positive offset;
- negative offset;
- load into `v0`;
- load into `v31`;
- overwrite of an existing vector-register value;
- completion backpressure with destination unchanged before handshake;
- immediate dependent `VADD8`;
- immediate dependent `VDOT8`.

### Directed store tests

Cover:

- zero offset;
- positive offset;
- negative offset;
- store from `v0`;
- store from `v31`;
- exact data value;
- exactly one memory write;
- completion backpressure with memory unchanged before handshake;
- store followed by load from the same address.

### Error tests

Cover:

- misaligned load;
- misaligned store;
- address below valid range through negative offset;
- address at or above the upper bound;
- no destination or memory update;
- correct trap cause and PC;
- exactly one trap;
- zero successful retirement.

### Backpressure

Command backpressure:

- hold command ready low;
- verify address, operation, source/destination index, immediate, PC, and metadata remain stable;
- verify no memory or register event before acceptance.

Completion backpressure:

- hold completion ready low;
- verify completion payload remains stable;
- verify no load destination write or store memory write before handshake;
- commit exactly once after readiness rises.

### Randomized testing

Use deterministic randomized testing with an independent memory/register golden model.

Randomize:

- aligned valid addresses;
- load/store selection;
- vector source/destination indices;
- scratchpad data;
- vector-register data;
- positive and negative offsets where valid;
- occasional boundary addresses.

Use a fixed reported seed and a bounded meaningful case count.

Track final scratchpad and vector-register state against the golden model.

## Event Accounting

Track directly:

- command handshakes;
- completion handshakes;
- successful vector-memory retirements;
- vector-register writes;
- scratchpad writes;
- scalar writebacks;
- traps.

For a successful load:

```text
commands = 1
completions = 1
retirements = 1
vector writes = 1
scratchpad writes = 0
scalar writes = 0
traps = 0
```

For a successful store:

```text
commands = 1
completions = 1
retirements = 1
vector writes = 0
scratchpad writes = 1
scalar writes = 0
traps = 0
```

For failed, reset-cancelled, or wrong-path operations, require zero architectural writes.

## Assertions

Add or preserve meaningful assertions for:

- no second command while busy;
- command payload stability under backpressure;
- completion payload stability under backpressure;
- no completion without an accepted command;
- no load vector write before successful completion handshake;
- no store scratchpad write before successful completion handshake;
- no vector write for stores;
- no scratchpad write for loads;
- no scalar writeback for vector memory operations;
- address and operation metadata stable while pending;
- at most one architectural write per command;
- reset clears pending completion and write state;
- error completion produces no architectural update;
- no duplicate completion or retirement.

## Canonical Targets

Add targets following repository conventions, including equivalents of:

```text
test-vector-scratchpad
test-vector-vmem-directed
test-vector-vmem-backpressure
test-vector-vmem-reset
test-vector-vmem-redirect
test-vector-vmem-errors
test-vector-vmem-random
test-vector-vmem-all
```

Exact names may be adjusted to match existing naming conventions.

Update `test-vector-regression` to include:

- adapter/stub tests;
- VADD8 tests;
- VDOT8 tests;
- vector-memory tests.

Do not duplicate the full scalar regression inside focused vector-memory targets.

## Final Acceptance Regression

During development, run focused vector-memory tests only.

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

1. One shared vector scratchpad exists.
2. The scratchpad is byte addressed and stores 32-bit words.
3. At least 256 bytes are implemented.
4. `VLOAD32` reads a scratchpad word into the shared vector register file.
5. `VSTORE32` writes a shared vector-register value to the scratchpad.
6. Existing VADD8 and VDOT8 reuse the same vector-register array.
7. Effective address uses scalar base plus signed immediate.
8. Only aligned 32-bit accesses succeed.
9. Out-of-range accesses fail precisely.
10. Failed loads do not update vector registers.
11. Failed stores do not update scratchpad memory.
12. Loads commit their vector write only on successful completion handshake.
13. Stores commit their memory write only on successful completion handshake.
14. Command backpressure preserves the complete payload.
15. Completion backpressure causes no early or duplicate architectural update.
16. Successful loads produce exactly one vector write.
17. Successful stores produce exactly one scratchpad write.
18. Vector memory operations produce zero scalar writebacks.
19. `v0` and `v31` work as load/store operands.
20. Positive, negative, and zero offsets work.
21. Lowest and highest valid aligned addresses work.
22. Store-to-load ordering works.
23. A dependent VADD8 observes a loaded value.
24. A dependent VDOT8 observes a loaded value.
25. Reset cancels pending loads and stores without stale effects.
26. Wrong-path loads and stores produce no architectural effects.
27. Deterministic randomized golden-model tests pass.
28. Unsupported encodings remain illegal.
29. Existing adapter, VADD8, VDOT8, and scalar regressions pass.
30. Documentation matches the implementation.
31. No cache, DMA, external bus, unaligned access, gather/scatter, masking, sparsity, or compiler support is added.
32. `rtl/core/rv32_core.sv` remains unchanged.
33. Codex creates no commit or push.
34. `.codex/milestone_result.md` is written in compact format.

## Stop Conditions

Stop for human review only if:

- the current command payload cannot represent base, immediate, and vector register index;
- preserving one vector-register owner requires a major architectural redesign;
- precise load/store commit conflicts with the approved completion protocol;
- no unused experimental instruction encoding remains;
- error handling requires broad scalar trap-path changes;
- scratchpad integration requires modifying the frozen scalar memory interface;
- multiple outstanding operations become necessary;
- a likely pre-existing scalar, adapter, VADD8, or VDOT8 correctness bug is discovered.

Ordinary address-generation bugs, memory-controller bugs, test failures, encoding selection, and documentation work are not stop conditions.

## Required Documentation

Update only materially affected files, normally:

- `docs/architecture/scalar_vector_interface.md`;
- a vector execution or vector-memory architecture document;
- `docs/implementation_status.md`;
- `docs/verification_plan.md`;
- `docs/milestone_history.md`;
- README only if stable user-facing commands change.

Document:

- scratchpad organization and size;
- byte addressing and endianness;
- load/store encodings;
- immediate format;
- alignment and range behavior;
- load and store commit points;
- reset and wrong-path behavior;
- test-only initialization/observation;
- deterministic random seed and case count;
- remaining limitations.

Do not present this as a cache, full memory hierarchy, or complete vector ISA.

## Result File

Write `.codex/milestone_result.md` using the compact repository format.

Include:

- completion status;
- architecture chosen;
- scratchpad configuration;
- load/store encodings;
- address calculation;
- commit semantics;
- error causes;
- focused test commands and results;
- randomized seed and case count;
- exact load/store/write/retirement event counts;
- final regression commands and results;
- bugs fixed;
- changed files;
- remaining limitations;
- confirmation that VADD8 and VDOT8 remain passing;
- confirmation that `rtl/core/rv32_core.sv` is unchanged;
- confirmation that no commit or push occurred.