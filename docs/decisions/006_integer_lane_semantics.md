# ADR-006: INT8/INT16 Lane Behavior

## Status

Proposed.

## Context

Four physical lanes execute architectural vectors in chunks. The plans recommend signed INT8/INT16 operands, widening multiply, 32-bit dot accumulation, and wrapping add/subtract, but do not freeze all semantics.

## Considered options

- Signed arithmetic with wrapping add/subtract, widening multiply, and 32-bit dot/reduction accumulation.
- Signed arithmetic with saturating vector arithmetic.
- A reduced INT8-only first vector milestone, adding INT16 later.

## Decision

Not decided. Freeze signedness, widening/truncation points, accumulation width/overflow, min/max comparison, lane chunk ordering, tail behavior, mask behavior, and invalid-mode behavior.

## Consequences

The exact behavior determines bit-exact Python-model, RTL, and software expectations and cannot be inferred from lane count alone.

## Unresolved questions

Does `vdot` always write scalar state, and what overflow behavior applies to reductions?
