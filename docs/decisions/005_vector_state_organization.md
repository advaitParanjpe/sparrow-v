# ADR-005: Vector Length and Register Organization

## Status

Accepted — ownership boundary only.

## Context

The charter proposes eight 128-bit registers, a mask register, and optional vector length; open questions also list 8 versus 16 registers and 128 versus 64 bits. Vector state is intended to be separate from the scalar register file.

## Considered options

- Eight 128-bit vector registers, one mask register, and an explicit vector-length register.
- Sixteen 128-bit vector registers.
- Eight 64-bit vector registers for a smaller implementation.

## Decision

Vector state is owned exclusively by the vector engine and is independent of the scalar register file. Command fields carry opaque vector-register indices only. Count, width, length range, mask state, architectural reset value, and tail/masked-off policy remain deferred before dense-vector RTL.

## Consequences

This controls instruction-field allocation, storage cost, lanes per architectural vector, partial-vector semantics, and model/test state.

## Unresolved questions

Are inactive or masked-off destination elements preserved or zeroed, and are vector registers reset architecturally?
