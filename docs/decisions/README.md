# Architecture Decision Records

Each record uses the same fields: status, context, considered options, decision, consequences, and unresolved questions. A **Proposed** record is not permission to implement its options. Acceptance requires explicit project review and any affected planning documents must then be updated.

Create an ADR before changing pipeline stages, ISA encodings, the CPU/vector boundary, a memory interface, scratchpad organization, sparsity metadata format, or an externally visible software ABI. Small local fixes inside an accepted design normally do not need one.

## ADR template

```md
# ADR NNN: Short decision title

## Status
Proposed | Accepted | Superseded

## Context
What decision is needed and what constraints apply?

## Options considered
- Option A:
- Option B:

## Decision
Human-approved choice and rationale.

## Consequences
Interfaces, verification, software, migration, and risks.

## Unresolved questions
Items intentionally deferred.
```

| ADR | Topic | Status |
| --- | --- | --- |
| [001](001_scalar_pipeline_depth.md) | Scalar Pipeline Depth and Baseline Contract | Accepted — Phase 1. |
| [002](002_scalar_core_provenance.md) | Scalar Core Provenance | Accepted — Phase 1. |
| [003](003_custom_instruction_encoding.md) | Custom Instruction Encoding Space | Accepted — reservation only, Phase 1. |
| [004](004_scalar_vector_protocol.md) | Scalar-to-Vector Extension Protocol | Accepted — v1 boundary, no RTL. |
| [005](005_vector_state_organization.md) | Vector Length and Register Organization | Accepted — ownership boundary only. |
| [006](006_integer_lane_semantics.md) | INT8/INT16 Lane Behavior | Proposed. |
| [007](007_scratchpad_banking_addressing.md) | Scratchpad Banking and Addressing | Accepted — boundary selection only; scratchpad details proposed. |
| [008](008_memory_ordering.md) | Memory Consistency and Ordering Assumptions | Accepted — Phase 1 baseline and v1 vector-boundary ordering. |
| [009](009_sparse_2of4_metadata.md) | Sparse 2:4 Metadata Format | Proposed. |
| [010](010_benchmark_application.md) | Benchmark Application Selection | Proposed. |
| [011](011_fpga_asic_targets.md) | FPGA and ASIC Target Strategy | Proposed. |
| [012](012_scalar_pipeline_promotion.md) | Scalar Pipeline Promotion Decision | Accepted — production-readiness assessment milestone. |
| [013](013_scalar_interface_freeze.md) | Scalar Interface Freeze and Observability Classification | Accepted — v1 reference-core contract. |
