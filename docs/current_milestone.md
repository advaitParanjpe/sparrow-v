# Implement and verify the minimal scalar-to-vector command/completion adapter with a stub vector engine

## Status

Approved bounded experimental-integration milestone. `rtl/core/rv32_core.sv` remains the protected production/reference scalar core and must not change. `rtl/core/rv32_core_pipe.sv` remains experimental and is the only scalar integration candidate in scope. This milestone implements the approved v1 command/completion boundary with a stub engine; it does not implement a real vector architecture or promote the pipeline.

## Objective

Implement a minimal scalar-to-vector integration path and deterministic stub vector engine that exercise the approved blocking, in-order, one-command-outstanding protocol. Prove that a custom instruction decodes to a decoupled command, blocks scalar progress after acceptance, completes exactly once with either a scalar result or a precise exception, and behaves correctly under reset and both command/completion backpressure.

The result is experimental integration evidence, not a final Sparrow-V vector ISA, vector datapath, vector-register implementation, vector-memory system, or basis for scalar-core promotion.

## Entry architecture and audit

Before implementation read `AGENTS.md`, `README.md`, `docs/architecture.md`, `docs/architecture/scalar_vector_interface.md`, `docs/architecture/scalar_interface_freeze.md`, `docs/architecture/scalar_production_readiness.md`, `docs/implementation_status.md`, `docs/verification_plan.md`, `docs/milestone_history.md`, this document, and relevant ADRs including ADR-003, ADR-004, ADR-005, ADR-008, ADR-012, and ADR-013. Audit `rv32_core_pipe`, decoder/package/register file/trap/retirement logic, focused pipeline testbenches, Makefile targets, and applicable scripts. Read nested `AGENTS.md` files if present.

Record a clean `git status --short`, commit identifier, tool versions, exact commands, exit status, and wall time. Determine and document:

- custom-0 (`0001011`) reservation and current illegal-instruction behavior;
- the chosen minimal instruction encoding/field extraction without claiming a full ISA;
- command fields, scalar source capture, destination metadata, fixed ID, and completion fields already specified by `scalar_vector_interface.md`;
- current MW blocking, retirement, terminal trap, reset, redirect, and scalar memory behavior;
- where accepted command state and completion enter the pipeline; and
- whether direct pipeline integration or a wrapper is the smallest compatible design.

The implementation must choose and document one approach. Direct integration may add clearly marked experimental vector ports only to `rv32_core_pipe` while preserving all existing scalar ports and leaving the frozen `rv32_core` interface untouched. A wrapper is acceptable only if it does not duplicate or bypass scalar decode, retirement, trap, or ordering behavior. Stop for human review if neither choice is possible without a material external-interface or broad-control redesign.

## In scope

- One initial custom-0 stub-success instruction and one stub-exception instruction, or an equivalently minimal documented pair.
- Vector-command decode, decoupled `vec_cmd_valid/ready`, command payload, PC, scalar source capture, optional scalar destination metadata, fixed command ID, and one-outstanding state.
- Decoupled `vec_cpl_valid/ready`, completion status/result/cause, precise success retirement, precise exception trap, reset cancellation, and command/completion backpressure.
- A standalone deterministic stub engine with busy state and configurable bounded latency.
- Focused adapter/stub testbenches, assertions, canonical Make targets, scalar-regression preservation, and factual documentation.

## Out of scope

- Vector register file, vector ALU, multiply/dot/reduction/mask datapath, vector loads/stores, vector memory interface implementation, scratchpad/cache, sparse metadata/2:4 execution, compiler/assembler support, FPGA/ASIC work, performance optimization, or a full vector ISA.
- Production promotion or renaming of `rv32_core_pipe`, changes to `rv32_core`, broad pipeline redesign, multiple outstanding commands, speculative issue, out-of-order completion, or a claim of formal equivalence.

## Initial experimental instruction behavior

Use custom-0 only, consistent with ADR-003. During implementation document exact bit fields and add a decoder table/test helper. The initial behavior must be intentionally minimal and explicitly non-ISA-final:

| Instruction class | Required behavior |
| --- | --- |
| Stub success | Accept normal command operands/metadata; after deterministic latency complete successfully with a simple documented scalar result (for example `rs1 + rs2`, pass-through, or another fixed transformation); optionally write `rd`; retire once. |
| Stub exception | Accept normally; after deterministic latency complete with a documented non-success cause; write no scalar result; trap precisely at the issuing PC. |

The implementation must not expose the operation as an architectural vector arithmetic promise beyond this test-only integration boundary.

## Command protocol requirements

- A command transfers only on `vec_cmd_valid && vec_cmd_ready`; every payload field remains stable while valid is held without ready.
- The accepted command captures operation class/funct, opaque vector indices when present, scalar source data/valid bits, scalar `rd`/write-enable intent, immediate payload, issuing PC, and fixed-zero v1 ID.
- No second command may be accepted while one command is outstanding; a killed/wrong-path instruction issues no command; scalar stalls cannot duplicate command transfer.
- Reset clears command/outstanding state and prevents acceptance during reset.
- `vec_cmd_ready` backpressure is supported for arbitrary finite time and is low while the stub/adapter has an outstanding command.

## Completion protocol requirements

- A completion transfers only on `vec_cpl_valid && vec_cpl_ready`; all fields remain stable while valid is held without ready.
- Completion includes fixed-zero ID, success/exception/illegal status, optional result-valid/data, and exception cause. The adapter rejects or asserts on a completion without a matching outstanding command.
- Success writes the captured scalar destination only if completion result-valid, command write-enable, and `rd != 0`; a vector-only form must retire without fabricated scalar writeback.
- Exception writes no scalar destination, traps exactly once at the captured issuing PC with the documented cause, and cannot retire as success.
- Completion is accepted exactly once; no stale completion is accepted after reset.

## Scalar ordering, stall, retirement, and trap semantics

- Scalar issue is in order, non-speculative, and blocks after command acceptance until completion acceptance.
- All older scalar work completes before command acceptance. No younger scalar instruction may retire, write state, or issue a vector command while the command is active.
- A successful vector instruction retires exactly on accepted successful completion through the existing scalar retirement bundle: `retire_valid=1`, its issuing PC/instruction, optional scalar writeback, no memory retirement side effect, and one `instret_count` increment.
- A vector exception enters the existing terminal precise trap path at captured command PC, emits one trap retirement event, writes no scalar destination, and prevents younger architectural effects.
- Scalar fetch/decode may only resume after the success or trap handling leaves no outstanding vector work. Normal scalar instructions and existing memory/redirect behavior must remain unaffected.

## Stub vector engine requirements

Implement a small standalone stub module, not a vector execution unit. It must provide command-ready backpressure, captured command state, parameterized/configurable deterministic latency, a busy indication/internal counter if useful to verification, success and exception completion generation, completion-valid holding under `vec_cpl_ready` backpressure, and reset cancellation. It must contain no vector register state, vector ALU/MAC, vector memory port, scratchpad logic, sparse metadata, or lane datapath.

## Assertions

Add assertions that prove or check:

- command payload stability under command backpressure;
- completion payload stability under completion backpressure;
- no second command while outstanding/busy;
- no completion without outstanding command and matching fixed ID;
- no simultaneous successful scalar writeback and exception;
- no duplicate command, completion, or retirement;
- no younger retirement while blocked; and
- reset clears adapter/stub outstanding state and suppresses stale completion.

## Focused verification

Add self-checking focused tests for:

- immediate command acceptance and deterministic multi-cycle completion;
- prolonged command backpressure and command-payload stability;
- prolonged completion backpressure and completion-payload stability;
- successful scalar writeback, vector-only/no-`rd` writeback, and exactly-once success retirement;
- one-outstanding enforcement and no duplicate command/completion/retirement;
- stub-exception cause and exact issuing-PC trap with no writeback;
- no younger scalar retirement before completion; scalar instruction before and after completion;
- taken branch around a vector instruction and wrong-path vector instruction suppression;
- reset while idle and reset while command/completion is outstanding, with no stale completion afterward; and
- preservation of all ordinary scalar behavior.

## Canonical targets to add

Use repository naming conventions and add real, self-checking targets:

| Purpose | Target to add |
| --- | --- |
| Focused adapter/stub success and ordering regression | `test-scalar-pipe-vec-stub` |
| Command-ready backpressure/payload-stability regression | `test-scalar-pipe-vec-cmd-stall` |
| Completion-ready backpressure/payload-stability regression | `test-scalar-pipe-vec-cpl-stall` |
| Precise stub-exception regression | `test-scalar-pipe-vec-exception` |
| Aggregate adapter/stub regression | `test-scalar-pipe-vec-stub-all` |

The aggregate target must run every focused adapter/stub test. Add an exact parameter or target for deterministic latency/backpressure reproduction if the tests use configurable modes.

## Required verification

Run and report every new adapter/stub target; `make test-scalar-directed`; all existing `test-scalar-pipe-*` targets including store-retirement and trap; all scalar differential smoke/random/stall/negative/redirect/subword/store-retirement targets; `make lint`; `make check`; `make docs-check`; and `git diff --check`.

Do not run the expected-failing throughput experiment as a required pass. Record exact commands, completion status, wall time, latency/backpressure configuration, command/completion counts, trap PC/cause, and deterministic rerun commands.

## Acceptance criteria

The milestone is complete only when:

1. A documented experimental integration boundary and selected direct/wrapper architecture exist.
2. At least one custom-0 stub instruction decodes and issues a complete v1 command payload.
3. Command valid/ready and payload stability are correct under backpressure.
4. Exactly one command may be outstanding and scalar execution blocks while it is active.
5. Success completion valid/ready and payload stability are correct under backpressure.
6. Successful completion optionally writes the correct scalar result and retires exactly once.
7. Exception completion traps once with exact PC/cause and no scalar writeback.
8. No younger scalar retirement occurs before the blocking vector instruction completes.
9. Wrong-path vector instructions issue no command.
10. Reset cancels outstanding work and no stale completion is accepted afterward.
11. Assertions cover the key protocol and ordering rules.
12. All prior scalar regressions remain passing.
13. No real vector datapath/register file/memory/sparse logic is implemented.
14. Documentation and milestone history are factual; no production promotion occurs.
15. No commit or push occurs.

## Stop conditions

Stop for human review if frozen scalar interfaces must change materially; command/completion behavior conflicts with accepted ADRs; precise retirement requires broad pipeline redesign; reset/trap semantics are ambiguous; custom-0 conflicts with current scalar decoding; wrapper versus direct integration has material unresolved consequences; a likely scalar bug is found; or multiple outstanding commands become necessary. Missing tests or ordinary adapter work are not stop conditions.

## Documentation requirements

On completion update `docs/architecture/scalar_vector_interface.md`, `docs/architecture.md`, `docs/implementation_status.md`, `docs/verification_plan.md`, relevant ADRs when clarification is necessary, and `docs/milestone_history.md`; update `README.md` only for stable user-facing test commands. Document the experimental encoding, command/completion fields, selected integration architecture, blocking/retirement/exception/reset behavior, stub behavior, tests, limitations, and why this is not a real vector implementation.

## Required final report

Report:

1. `MILESTONE COMPLETE` or `MILESTONE NOT COMPLETE`.
2. Selected integration architecture and experimental instruction encoding.
3. Command/completion protocol, pipeline stall/retirement, exception/reset, and stub behavior implemented.
4. Tests/assertions added, exact commands/results, deterministic configurations, bugs/fixes, and changed files.
5. Diff-review findings and remaining limitations.
6. Confirmation that no real vector datapath/register file/memory was implemented, `rv32_core.sv` was unchanged, and no commit or push occurred.
