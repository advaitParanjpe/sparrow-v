# ADR-002: Scalar Core Provenance

## Status

Accepted — Phase 1.

## Context

The project prioritizes an understandable core but recognizes schedule risk in building one from scratch. It allows adaptation of a small permissively licensed educational RV32I core with documented provenance.

## Considered options

- Implement a minimal RV32I core from scratch in this repository.
- Adapt a clearly permissively licensed, small educational RV32I core and document all changes.

## Decision

Implement the scalar CPU from scratch in this repository. No external functional CPU RTL is imported or copied.

## Consequences

New RTL maximizes architectural ownership but costs bring-up time. Adaptation may reduce risk but adds provenance, integration, and verification obligations.

## Unresolved questions

None for Phase 1.
