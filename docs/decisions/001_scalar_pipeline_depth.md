# ADR-001: Scalar Pipeline Depth and Baseline Contract

## Status

Proposed.

## Context

The plan permits either a three-stage or five-stage single-issue in-order RV32I pipeline. Phase 1 requires a frozen supported instruction subset, hazard behavior, trap behavior, reset polarity, and program-image convention.

## Considered options

- Three stages: fetch; decode/execute; memory/writeback.
- Five stages: IF; ID; EX; MEM; WB.

## Decision

Not decided. Select one pipeline and record the exact Phase 1 RV32I subset, aligned-access/trap policy, reset polarity, memory response assumptions, and program-loading format in the accepted record.

## Consequences

The choice changes hazard, forwarding, branch-flush, load-use, verification, and C bring-up complexity. No scalar RTL should establish an implicit contract first.

## Unresolved questions

Which instructions and CSRs are mandatory for the first executable program, and how do illegal or misaligned accesses report failure?
