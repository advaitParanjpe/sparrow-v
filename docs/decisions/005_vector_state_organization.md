# ADR-005: Vector Length and Register Organization

## Status

Proposed.

## Context

The charter proposes eight 128-bit registers, a mask register, and optional vector length; open questions also list 8 versus 16 registers and 128 versus 64 bits. Vector state is intended to be separate from the scalar register file.

## Considered options

- Eight 128-bit vector registers, one mask register, and an explicit vector-length register.
- Sixteen 128-bit vector registers.
- Eight 64-bit vector registers for a smaller implementation.

## Decision

Not decided. Preserve a dedicated vector register file; freeze count, width, length range, mask state, reset state, and tail/masked-off write policy before dense-vector RTL.

## Consequences

This controls instruction-field allocation, storage cost, lanes per architectural vector, partial-vector semantics, and model/test state.

## Unresolved questions

Are inactive or masked-off destination elements preserved or zeroed, and are vector registers reset architecturally?
