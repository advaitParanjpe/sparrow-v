# Milestone history

Append completed, human-reviewed milestones below. Pending-review implementation evidence must be explicitly marked and must not imply a commit. Do not reconstruct or invent prior entries.

### Lean Codex milestone workflow — implementation complete, pending human review — 2026-06-22

- Reference: uncommitted workflow-infrastructure change; no commit or human acceptance yet.
- Summary: permanent Codex rules now live in `AGENTS.md` and a concise context
  map; the active milestone is a lean template; one launcher session writes an
  ignored compact result file; scalar/vector/full regression aggregates provide
  one final-acceptance path.
- Key files: `AGENTS.md`, `docs/codex_context.md`, `docs/current_milestone.md`,
  `scripts/run_milestone.sh`, `Makefile`, and workflow documentation.
- Tests run: shell syntax, Make help and full-regression dry run, repository
  checks, documentation checks, and `git diff --check` passed.
- Follow-up work: human review, then manually commit the workflow change before
  defining the next milestone.

### Implement and verify the minimal scalar-to-vector command/completion adapter with a stub vector engine — implementation complete, pending human review — 2026-06-22

- Reference: uncommitted working-tree implementation evidence; no commit or human acceptance yet.
- Summary: direct experimental integration adds the approved blocking, in-order, one-command command/completion boundary to `rv32_core_pipe` and a standalone latency-3 deterministic stub. Custom-0 `funct3=000` returns `rs1 + rs2` to scalar `rd`; `001` completes and retires without scalar writeback; `010` completes exceptionally with precise PC and cause 2. These are test encodings, not the vector ISA.
- Key files: `rtl/core/rv32_core_pipe.sv`, `rtl/vector/rv32_vec_stub_engine.sv`, `tb/integration/tb_scalar_pipe_vec_stub.sv`, shared pipe idle-port include, `Makefile`, and scalar/vector architecture and verification documentation.
- Tests run and measured results: aggregate vector-stub regression passed all seven modes. Success, command-backpressure, completion-backpressure, and wrong-path target modes each reported 1 command, 1 completion, 1 vector retirement, 1 scalar writeback, and 0 vector traps. Vector-only reported 1 command, 1 completion, 1 retirement, 0 scalar writes, and 0 traps. Exception reported 1 command, 1 completion, PC `0x00000008`, cause 2, 0 successful retirements, and no scalar writeback. Reset cancellation reported only the fresh post-reset command: 1 command, 1 completion, and 1 retirement; the cancelled command produced no visible completion, retirement, writeback, or trap.
- Known limitations: no real vector datapath/register file/vector memory/sparse logic, no full vector ISA, no formal equivalence, coverage closure, synthesis/PPA evidence, or broad randomized exceptional-case campaign. `rv32_core_pipe` remains experimental and is not promoted.
- Follow-up work: human review and commit decision, then separately approved real vector-state, operation, and memory milestones.

### Repair and verify `rv32_core_pipe` store-retirement trace outputs — implementation complete, pending human review — 2026-06-22

- Reference: uncommitted working-tree implementation evidence; no commit or human acceptance yet.
- Summary: pipeline stores now wait for the sole data-response handshake before retiring and report effective byte address, unshifted scalar data, and little-endian lane strobe. The focused regression proves both a killed wrong-path store has no request, retirement, or memory side effect and a valid taken-branch target store retires and writes memory exactly once. The differential harness separately compares normalized retirement-store events rather than treating accepted store requests as a substitute.
- Key files: `rtl/core/rv32_core_pipe.sv`, `tb/integration/tb_scalar_pipe_store_retire.sv`, `tb/integration/tb_scalar_differential.sv`, `Makefile`, scalar status/verification documentation.
- Tests run and measured results: all milestone commands passed in the current tree. Focused regression reports 8 requests, 8 responses, and 8 retirements, one target-path memory write, and zero killed-store retirements. Differential seed 17 passed modes 0–3; mode 3 reports 25 stores and 25 store retirements in 451 cycles for both cores. The controlled-negative target detected its injected pipeline retirement-address corruption.
- Known limitations: no formal equivalence, coverage closure, synthesis/PPA evidence, or broad randomized trap/illegal campaign. The pipeline remains experimental and is not promoted.
- Follow-up work: human review of the trace-repair evidence before any separate promotion reassessment.

### Pipeline production-readiness review and scalar-to-vector interface definition — complete, human-reviewed and approved, uncommitted — 2026-06-22

- Reference: clean entry and evidence commit `5850b69813207055f1f1c7c1eebcb5dd63bda14b`; human review approved the recorded architecture decisions. No commit was created by this milestone, and its documentation changes remain uncommitted.
- Summary: assessed both scalar implementations, selected C (do not promote) because development-pipeline `retire_mem_*` outputs are constant zero, froze the reference-core v1 interface, and defined an RTL-independent blocking scalar/vector command-completion and separate vector-memory boundary.
- Key files: `docs/architecture/scalar_interface_freeze.md`, `docs/architecture/scalar_vector_interface.md`, ADRs 004/005/007/008/012/013, architecture/status/verification documentation.
- Tests run and measured results: all required Phase-1 targets passed; immediate differential seeds 1–500 passed in 18.4 seconds; seeds 1–16 passed in modes 1/2/3; seed 17 passed modes 0/1/2/3. Throughput experiment failed as expected (exit 2; 52 cycles, 16 retired, maximum consecutive retirements 1, 16 gaps).
- Known limitations: no formal equivalence, randomized illegal/misaligned coverage, synthesis/PPA evidence, vector RTL, or scratchpad RTL. The pipe trace-store interface needs repair and direct verification before reconsidering promotion.
- Follow-up work: bounded pipe retirement-interface repair/verification milestone, then a separate approved scalar/vector adapter implementation milestone.

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
