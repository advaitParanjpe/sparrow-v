# ADR-001: Scalar Pipeline Depth and Baseline Contract

## Status

Accepted — Phase 1.

## Context

The plan permits either a three-stage or five-stage single-issue in-order RV32I pipeline. Phase 1 requires a frozen supported instruction subset, hazard behavior, trap behavior, reset polarity, and program-image convention.

## Considered options

- Three stages: fetch; decode/execute; memory/writeback.
- Five stages: IF; ID; EX; MEM; WB.

## Decision

Use a from-scratch, three-stage IF/DX/MW single-issue in-order core. `rst_n` is synchronous active-low. The accepted ISA, traps, counters, and memory contract are in `docs/architecture/scalar_core.md`.

## Consequences

The choice changes hazard, forwarding, branch-flush, load-use, verification, and C bring-up complexity. No scalar RTL should establish an implicit contract first.

## Unresolved questions

None for Phase 1; CSR instruction access and a full privileged architecture are deliberately deferred.
