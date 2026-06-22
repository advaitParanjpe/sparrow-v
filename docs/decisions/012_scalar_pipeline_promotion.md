# ADR-012: Scalar Pipeline Promotion Decision

## Status

Accepted — production-readiness assessment milestone.

## Context

`rv32_core_pipe` has deterministic differential evidence over the shared
subset but must be assessed separately for correctness, interface stability,
verification maturity, performance readiness, and production integration.

## Options considered

- Promote the development pipeline now.
- Conditionally promote it as the primary development core.
- Keep it experimental pending a bounded interface/verification repair.

## Decision

Choose **C. Do not promote**.  `rv32_core.sv` remains the protected
production/reference core.  `rv32_core_pipe.sv` remains experimental.

The concrete blocker is visible in `rv32_core_pipe.sv`: `retire_mem_we`,
`retire_mem_addr`, `retire_mem_data`, and `retire_mem_wstrb` are continuously
assigned zero, while `rv32_core.sv` reports accepted store retirement data.
Same-named ports therefore do not have equivalent semantics.  The current
differential harness compares accepted store requests, not pipe
`retire_mem_*`, so the campaign cannot establish the frozen trace contract.

## Consequences

Tests and documentation retain “production/reference” for `rv32_core` and
“development/experimental” for `rv32_core_pipe`; no rename occurs.  A bounded
follow-up milestone must define, implement, and test pipe store-retirement
semantics against the v1 freeze, then repeat differential evidence including
that bundle before reconsidering B or A.  Passing current simulation is not a
throughput, synthesis, area, timing, or formal-equivalence claim.

## Unresolved questions

Whether the pipe can meet the frozen integration contract without broader
restructuring; formal/coverage evidence and synthesis project evidence.
