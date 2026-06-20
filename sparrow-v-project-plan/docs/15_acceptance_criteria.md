# Acceptance Criteria

## Repository quality

- One-command checks exist.
- Source, tests, docs, and generated artifacts are separated.
- No unexplained dead code or placeholder claims.
- README accurately reflects current state.

## Scalar core

- All documented RV32I instructions pass directed tests.
- x0 remains zero.
- Branches and hazards behave correctly.
- Loads/stores work under memory stalls.
- A compiled C program runs successfully.

## Vector engine

- Every documented vector opcode has directed tests.
- Randomized vectors match the Python model.
- INT8 and INT16 signed arithmetic are verified.
- Partial lengths and masks are verified.
- Vector writes occur only after accepted instructions.

## Scratchpad

- Scalar and vector accesses remain correct under bank conflicts.
- Backpressure cannot drop requests.
- Arbitration is deterministic or fairly specified.
- Conflict counters match observed behavior.

## Sparse execution

- Every valid metadata pattern is covered.
- Invalid metadata behavior is defined.
- Sparse results equal dense reconstructed results.
- Actual multiply count is lower than dense-equivalent count for sparse workloads.
- Exported software format matches RTL decode.

## End-to-end workload

- Scalar output matches host reference.
- Dense-vector output matches scalar/reference output within exact integer semantics.
- Sparse-vector output matches the pruned-model reference.
- Performance metrics are collected automatically.

## Hardware implementation

- Synthesis completes without unintended latches or black boxes.
- Timing reports are preserved.
- Area/resource reports are preserved.
- Physical-flow limitations are documented honestly.

## Documentation

- Architecture diagram matches RTL hierarchy.
- ISA table matches implemented decode.
- Benchmark configuration is reproducible.
- Known limitations and future work are explicit.

