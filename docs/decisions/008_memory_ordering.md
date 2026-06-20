# ADR-008: Memory Consistency and Ordering Assumptions

## Status

Proposed.

## Context

Scalar and vector paths share scratchpad storage. A blocking interface can make ordering simple, while future decoupling can create visibility and load/store ordering issues.

## Considered options

- Strict program order for all scalar/vector scratchpad operations in the blocking version.
- Defined per-engine ordering with explicit vector fence instructions for cross-engine visibility.
- A more relaxed model only after a formal architectural specification and verification plan exist.

## Decision

Not decided. The first memory contract must define read-after-write visibility, load/store ordering, completion ordering, reset behavior, and whether fence instructions are needed.

## Consequences

This gates correct scalar/vector arbitration tests and determines whether later decoupled issue changes software-visible behavior.

## Unresolved questions

Can a scalar load observe a vector store before vector completion in any approved execution model?
