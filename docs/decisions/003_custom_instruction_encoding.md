# ADR-003: Custom Instruction Encoding Space

## Status

Accepted — reservation only, Phase 1.

## Context

Sparrow-V requires custom vector instructions but does not define exact opcode, funct, register-field, immediate, or illegal-encoding behavior. The plans direct use of a RISC-V custom opcode space.

## Considered options

- Allocate one RISC-V custom major opcode with funct fields for all Sparrow-V operations.
- Allocate multiple RISC-V custom major opcodes by instruction class.
- Use another nonstandard encoding scheme only with a documented interoperability rationale.

## Decision

Reserve standard RISC-V custom-0 major opcode `0001011` for future Sparrow-V vector instructions. Phase 1 decodes no custom instruction and traps this opcode as illegal.

## Consequences

The selected table must be the single source mirrored by decoder, software helpers, Python model, and tests. It gates Phase 3.

## Unresolved questions

All vector instruction fields remain unresolved until Phase 3.
