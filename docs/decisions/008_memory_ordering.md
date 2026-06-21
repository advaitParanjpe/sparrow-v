# ADR-008: Memory Consistency and Ordering Assumptions

## Status

Accepted — Phase 1 baseline.

## Context

Scalar and vector paths share scratchpad storage. A blocking interface can make ordering simple, while future decoupling can create visibility and load/store ordering issues.

## Considered options

- Strict program order for all scalar/vector scratchpad operations in the blocking version.
- Defined per-engine ordering with explicit vector fence instructions for cross-engine visibility.
- A more relaxed model only after a formal architectural specification and verification plan exist.

## Decision

Use strict program order for the scalar core. The core allows one instruction and one data request at a time, waits for data completion before retirement, and treats FENCE as a serializing no-op because no other scalar memory operation can be outstanding.

## Consequences

This gates correct scalar/vector arbitration tests and determines whether later decoupled issue changes software-visible behavior.

## Unresolved questions

Deferred to the extension-interface phase.
