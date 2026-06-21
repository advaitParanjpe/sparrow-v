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
| [001](001_scalar_pipeline_depth.md) | Scalar pipeline depth and baseline contract | Accepted — Phase 1 |
| [002](002_scalar_core_provenance.md) | New scalar core or adapted permissive core | Accepted — Phase 1 |
| [003](003_custom_instruction_encoding.md) | Custom instruction encoding space | Accepted — reservation only |
| [004](004_scalar_vector_protocol.md) | Scalar-to-vector extension protocol | Proposed |
| [005](005_vector_state_organization.md) | Vector length and register organization | Proposed |
| [006](006_integer_lane_semantics.md) | INT8/INT16 lane behavior | Proposed |
| [007](007_scratchpad_banking_addressing.md) | Scratchpad banking and addressing | Proposed |
| [008](008_memory_ordering.md) | Memory consistency and ordering | Accepted — Phase 1 |
| [009](009_sparse_2of4_metadata.md) | Sparse 2:4 metadata format | Proposed |
| [010](010_benchmark_application.md) | End-to-end benchmark application | Proposed |
| [011](011_fpga_asic_targets.md) | FPGA and ASIC target strategy | Proposed |
