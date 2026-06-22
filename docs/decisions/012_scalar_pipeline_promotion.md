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

At the time of this decision, `retire_mem_we`, `retire_mem_addr`,
`retire_mem_data`, and `retire_mem_wstrb` were continuously assigned zero.
The subsequent bounded trace-repair milestone implemented response-complete
store retirement and directly compared normalized retirement-store events.
The repair removes this specific blocker but does not itself revise the
decision: broader verification, formal-equivalence, and synthesis/PPA
evidence remain absent.

## Consequences

Tests and documentation retain “production/reference” for `rv32_core` and
“development/experimental” for `rv32_core_pipe`; no rename occurs. The
store-retirement repair evidence may inform a later human promotion review,
but promotion is not automatic. Passing current simulation is not a
throughput, synthesis, area, timing, or formal-equivalence claim.

## Unresolved questions

Whether the pipe can meet the frozen integration contract without broader
restructuring; formal/coverage evidence and synthesis project evidence.
