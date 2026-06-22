# Repair and verify `rv32_core_pipe` store-retirement trace outputs

## Status

Implementation complete, pending human review and commit. `rtl/core/rv32_core.sv` remains the protected production/reference scalar implementation. `rtl/core/rv32_core_pipe.sv` remains experimental. This milestone repaired and verified only the pipeline store-retirement trace contract; it did not promote, rename, replace, or otherwise integrate either core.

## Objective

Make `rv32_core_pipe` contract-compatible with the frozen v1 scalar retirement interface by accurately reporting retired store instructions through `retire_mem_we`, `retire_mem_addr`, `retire_mem_data`, and `retire_mem_wstrb`, while preserving all existing scalar behavior.

At milestone entry, the pipeline continuously drove all four fields to zero. The reference core emits a one-cycle store-retirement event when the outstanding store's data-memory response handshakes. It reports the effective byte address, unshifted scalar store operand, and the request's little-endian lane strobe. The repaired pipeline now matches that architectural event and representation; matching port names or accepted store requests alone remains insufficient evidence.

## Entry baseline and audit requirements

Before editing RTL or tests, read `AGENTS.md`, `README.md`, `docs/architecture.md`, `docs/architecture/scalar_interface_freeze.md`, `docs/architecture/scalar_production_readiness.md`, `docs/implementation_status.md`, `docs/verification_plan.md`, `docs/milestone_history.md`, this document, relevant ADRs (at minimum ADR-012 and ADR-013), both core implementations, current retirement declarations/assignments, memory and differential testbenches, and `Makefile`. Read any nested `AGENTS.md` files.

Inspect recent Git history and record a clean `git status --short`, commit identifier, tool versions, exact commands, exit status, and wall time. Treat the RTL, the frozen interface specification, and directly run tests as the source of truth.

The audit must establish and document:

- the reference store retirement event: accepted data response, not request acceptance;
- the reference representation: effective byte `retire_mem_addr`, unshifted `retire_mem_data`, and lane-positioned `retire_mem_wstrb` for SB/SH/SW;
- store request/response behavior under request backpressure and response delay;
- exact-once retirement behavior and absence of register-write retirement for stores;
- suppression of faulting, killed, stale, wrong-path, and younger-after-terminal-trap stores;
- reset and redirect interaction with store retirement.

Do not infer any of these rules only from signal names. The frozen v1 interface requires a response handshake for store retirement even if an existing pipeline-oriented memory model currently completes writes at request acceptance; that model must be brought into contract-compatible verification during implementation rather than redefining the scalar interface.

## In scope

- `retire_mem_we`, `retire_mem_addr`, `retire_mem_data`, and `retire_mem_wstrb` in `rv32_core_pipe`.
- SB, SH, and SW, including byte offsets 0/1/2/3 and halfword offsets 0/2.
- Exact-once store retirement, request backpressure, response delay, mixed timing, branches/redirects, traps, and reset.
- A focused pipeline store-retirement regression and direct normalized differential comparison against `rv32_core`.
- Deterministic exact-seed reproduction, controlled negative detection, factual documentation updates, and a promotion recommendation after evidence exists.

## Out of scope

- Vector RTL, scalar-to-vector adapter RTL, vector memory RTL, scratchpad/cache work, compiler/runtime work, new ISA instructions, formal-equivalence claims, FPGA/ASIC implementation, throughput redesign, or a broad pipeline redesign.
- Production promotion, module/file renaming, deletion, replacement of `rv32_core`, or automatic change to the human-approved C (do not promote) decision.

## Architectural constraints

- Frozen external scalar interfaces and the v1 retirement contract remain unchanged.
- A store retirement event must coincide with the same architectural completion event as the reference core: completion of the sole outstanding data transaction by response handshake, not merely request acceptance.
- Each retired store emits one and only one cycle with `retire_valid=1`, `retire_mem_we=1`, and the reference-equivalent address, data, and strobe fields.
- `retire_mem_addr` is the effective byte address; it is not the word-aligned data-port address.
- `retire_mem_data` is the unshifted scalar store operand; `retire_mem_wstrb` is lane-positioned little-endian byte enable data: SB selects one lane, SH selects lanes 0/1 or 2/3, and SW selects all lanes.
- A store held before request acceptance does not retire early; a held request and a delayed response cannot produce duplicate retirement.
- Faulting/misaligned, killed/stale/wrong-path, and younger-after-terminal-trap stores emit no request side effect and no store-retirement event.
- Stores do not invent `retire_rd_we` or a scalar register write. Cycle timing may differ between implementations, but normalized architectural retirement may not.
- `rv32_core.sv` remains unchanged unless a reproducible reference-core defect and explicit human approval require otherwise.

## Focused directed verification

Add a self-checking focused pipeline testbench, preferably `tb/integration/tb_scalar_pipe_store_retire.sv`, and canonical target to add:

| Purpose | Target to add |
| --- | --- |
| Focused pipeline store-retirement contract regression | `test-scalar-pipe-store-retire` |

The focused regression must directly observe the pipeline retirement outputs and prove:

- SB at offsets 0, 1, 2, and 3; SH at offsets 0 and 2; and SW;
- effective retired address, unshifted retired data, and correct lane strobe for every case;
- exactly one retirement pulse per accepted/completed store and no register-write retirement;
- no retirement before request acceptance or before the required response completion;
- correct behavior with request backpressure, delayed response, and mixed stall/delay timing;
- consecutive and mixed-width consecutive stores;
- stores before and after a taken branch, plus wrong-path store suppression;
- misaligned SH/SW with no request or retirement event;
- terminal trap suppression of younger store retirement; and
- reset with no stale retirement event.

The test must check architectural effects and event count, not merely final memory or terminal completion.

## Differential store-retirement verification

Extend `tb/integration/tb_scalar_differential.sv` so it records and compares normalized store-retirement events independently of accepted store-request traces. For each event compare retirement order, effective address, unshifted data, lane strobe, and exact count. Preserve the accepted-store-request comparison as a secondary memory-side-effect check; it must no longer substitute for retirement-contract comparison.

Add canonical targets only where needed for reproducibility:

| Purpose | Target to add |
| --- | --- |
| Direct store-retirement differential regression across modes | `test-scalar-diff-store-retire` |
| Controlled store-retirement negative detection | `test-scalar-diff-store-retire-negative` |

The direct comparison must run under immediate memory (mode 0), request backpressure (mode 1), delayed response (mode 2), and mixed timing (mode 3), use `make test-scalar-diff-seed SEED=<n> MODE=<n>` for exact reproduction, and include the current subword directed/random/stall campaign. Do not require cycle-by-cycle equality.

## Controlled negative testing

Add or extend a deterministic negative mode that corrupts exactly one recorded pipeline store-retirement address, data, strobe, or event count after collection. The checker must report the intended mismatch and pass only because detection occurred; it must not depend on timeout or corrupt the underlying request-side-effect comparison.

## Promotion reassessment

After all evidence is complete, update the production-readiness assessment and ADR-012 only if the recommendation changes. The implementation may recommend continued C (do not promote), conditional promotion, or promotion readiness, but it must not rename, promote, or substitute the pipeline automatically.

Any reconsideration requires all current regressions passing, direct contract equivalence, no newly discovered correctness blocker, factual documentation, and human review. Passing this narrow trace repair alone does not establish performance, synthesis, formal, or broad verification readiness.

## Required verification

Run and report:

```sh
make test-scalar-pipe-store-retire
make test-scalar-pipe-dev
make test-scalar-pipe-alu
make test-scalar-pipe-forward
make test-scalar-pipe-control
make test-scalar-pipe-redirect
make test-scalar-pipe-memory
make test-scalar-pipe-trap
make test-scalar-diff-smoke
make test-scalar-diff-random
make test-scalar-diff-stall
make test-scalar-diff-negative
make test-scalar-diff-redirect-backpressure
make test-scalar-diff-subword-directed
make test-scalar-diff-subword-random
make test-scalar-diff-subword-stall
make test-scalar-diff-subword-negative
make test-scalar-diff-store-retire
make test-scalar-diff-store-retire-negative
make test-scalar-diff-seed SEED=<recorded-seed> MODE=<0|1|2|3>
make lint
make check
make docs-check
git diff --check
```

Document the exact seeds, modes, runtime, and outputs used by the new differential target. The existing expected-failing throughput experiment remains non-blocking and cannot support a promotion claim.

## Acceptance criteria

The milestone is complete only when:

1. `rv32_core_pipe` drives all four `retire_mem_*` fields according to the frozen reference contract.
2. SB, SH, and SW are directly covered at every valid byte/halfword offset.
3. Every completed store retires exactly once, with no early, duplicate, or register-write retirement.
4. Request-backpressured, delayed-response, and mixed timing behavior is proven correct.
5. Faulting/misaligned, killed/wrong-path, stale, and younger-after-terminal-trap stores produce no retirement event.
6. Reset leaves no stale store-retirement event.
7. The focused pipeline regression and direct differential store-retirement comparison pass.
8. Exact seed/mode reproduction and controlled-negative detection work.
9. All prior scalar, focused pipeline, differential, trap, lint, and repository regressions remain passing.
10. `rv32_core.sv` and frozen external interfaces remain unchanged.
11. Documentation and milestone history are updated factually; promotion status is reassessed but not enacted automatically.
12. No vector RTL, commit, or push is performed.

## Stop conditions

Stop for human review if the reference retirement contract is ambiguous; store retirement semantics differ materially between cores; an external interface change is required; exact completion cannot be observed without invasive redesign; a broad pipeline-control redesign is required; a likely reference-core defect is found; or promotion would require restructuring beyond this milestone. Missing tests or harness support are implementation work, not stop conditions.

## Documentation requirements

On completion update `docs/architecture/scalar_production_readiness.md`, `docs/architecture/scalar_interface_freeze.md` if clarification is necessary, `docs/implementation_status.md`, `docs/verification_plan.md`, relevant scalar verification documentation, and `docs/milestone_history.md`. Update ADR-012 only if the promotion recommendation changes. Update `README.md` only if stable user-facing commands change.

## Required final report

Report:

1. `MILESTONE COMPLETE` or `MILESTONE NOT COMPLETE`.
2. The exact retirement contract derived from the reference core and freeze.
3. RTL/test/harness changes and direct differential comparison added.
4. Store widths/offsets, exact-once, timing-mode, redirect/trap/reset, and controlled-negative evidence.
5. Exact commands, seeds, modes, runtime, and pass/fail results.
6. Bugs found, fixes made, promotion recommendation, documentation updates, complete changed-file list, and diff-review findings.
7. Remaining limitations and human-review items.
8. Confirmation that `rv32_core.sv` was unchanged and no vector RTL, commit, or push occurred.
