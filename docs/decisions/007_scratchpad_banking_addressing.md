# ADR-007: Scratchpad Banking and Addressing

## Status

Proposed.

## Context

The proposed scratchpad has four 32-bit word-interleaved banks with one request per bank per cycle. Capacity, address unit, byte enables, latency, vector element transaction formation, and arbitration policy are open.

## Considered options

- Four 32-bit word-interleaved banks with scalar priority.
- Four 32-bit word-interleaved banks with round-robin arbitration.
- Another bank count/width/depth configuration justified by target constraints.

## Decision

Not decided. Freeze capacity, address map, access latency, byte/halfword behavior, scalar/vector arbitration, conflict/replay ordering, and counter definitions before Phase 5.

## Consequences

The decision defines the vector LSU, software data layout, deterministic bank-conflict behavior, and required assertions.

## Unresolved questions

What is the maximum vector memory work in flight, and how are misaligned vector accesses reported?
