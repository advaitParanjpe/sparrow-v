# Add full subword load/store differential coverage for the scalar pipeline

## Status

Approved bounded verification milestone. `rtl/core/rv32_core.sv` remains the protected production/reference core and must not change. `rtl/core/rv32_core_pipe.sv` remains experimental and is compared only through the existing deterministic differential framework; this milestone does not promote or integrate it.

## Objective and motivation

Extend deterministic scalar differential verification so `rv32_core` and `rv32_core_pipe` are compared across every currently supported scalar memory width and memory-data formatting behavior. The current differential campaign covers scalar ALU/control flow, LUI/AUIPC, LW/SW, ECALL, deterministic seeds, immediate/delayed/backpressured/mixed memory modes, final register and memory comparison, and controlled register-focused negative testing. Focused pipeline trap regressions also establish matching causes for instruction/control-target misalignment (0), load misalignment (4), and store misalignment (6).

The work strengthens the scalar-memory verification base before any production-pipeline promotion. It is not formal equivalence and does not change the pipeline's experimental status.

## In scope

- Differential directed and deterministic randomized coverage for LB, LBU, LH, LHU, LW, SB, SH, and SW.
- Signed and unsigned subword extension, byte-lane selection, store byte enables, and preservation of untouched bytes after partial stores.
- Loads to x0, stores without a destination-register write, load-use dependencies, mixed-width sequences, and store-to-load memory semantics.
- Valid byte offsets 0/1/2/3 and valid halfword offsets 0/2, sign-bit-set data patterns, and valid in-range aligned random accesses.
- Immediate-memory, request-backpressure, delayed-response, and mixed stall/delay modes.
- Deterministic seed reproduction, actionable mismatch diagnostics, a measured larger bounded random campaign, and memory-focused controlled negative detection.
- Factual documentation, verification-plan, scalar-verification, and milestone-history updates made when the implementation is complete.

## Out of scope

- New trap architecture or new trap-development work; existing trap regressions must remain passing.
- Production integration/replacement of `rv32_core_pipe`, or any change to `rtl/core/rv32_core.sv` without a reproducible reference-core bug and human approval.
- Vector ISA/datapath, sparse execution, scratchpad/cache/DMA, branch prediction, multiple outstanding memory requests, compiler/runtime, FPGA/ASIC, formal-equivalence claims, broad pipeline redesign, or new scalar instructions.

## Architectural constraints

- Existing memory interfaces and little-endian behavior remain unchanged.
- Byte enables must match access size and address offset. SB and SH preserve all untouched bytes.
- Signed loads sign-extend; unsigned loads zero-extend; LW returns the correct word.
- Loads to x0 do not alter architectural state. Stores do not write a destination register.
- Request/response handling remains correct under stalls and delays, with no duplicate memory request, writeback, or store side effect.
- Cycle counts need not match between cores; normalized architectural effects do.
- Normal generated programs use aligned accesses. Misalignment remains covered by the existing focused trap regression, not by new random generation.

## Directed differential coverage

Add focused differential cases that check architectural retirement/register/store/final-memory effects for:

- LB with positive data and with byte bit 7 set; LBU with byte bit 7 set.
- LH with positive data and with halfword bit 15 set; LHU with halfword bit 15 set; LW.
- SB at offsets 0, 1, 2, and 3; SH at offsets 0 and 2; SW.
- Surrounding-byte preservation after SB and SH.
- A load to x0.
- A dependent ALU instruction after each load width, plus a dependent branch or address calculation after representative loads.
- Consecutive mixed-width loads and stores, and store followed by load from the same address.
- Subword access under request backpressure, subword load under delayed response, and subword access under mixed stall/delay behavior.

Directed checks must show byte-lane, extension, destination-write, byte-enable, and final-memory effects rather than merely terminal completion.

## Random generation and campaign

Extend the active differential generator with aligned subword loads/stores while retaining deterministic execution from a recorded seed. Generated programs must:

- use valid in-range data-memory addresses, avoid self-modifying code, remain bounded, and guarantee termination;
- exercise all four byte lanes and both valid halfword offsets;
- generate values with byte bit 7 and halfword bit 15 set;
- include all supported load/store widths and report the actual generated instruction mix;
- preserve failing seeds as reproducible regressions.

Measure runtime before selecting the campaign size. Run more than the existing 32 immediate-mode seeds; 100–250 seeds is acceptable only when the measured runtime is practical. Report exact seed count, runtime, modes, and an exact reproduction command.

## Controlled negative testing

Retain the existing register-focused controlled negative test. Add a memory-focused controlled negative case that intentionally corrupts exactly one load-extension result, store byte enable, or final memory byte. The checker must detect the intended mismatch without relying on timeout.

## Canonical targets to add

Use repository naming conventions and add real Make targets for:

| Purpose | Target to add |
| --- | --- |
| Focused subword directed differential smoke | `test-scalar-diff-subword-directed` |
| Extended deterministic random campaign | `test-scalar-diff-subword-random` |
| Request-backpressure, delayed-response, and mixed modes | `test-scalar-diff-subword-stall` |
| Exact seed/mode reproduction | `test-scalar-diff-subword-seed SEED=<n> MODE=<n>` |
| Memory-focused controlled negative test | `test-scalar-diff-subword-negative` |

The implementation may reuse the existing differential harness and mode encoding, but these targets must be canonical, documented, and self-checking.

## Required verification

Run and report:

- all current production scalar tests;
- all current focused pipeline tests, including `make test-scalar-pipe-trap`;
- all current differential tests;
- the new directed subword differential test, extended randomized campaign, exact-seed rerun, and every memory timing mode;
- existing register-focused and new memory-focused controlled negative tests;
- `make lint`, `make check`, and `git diff --check`.

## Acceptance criteria

The milestone is complete only when:

1. Every supported load and store width is differentially verified.
2. Signed/unsigned extension, byte enables, partial-store preservation, x0 loads, and load-use behavior are checked.
3. All valid byte and halfword offsets are exercised.
4. Immediate, delayed, backpressured, and mixed memory modes pass.
5. The larger deterministic campaign passes, reports actual mix/seed count/runtime, and supports exact seed reproduction.
6. Both controlled negative tests detect their intended mismatches.
7. All prior regressions, including focused pipeline traps, remain passing.
8. No external interface changes occur and `rtl/core/rv32_core.sv` remains unchanged.
9. Documentation and milestone history are updated with measured results; no commit or push occurs.

## Stop conditions

Stop for human review only if reference and pipeline memory semantics materially conflict, byte-enable behavior is ambiguous, a reference-core bug is found, an external interface change is required, a broad pipeline redesign is required, the supported instruction subset is unclear, or required observability needs invasive interface changes. Missing tests, generator work, or harness implementation are not stop conditions.

## Documentation requirements

On completion, factually update `docs/implementation_status.md`, `docs/verification_plan.md`, relevant scalar verification documentation, and `docs/milestone_history.md`; update `README` only if stable user-facing commands are added. Document the supported subset, directed coverage, randomized instruction mix, campaign size/runtime, memory modes, negative-test evidence, bugs/fixes, remaining blind spots, and why the pipeline remains experimental.

## Required final report

Report:

1. `MILESTONE COMPLETE` or `MILESTONE NOT COMPLETE`.
2. Directed subword cases and random-generator changes.
3. Actual tested instruction subset, seed count, runtime, and memory modes.
4. Negative-test evidence, bugs/fixes, exact commands/results, and documentation updates.
5. Complete changed-file list, diff-review findings, and remaining limitations.
6. Confirmation that the reference core was unchanged and that no commit or push occurred.
