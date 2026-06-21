# Expand scalar differential verification to full supported load/store and trap coverage

## Status

Approved bounded verification milestone. `rtl/core/rv32_core.sv` remains the production/reference core and `rtl/core/rv32_core_pipe.sv` remains experimental. The executor must begin from a clean, attributable tree; otherwise stop for human review.

## Objective and motivation

Extend deterministic differential verification so both scalar cores are compared across all currently supported load/store widths and supported terminal behavior. The current campaign covers LW/SW, scalar ALU/control flow, ECALL, and deterministic memory timing modes, but not the full subword-memory or trap surface. This strengthens the scalar foundation before any production-pipeline promotion or vector-interface work. It is not formal equivalence and does not make the pipeline production-ready.

## Current baseline

Existing differential commands are `test-scalar-diff-smoke`, `test-scalar-diff-random` (32 immediate-mode seeds), `test-scalar-diff-stall` (seed 17 modes 1–3), `test-scalar-diff-seed`, `test-scalar-diff-negative`, and `test-scalar-diff-redirect-backpressure`. The active campaign covers LUI/AUIPC, listed scalar ALU operations, all branches, JAL/JALR, LW/SW, and ECALL. It compares normalized retirement/register/store/final-memory/terminal effects, not cycles. The redirect/backpressure phantom-outstanding-fetch bug is covered by the focused seed-17 target.

## In scope

- Differential coverage for LB, LBU, LH, LHU, LW, SB, SH, and SW.
- Little-endian byte lanes, byte enables, sign/zero extension, partial-store preservation, loads to x0, and store-without-register-write checks.
- Load-use ALU, branch/address, mixed-width, store-to-load, backpressured, delayed-response, and mixed-mode cases.
- Directed aligned/misaligned halfword and word access, illegal instruction, ECALL, and EBREAK categories where behavior is common and directly validated.
- Trap occurrence, cause, PC, and no-side-effect comparison.
- Deterministic subword random generation, saved/reproducible seeds, improved mismatch diagnostics, an extended bounded campaign justified by measured runtime, and memory-focused controlled negative detection if practical.
- Documentation, verification-plan, and milestone-history updates.

## Out of scope

- Production integration/replacement; vector, sparse, scratchpad, cache, DMA, branch prediction, multiple outstanding memory operations, compiler/runtime, FPGA/ASIC, performance benchmarking, formal-equivalence claims, broad pipeline redesign, or unrelated new ISA behavior.

## Actual supported behavior to validate

The shared decoder supports LB/LH/LW/LBU/LHU and SB/SH/SW. Byte accesses are unaligned-permitted; halfwords require address bit 0 clear; words require bits [1:0] clear. Data is little-endian and stores use lane strobes. Signed loads sign-extend; unsigned loads zero-extend. x0 writes are discarded. The production trap contract specifies causes: instruction misalignment 0, illegal 2, EBREAK 3, load misalignment 4, store misalignment 6, ECALL 11. The executor must directly establish matching pipeline behavior before treating any trap category as common.

## Architectural constraints

External memory interfaces remain unchanged. Partial stores preserve untouched bytes; faulting or illegal operations must not create register/memory side effects. Cycle timing/counters need not match. Do not weaken tests to force agreement. The reference core must not change unless a reproducible reference-core bug is found and human review approves action.

## Generation and directed coverage

Normal random programs must be seed-reproducible, aligned, bounded, terminating, inside valid test memory, non-self-modifying, and contain patterns for byte lanes and sign bits. Keep illegal/misaligned/ECALL/EBREAK as separate directed categories. Add directed cases for every load/store width, all byte offsets, both valid halfword offsets, neighbouring-byte/halfword preservation, x0 load destination, dependent ALU and branch/address consumers, consecutive mixed-width memory work, store-followed-by-load, all memory timing modes, trap cause/PC, and no fault side effects.

## Required verification

Retain all current scalar, pipeline, and differential commands. Add real canonical targets for subword differential smoke, trap differential smoke, and extended random campaign; document their names when added. Run those plus exact seed rerun, immediate/delayed/backpressured/mixed modes, controlled negative test, `make lint`, `make check`, and `git diff --check`.

## Measurable acceptance criteria

Completion requires every supported load/store width, extension rule, byte-enable and preservation rule, x0 load, load-use case, common trap cause/PC/no-side-effect case, and all memory modes to pass differential comparison. The extended deterministic campaign must report seed count/runtime; exact reproduction and negative detection must work; existing regressions must pass; no external interface changes or production-readiness claim may be made. Update implementation status, verification plan, verification documentation, and factual milestone history. Do not commit or push.

## Stop conditions

Stop for human review if trap/misalignment/byte-enable/fault-side-effect semantics conflict, a likely reference-core bug appears, an external interface or broad pipeline redesign is needed, unsupported instructions would need to be added, state is not observable without invasive changes, the tree is dirty and attribution is unclear, or required tools fail.

## Required final report

Report the actual common memory/trap subset, generator and directed cases, comparison/memory constraints, byte-enable and trap checks, seed count/runtime/modes, exact results, negative evidence, bugs/fixes, changed files, diff review, blind spots, continuing experimental limitations, human-review items, and no-commit/no-push confirmation.
