# ADR-008: Memory Consistency and Ordering Assumptions

## Status

Accepted — Phase 1 baseline and v1 vector-boundary ordering.

## Context

Scalar and vector paths share scratchpad storage. A blocking interface can make ordering simple, while future decoupling can create visibility and load/store ordering issues.

## Considered options

- Strict program order for all scalar/vector scratchpad operations in the blocking version.
- Defined per-engine ordering with explicit vector fence instructions for cross-engine visibility.
- A more relaxed model only after a formal architectural specification and verification plan exist.

## Decision

Use strict program order for the scalar core. The core allows one instruction and one data request at a time, waits for data completion before retirement, and treats FENCE as a serializing no-op because no other scalar memory operation can be outstanding.

For the v1 blocking vector boundary, scalar work older than a vector command completes before command acceptance and scalar issue remains stalled through accepted completion. Scalar and vector memory therefore cannot overlap architecturally. A later nonblocking or shared-scratchpad implementation must define arbitration and ordering in a new ADR.

## Consequences

This gates correct scalar/vector arbitration tests and determines whether later decoupled issue changes software-visible behavior.

## Unresolved questions

Deferred to the extension-interface phase.
