# Project Status

## Current phase

**Phase 0 — Repository and specification freeze: in progress.**

## Completed work

- Original planning documents have been preserved as the project specification.
- Repository layout, decision-record templates, documentation maps, and repository checks have been added.
- No implementation-phase claims are made.

## Active blockers

- The Phase 0 roadmap calls for a frozen scalar instruction subset and custom opcode allocation, while the planning documents deliberately leave both unresolved.
- Pipeline depth, scalar-core provenance, reset polarity, vector semantics, sparse packing, memory arbitration, end-to-end workload, and implementation targets require recorded approval before dependent RTL phases.

## Next approved task

Review and resolve the Proposed ADRs needed to freeze the Phase 1 scalar-core contract. Do not start Phase 1 RTL until that review is complete.

## Tests currently available

- Repository structure, required-document, placeholder-marker, generated-output, and source-manifest checks.
- Python unit tests for repository-check validation behavior.

No RTL simulation, synthesis, timing, FPGA, ASIC, benchmark, or application tests exist yet.

## Known limitations

- No functional RTL, ISA encoding table, software runtime, or reference model has been implemented.
- `make check` validates repository/documentation hygiene only; it is not a simulation or correctness result.
- The worktree may be nested below an unrelated Git worktree; repository checks intentionally do not interpret that parent worktree's status as Sparrow-V status.
