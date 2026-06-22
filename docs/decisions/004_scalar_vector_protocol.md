# ADR-004: Scalar-to-Vector Extension Protocol

## Status

Accepted — v1 boundary, no RTL.

## Context

The plans permit a blocking first implementation and defer decoupled issue. The boundary has issue/accept and completion/ready concepts but lacks cycle-precise stall, result, exception, and reset rules.

## Considered options

- One-in-flight blocking protocol: scalar issue stalls until vector completion.
- Decoupled tagged protocol with scoreboarding and independent scalar continuation.

## Decision

Adopt the one-outstanding blocking valid/ready command and completion protocol in `docs/architecture/scalar_vector_interface.md`. Acceptance, completion, writeback, precise exceptions, backpressure, and reset cancellation are defined there. It is an RTL-independent boundary, not a vector ISA.

## Consequences

Blocking minimizes Phase 3 state and verification. Decoupling needs tags, destination tracking, fences, and more ordering assertions. The v1 fixed-zero identity field reserves a later tagged extension without adding unneeded machinery.

## Unresolved questions

Detailed operation encodings, cause allocation, and any nonblocking revision.
