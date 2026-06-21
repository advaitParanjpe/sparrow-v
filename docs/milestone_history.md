# Milestone history

Append completed, human-reviewed milestones below. Pending-review implementation evidence must be explicitly marked and must not imply a commit. Do not reconstruct or invent prior entries.

### Add full subword load/store differential coverage for the scalar pipeline — implementation complete, pending human review — 2026-06-21

- Reference: uncommitted working-tree implementation evidence; no commit or human acceptance yet.
- Summary: added directed and deterministic differential coverage for every supported scalar load/store width; corrected the experimental pipeline's data-port address to remain word-aligned for subword accesses.
- Key files: `tb/integration/tb_scalar_differential.sv`, `rtl/core/rv32_core_pipe.sv`, `Makefile`.
- Tests run and measured results: final directed test passes with LHU+ADDI=`0x00008080`; 128 immediate-mode seeds pass in 7.08 seconds wall time; seed 17 passes modes 1/2/3; register- and memory-focused controlled-negative tests detect their injected mismatches.
- Known limitations: not formal equivalence; FENCE, EBREAK, illegal encodings, and misalignment are not randomized; pipeline remains experimental.
- Follow-up work: final human review and commit decision; no production integration is implied.

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
