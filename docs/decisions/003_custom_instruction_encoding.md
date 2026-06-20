# ADR-003: Custom Instruction Encoding Space

## Status

Proposed.

## Context

Sparrow-V requires custom vector instructions but does not define exact opcode, funct, register-field, immediate, or illegal-encoding behavior. The plans direct use of a RISC-V custom opcode space.

## Considered options

- Allocate one RISC-V custom major opcode with funct fields for all Sparrow-V operations.
- Allocate multiple RISC-V custom major opcodes by instruction class.
- Use another nonstandard encoding scheme only with a documented interoperability rationale.

## Decision

Not decided. The expected default is a documented RISC-V custom opcode allocation, but no final bits are assigned in Phase 0.

## Consequences

The selected table must be the single source mirrored by decoder, software helpers, Python model, and tests. It gates Phase 3.

## Unresolved questions

How are vector register indices, scalar destinations, metadata operands, configuration operations, and reserved/illegal encodings represented?
