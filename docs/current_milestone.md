# Differentially verify the pipelined scalar core against the reference core

## Status

Approved verification-infrastructure milestone. `rtl/core/rv32_core.sv` remains the production/reference implementation; `rtl/core/rv32_core_pipe.sv` remains isolated and experimental.

## Objective and motivation

Create a deterministic differential-verification flow that runs equivalent supported RV32I programs on both scalar cores and detects architectural divergence while ignoring expected cycle, request-timing, and pipeline-state differences. Directed tests cover known scenarios but do not establish broad behavioral equivalence. This work improves confidence before any human decision on production integration or vector-extension attachment. It is not formal equivalence and passing it does not promote the pipeline to production.

## Current baseline

The checkpoint is `ce7b3e3`. The production core has a self-checking directed regression (`make test-scalar-directed`). The development core has focused ALU, forwarding, control-flow, redirect, and memory targets. Both use the shared decoder, ALU, immediate generator, register file, and external valid/ready memory protocol. The Python `RV32IReference` is a limited helper, not a full differential framework.

The production retirement interface reports register writes, memory writes, and terminal events. The development core reports PC/instruction/register/terminal retirement fields, but currently ties its `retire_mem_*` outputs low. The differential harness must therefore observe accepted data-memory writes and final memory images independently of development retirement memory fields. Final register state may use bounded verification-only hierarchical observation; no production external interface redesign is authorized.

## In scope

- Shared directed/generated program representation and deterministic recorded seeds.
- Derivation and documentation of the exact common legal subset from RTL, rather than assumption.
- Equivalent register/data-memory initialization and deterministic termination.
- Separate runs of the two cores using the same program, initial memory, and reproducible memory-stall schedule.
- Normalized architectural traces: retired PC/instruction, register write, accepted memory write, terminal event, final registers, final memory, trap PC/cause, and semantically comparable retirement count.
- Directed differential smoke cases, bounded randomized differential regression, deterministic request backpressure, delayed load responses, bounded timeouts/deadlock diagnosis, actionable mismatch reports, and preserved confirmed failing seeds.
- A controlled negative checker test proving mismatch detection.
- Focused test-only trace/observation infrastructure if necessary; canonical fast smoke, bounded campaign, and single-seed reproduce commands/targets are to be added using existing Makefile conventions.
- Factual updates to implementation/verification documentation and milestone history.

## Out of scope

- Production integration, replacement, or deletion of `rv32_core.sv`.
- Broad RTL redesign, new ISA behavior, vector/sparse/scratchpad/cache work, branch prediction, multiple outstanding memory operations, compiler/runtime work, FPGA/ASIC work, or performance benchmarking.
- Cycle-by-cycle equivalence, matching raw stalls/counters/request timing, formal-equivalence claims, or changing architectural behavior merely to make the cores agree.

## Architectural constraints and protected files

Treat both core RTL files as protected while building verification infrastructure. A core change is permitted only after a reproducible divergence, documentation identifies which behavior is wrong, a focused regression is added, and the correction is small and architecture-consistent. All existing checks must then pass.

Stop for human review before external-interface changes, ambiguous architecture, changing both cores for one mismatch, pipeline-control redesign, trap-policy/memory-semantics changes, or any destructive rewrite.

## Common instruction subset

The implementation must derive the final subset from the decoder/core behavior. The initial normal-program candidate is: LUI, AUIPC; legal OP-IMM and OP ALU/comparison/shift encodings; BEQ/BNE/BLT/BGE/BLTU/BGEU; JAL/JALR; LB/LH/LW/LBU/LHU; SB/SH/SW; and ECALL termination, subject to direct validation in both cores.

Exclude FENCE from normal generation until development behavior is confirmed common. Exclude EBREAK, custom opcodes, illegal encodings, and misaligned accesses from normal random programs. Cover illegal and instruction-misalignment behavior as separate directed categories. Cover load/store misalignment only after the harness establishes matching documented causes; production documentation specifies causes 4/6, while the development implementation requires direct confirmation. Exclude compressed, CSR/privileged, floating-point, atomics, vector, and undefined project behavior.

## Program generation

Programs must be deterministic from a reported seed, bounded in length, constrained to the test-memory map, and terminate through a controlled ECALL or bounded control-flow structure. They must not self-modify, access unavailable memory, or branch outside generated code. Control flow must be constrained to remain in-program. Campaign size must be chosen from measured local runtime and reported exactly; begin with a modest tens-to-hundreds seed campaign, not an arbitrary large count.

## Comparison and memory strategy

Compare normalized architectural effects, not cycles: ordered retirement/terminal sequence where reliable, register writes, accepted store side effects, final x1–x31 plus x0, final data-memory image, trap occurrence/cause/PC, and termination. Treat differing cycle counts, requests, stalls, fetch generations, and debug counters as expected microarchitectural differences.

Use a common deterministic memory model and schedule modes: immediate acceptance/response, request backpressure, delayed load response, and mixed fixed stall patterns. If cores run separately, derive each schedule solely from seed/program-defined state so it reproduces identically. Mismatch output must include seed, saved program, schedule, category, first divergent event, recent normalized context for both runs, expected/observed values, relevant final state, and exact rerun command.

## Required verification

The implementation milestone must add and document real canonical commands for a fast differential smoke, a bounded randomized campaign, and a single-seed rerun. It must run:

1. `make test-scalar-directed`.
2. `make test-scalar-pipe-dev`, `make test-scalar-pipe-alu`, `make test-scalar-pipe-forward`, `make test-scalar-pipe-control`, `make test-scalar-pipe-redirect`, and `make test-scalar-pipe-memory`.
3. `make lint`, `make check`, and `git diff --check`.
4. New directed differential smoke tests, bounded random campaign, memory-stall/delayed-response campaign, and one exact seed rerun.
5. A controlled negative checker perturbation demonstrating detection.

## Measurable acceptance criteria

Completion requires a documented flow that runs equivalent programs on both cores, normalized architecture-level comparison, deterministic seed rerun, directed smoke pass, bounded reported random seed count pass, memory schedule variation, actionable diagnostics, and a passing controlled negative test. All existing regressions, lint, and repository checks must pass. Confirmed RTL bugs require a focused regression, grounded root cause, minimal fix, and full evidence. Update `docs/implementation_status.md`, `docs/verification_plan.md`, relevant verification documents, and append a factual milestone-history entry. Do not commit or push.

## Stop conditions

Stop for human review if the common subset cannot be determined, semantics/traps/memory behavior materially differ, reliable state needs invasive interface changes, a mismatch may be in the reference core, both cores need architectural changes, a broad redesign is required, tests/docs disagree, a harness flaw prevents trustworthy comparison, the tree is not attributable, or required tools cannot run.

## Required final report

Report the differential architecture, actual common subset, generation/normalization/memory strategy, commands/results, seeds/campaign size/runtime, negative-test result, mismatches and confirmed fixes, changed files, final diff review, blind spots, reasons the pipeline remains experimental, human-review items, and confirmation of no commit/push.
