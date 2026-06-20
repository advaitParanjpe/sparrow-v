# ADR-002: Scalar Core Provenance

## Status

Proposed.

## Context

The project prioritizes an understandable core but recognizes schedule risk in building one from scratch. It allows adaptation of a small permissively licensed educational RV32I core with documented provenance.

## Considered options

- Implement a minimal RV32I core from scratch in this repository.
- Adapt a clearly permissively licensed, small educational RV32I core and document all changes.

## Decision

Not decided. Do not import third-party CPU RTL until this record is accepted and the exact upstream license, revision, attribution, and modification boundary are approved.

## Consequences

New RTL maximizes architectural ownership but costs bring-up time. Adaptation may reduce risk but adds provenance, integration, and verification obligations.

## Unresolved questions

Does the project schedule justify a from-scratch implementation after the Phase 1 instruction subset is frozen?
