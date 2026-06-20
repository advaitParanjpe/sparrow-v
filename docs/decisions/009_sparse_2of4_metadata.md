# ADR-009: Sparse 2:4 Metadata Format

## Status

Proposed.

## Context

Each four-weight group stores two values and two distinct positions in 0–3. A simple four-bit pair is suggested, but canonical order, packing across groups, transport through `vspdot`, alignment, and invalid-metadata behavior are undefined.

## Considered options

- Four bits per group: two 2-bit indices in ascending canonical order, supplied from a scalar-addressed metadata stream.
- Four bits per group with metadata packed in a scalar register for a bounded vector/chunk.
- Encoded six-pattern representation using three bits per valid 2-of-4 combination.

## Decision

Not decided. Freeze stored-value order, metadata bit layout, group/chunk scope, transport, alignment, validation, and invalid-data behavior before sparse RTL or exporter implementation.

## Consequences

The choice controls actual data traffic, instruction fields, decoder complexity, memory layout, exporter output, and dense-equivalence tests.

## Unresolved questions

Is `rs_meta` a packed scalar value, an address, or another operand type, and is metadata supplied per architectural vector or per execution chunk?
