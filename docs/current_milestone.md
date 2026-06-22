# Pipeline production-readiness review and scalar-to-vector interface definition

## Status

Approved architecture, audit, specification, and decision milestone. This milestone does not implement vector RTL, alter scalar RTL, rename modules, delete files, change build behavior, or promote a core before the evidence and human-review conditions below are met. `rtl/core/rv32_core.sv` remains the protected production/reference scalar core at milestone entry; `rtl/core/rv32_core_pipe.sv` remains experimental at milestone entry.

## Objective

Determine whether `rv32_core_pipe` is sufficiently correct, interface-stable, verified, maintainable, and integration-ready to become Sparrow-V's primary scalar CPU, while retaining `rv32_core` as a reference model when appropriate. Separately define a stable scalar interface freeze and a minimal custom scalar-to-vector command/completion boundary for a later vector-engine milestone.

This is not a throughput-promotion milestone. Passing architectural differential tests establishes only correctness within their exercised domain; it does not establish sustained-throughput, timing, area, formal-equivalence, or production-integration readiness.

## Entry baseline and constraints

The entry baseline includes the protected/reference scalar core, isolated pipelined scalar core, directed ALU/forwarding/control/redirect/memory/trap tests, deterministic normalized differential comparison, all supported load/store widths, immediate/delayed/backpressured/mixed memory modes, exact-seed reproduction, a 128-seed immediate subword campaign, controlled register and memory negative tests, matching misalignment causes, and fixes for redirect/backpressure and terminal retirement. No formal-equivalence proof exists. `check-scalar-throughput-experiment` is an expected-failing historical experiment and must remain non-blocking.

The milestone must preserve existing architectural behavior unless a concrete, reproducible defect or an accepted ADR justifies a change. It must not weaken assertions, bypass tests, classify an expected failure as a pass, or convert verification-only behavior into an external contract accidentally.

## In scope

- Repository, RTL, interface, test, build-script, documentation, and Git-history audit.
- A structured production-readiness comparison and evidence-based promotion decision for both scalar implementations.
- A measured, bounded, deterministic scalar confidence campaign before that decision.
- Scalar architectural/interface freeze specification and classification of stable, verification-only, and intentionally unstable signals.
- A minimal custom vector command/completion protocol, vector-state boundary, memory-boundary recommendation, ordering/retirement/exception semantics, and integration roadmap.
- ADRs and factual documentation updates required to record the decisions.

## Out of scope

- Vector RTL, vector register-file RTL, vector ALU/MAC, scratchpad RTL, vector ISA implementation, sparse metadata decoding, compiler/assembler changes, cache, branch prediction, throughput redesign, production file/module renaming, file deletion, FPGA/ASIC implementation, and formal equivalence.
- A claim that simulation establishes synthesis timing, area, power, or formal proof.

## Phase 1 — repository and architecture audit

Before assessing or changing any architecture document, read `AGENTS.md`, `README.md`, `docs/architecture.md`, `docs/implementation_status.md`, `docs/verification_plan.md`, `docs/milestone_history.md`, `docs/verification/scalar_phase_1.md`, this document, all ADRs, both scalar cores, the decoder/package/register-file/ALU/immediate sources, all scalar and differential testbenches, `Makefile`, and applicable scripts. Read nested `AGENTS.md` files if present.

Inspect recent Git history and record `git status --short`; the promotion decision is invalid if the baseline is not clean or if evidence cannot be attributed to a documented tree state. Record the exact commit identifier, tool versions, test commands, exit status, wall time, and any expected/non-blocking failure distinctly.

Rerun and record the current scalar/differential baseline before any promotion conclusion:

```sh
make test-scalar-directed
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
make lint
make check
```

Do not run `make test-scalar-random` as a required pass: it is documented as blocked. Run `make check-scalar-throughput-experiment` only to record its expected failure and limitations; it cannot block correctness readiness or support a performance claim.

## Phase 2 — production-readiness assessment

Create a comparison table for `rv32_core` and `rv32_core_pipe` that cites concrete source/test evidence for each item below, identifies intentional differences, and distinguishes unverified assumptions from demonstrated behavior:

- supported instruction subset and decode/illegal-instruction handling;
- trap causes, trap state, fault PC, side-effect suppression, and terminal behavior;
- instruction/data memory request-response semantics, alignment, byte strobes, response timing, and outstanding-transaction limits;
- fetch, redirect, stale-response, request-backpressure, and response-backpressure handling;
- forwarding/interlocks, retirement event/trace semantics, counters, reset behavior, and externally visible ports;
- observability/debug signals, testbench coupling, code quality/maintainability, lint results, and synthesis suitability;
- verification depth, negative-test evidence, known blind spots, and expected performance limits.

Rate each core separately in five non-interchangeable categories: (1) correctness readiness, (2) interface stability, (3) verification maturity, (4) performance readiness, and (5) production naming/integration readiness. A passing differential campaign may support (1) only for the tested subset/modes; it cannot by itself raise the ratings for (3)–(5).

Explicitly identify whether `retire_mem_*` behavior, performance counters, and terminal trap behavior are architectural, integration, or verification-only contracts. Assess whether either core relies on simulation-only constructs or interfaces that make it unsuitable for synthesis integration. Do not infer that matching output-port names means matching semantics.

## Phase 3 — broader deterministic confidence campaign

Before any promotion decision, measure the runtime of a representative immediate-mode differential batch and choose a practical deterministic campaign size. Target 500–1000 immediate-mode seeds only if measured wall time and available tooling make it practical; otherwise select and justify the largest lower bounded count that preserves a useful review cadence. Document seed range, generator/instruction mix, tool versions, timeout policy, total wall time, and exact rerun commands.

The final campaign must include:

- all directed scalar and focused pipeline regressions listed in Phase 1;
- all current differential directed, random, redirect/backpressure, trap, and controlled-negative regressions;
- the measured large immediate-mode differential campaign;
- a representative, explicitly stated smaller seed set in each request-backpressured, delayed-response, and mixed mode;
- exact-seed reruns selected from each mode, including any failure reproduction if encountered;
- lint, repository checks, documentation checks, `git diff --check`, and a final working-tree audit.

The implementation may add a documented campaign target only if needed to make this reproducible. It must not call the campaign complete merely because an old 128-seed target passed, and it must not require formal equivalence.

## Phase 4 — promotion decision framework

Produce exactly one evidence-based conclusion:

| Conclusion | Meaning |
| --- | --- |
| **A. Promote** | `rv32_core_pipe` becomes the primary Sparrow-V scalar CPU. |
| **B. Conditionally promote** | It becomes the primary development core, with specific documented limitations and gates. |
| **C. Do not promote** | It remains experimental because a concrete correctness, interface, verification, or maintainability blocker remains. |

The conclusion must reference the Phase 2 ratings, campaign results, unresolved differences, and known blind spots. If A or B is selected, specify whether renaming is deferred (default) or requires a later approved milestone; whether `rv32_core.sv` remains the reference model; how tests label/reference the primary versus reference core; interfaces frozen by this milestone; behaviors still experimental; and exact documentation claims permitted. Do not perform promotion, renaming, or deletion in this milestone.

If C is selected, name each concrete blocker, required evidence/fix, and the bounded follow-up milestone. A vague preference for one implementation is not evidence.

## Phase 5 — scalar interface freeze

Publish a scalar-interface specification that lists signal names, direction, width, reset/validity behavior, handshake obligations, transaction/ordering limits, and intended consumers. At minimum classify the following:

| Classification | Required treatment |
| --- | --- |
| Stable architectural/integration interfaces | `clk`, synchronous active-low `rst_n`, parameters affecting reset vectors, instruction-memory request/response, data-memory request/response, trap outputs, retirement outputs, and integration-level top ports. Freeze their semantics before vector integration. |
| Stable observability interfaces | `cycle_count`, `instret_count`, and any trace/debug output retained for system integration. State whether each is architectural or debug-only and give it a versioned semantic contract if it is retained. |
| Verification-only interfaces | Differential trace fields, testbench hierarchy access, controlled-negative hooks, and any internal counters used only by tests. Do not expose these to the vector engine or make them a software ABI. |
| Intentionally unstable/deferred interfaces | Microarchitectural stall/flush counters, pipeline-stage internals, performance counters not explicitly frozen, core naming, and future vector-specific ports until their specification/ADR is accepted. |

The specification must state that the vector engine must not observe scalar register-file internals, fetch state, pipeline stage valid bits, redirect epochs, internal hazards, or raw memory-port timing. It must consume only the defined extension boundary and, where selected, its own memory boundary.

## Phase 6 — scalar-to-vector interface definition

Create `docs/architecture/scalar_vector_interface.md` (or an equivalently named dedicated specification) and define the protocol independently of vector datapath RTL. It must be cycle-precise enough for a future RTL/testbench implementation, while leaving detailed vector operation semantics to a later ISA milestone.

### Command issue

Specify a decoupled `valid/ready` command channel with command acceptance defined as `cmd_valid && cmd_ready`. Define the exact fields and widths or an explicitly versioned packed command record for:

- decoded operation identifier/class and reserved/illegal encoding behavior;
- source scalar operands and valid bits;
- scalar destination-register metadata and writeback-enable intent;
- immediate/function fields and vector register indices where relevant;
- instruction PC and an instruction identity/tag policy;
- privilege/trap context, or an explicit Phase-1 statement that it is absent;
- reset behavior and whether command acceptance can be backpressured.

Reserve custom-0 only consistently with ADR-003. Do not freeze a full vector ISA, lane semantics, sparse encoding, or software ABI here.

### Completion

Specify a completion channel with `valid/ready` handshake (or justify an equivalent protocol). Define completion acceptance, result-valid semantics, scalar destination/result data, exception/trap indication and cause ownership, completion status, identity/tag, cancellation/reset behavior, and ordering guarantees. A completion with no scalar result must be representable without an invented scalar writeback.

### Initial ordering, stall, retirement, and exception policy

Adopt or explicitly reject the following minimum initial policy; any rejection requires a comparison and an accepted ADR:

- one vector command outstanding;
- in-order scalar issue and in-order vector completion;
- scalar pipeline stalls after command acceptance until completion is accepted;
- no speculative vector issue;
- vector instruction retires exactly at accepted successful completion, not at command issue;
- vector exceptions are precise: no destination writeback/retirement occurs, scalar trap state identifies the issuing instruction, and younger scalar work cannot become architecturally visible;
- redirects and scalar traps cannot leave an uncancelled architecturally visible vector command; define whether they are impossible under blocking or require reset/cancellation acknowledgement.

Specify command-ready behavior while a command is outstanding, whether a scalar destination is reserved before completion, how x0 is treated, and what happens on reset. Explain why tags are unnecessary for the one-outstanding initial policy, while reserving a future extension path rather than exposing unneeded tag machinery now.

### Memory boundary decision

Compare and recommend one initial vector-memory boundary: dedicated scratchpad, shared scalar data-memory port, explicit vector load/store commands with another owner, or a separate vector memory interface. The recommendation must evaluate implementation complexity, verification difficulty, future banked-scratchpad support, scalar/vector contention, clean software model, ordering/exception behavior, and later ASIC synthesis.

The selected first boundary must state ownership, arbitration/ordering responsibility, address/data/byte-enable semantics where applicable, reset/error behavior, and whether scalar/vector memory can overlap. It must remain a documented architecture choice only; no scratchpad or vector-memory RTL is permitted.

### Register-state and ISA boundaries

Specify that vector registers are owned entirely by the vector engine and remain independent of the scalar register file. Define how vector register indices are encoded/transported, the scalar-operand/result crossing rules, vector reset state, and architectural versus debug observation of vector state. Defer register count/width, mask/tail policy, lane arithmetic, sparse metadata, and detailed instruction semantics to their existing or later ADRs. The extension mechanism may propose operation classes/encoding allocation, but must not claim a full vector ISA.

## Phase 7 — ADRs and documentation

Create or update ADRs with context, alternatives, decision, consequences, and deferred questions for:

- scalar pipeline promotion decision and treatment of `rv32_core` as reference;
- scalar interface freeze and observability classification;
- scalar-to-vector command/completion protocol and one-outstanding policy (update ADR-004 or supersede it explicitly);
- vector register-state ownership (update ADR-005 or supersede it explicitly);
- initial vector memory boundary and ordering implications (update ADR-007 and ADR-008 or supersede them explicitly).

Update `docs/architecture.md`, `docs/implementation_status.md`, `docs/verification_plan.md`, `docs/milestone_history.md`, the dedicated scalar-to-vector specification, relevant ADR index/status entries, and `README.md` only if user-facing architecture status changes. The documents must distinguish implemented facts from recommendations and deferred work.

## Acceptance criteria

The milestone is complete only when:

1. The clean entry baseline, Git revision, exact commands, pass/fail results, and measured times are recorded.
2. The broader deterministic campaign is justified by measured runtime and passes with reproducible seed/mode commands.
3. A production-readiness assessment compares both cores across every Phase 2 category.
4. One A/B/C promotion decision is made with traceable evidence, and the role of `rv32_core.sv` is defined.
5. Stable scalar interfaces, stable observability interfaces, verification-only interfaces, and unstable/deferred interfaces are explicitly listed.
6. The scalar-to-vector command and completion protocol specifies handshake, fields, backpressure, status, reset, ordering, and identity policy.
7. One-outstanding, stall, retirement, redirect, cancellation, and precise-exception semantics are decided.
8. An initial vector memory-boundary recommendation and vector-state ownership model are documented.
9. Required ADRs and all required documentation are internally consistent.
10. No vector RTL, scalar promotion/renaming, build-behavior change, commit, or push occurs.

## Stop conditions

Stop for human review rather than deciding independently if promotion requires significant RTL restructuring; scalar interfaces remain materially unstable; reference and pipeline semantics conflict; a likely correctness bug is found; external interface changes are unavoidable; retirement/exception semantics cannot be specified cleanly; or the vector memory-boundary choice has material unresolved trade-offs. Record the evidence and alternatives; do not substitute an undocumented assumption.

## Required final report

Report:

1. `MILESTONE COMPLETE` or `MILESTONE NOT COMPLETE`.
2. The scalar-core promotion decision and its evidence.
3. Exact commands, pass/fail results, commit/tree state, and measured runtime basis for the confidence campaign.
4. Stable scalar interfaces and observability contracts, plus verification-only and deferred interfaces.
5. Scalar-to-vector command/completion protocol; stall, retirement, redirect, reset, and exception semantics.
6. Memory-boundary recommendation and vector-state ownership.
7. ADRs and documentation changed, remaining risks/deferred decisions, and the next implementation milestone roadmap.
8. Confirmation that no vector RTL was implemented and no commit or push occurred.
