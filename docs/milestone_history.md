# Milestone history

Append completed, human-reviewed milestones below. Do not reconstruct or invent prior entries.

### Differentially verify the pipelined scalar core against the reference core — 2026-06-21

- Reference: uncommitted working-tree milestone evidence.
- Summary: deterministic normalized differential harness added for the shared scalar subset; fixed pipeline stale-response redirect bookkeeping under request backpressure.
- Key files: `tb/integration/tb_scalar_differential.sv`, `rtl/core/rv32_core_pipe.sv`, `Makefile`.
- Tests run and measured results: smoke; 32 immediate-memory seeds; seed 17 modes 1/2/3; controlled negative test; existing scalar regressions, lint, and repository checks.
- Known limitations: not formal equivalence; byte/halfword memory, FENCE, EBREAK, illegal, and misalignment are not randomized; pipeline remains experimental.
- Follow-up work: human review before production integration.

## Entry template

### Milestone name — YYYY-MM-DD

- Reference: user-added commit hash or working-tree reference.
- Summary:
- Key files:
- Tests run and measured results:
- Known limitations:
- Follow-up work:
