# ADR-004: Scalar-to-Vector Extension Protocol

## Status

Proposed.

## Context

The plans permit a blocking first implementation and defer decoupled issue. The boundary has issue/accept and completion/ready concepts but lacks cycle-precise stall, result, exception, and reset rules.

## Considered options

- One-in-flight blocking protocol: scalar issue stalls until vector completion.
- Decoupled tagged protocol with scoreboarding and independent scalar continuation.

## Decision

Not decided. The planned minimum is blocking, subject to an accepted definition of accepted issue, completion, scalar result writeback, backpressure, illegal instruction, and reset-cancellation behavior.

## Consequences

Blocking minimizes Phase 3 state and verification. Decoupling needs tags, destination tracking, fences, and more ordering assertions.

## Unresolved questions

Can vector-only instructions complete without a scalar writeback, and what exact event retires a vector instruction?
