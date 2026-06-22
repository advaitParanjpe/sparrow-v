# ADR-013: Scalar Interface Freeze and Observability Classification

## Status

Accepted — v1 reference-core contract.

## Context

Vector integration needs a stable scalar boundary without turning test hooks
or pipeline internals into an ABI.

## Options considered

- Freeze the reference-core external interface and classify observability.
- Freeze both scalar implementations based on matching port names.
- Defer all freezing until vector RTL begins.

## Decision

Freeze the `rv32_core` v1 interface described in
`architecture/scalar_interface_freeze.md`.  Counters and retirement are
debug/integration observability with explicit semantics; test hooks and
microarchitectural counters are not stable interfaces.  Do not freeze the
pipeline implementation until its store-retirement discrepancy is repaired.

## Consequences

Future vector work consumes only the approved extension/memory boundaries.
It cannot depend on scalar register-file hierarchy, fetch epochs, valid bits,
hazard state, or raw memory timing.

## Unresolved questions

Whether to retain every diagnostic counter in a future synthesized top level.
