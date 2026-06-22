# Verification plan

## Checks available now

- `make check`: repository structure/documentation validation.
- `make test-repo`: Python repository/reference tests.
- `make test-scalar-directed`: self-checking production scalar directed simulation, including delayed/backpressured memory behavior.
- `make lint`: Verilator lint over RTL.
- Focused development-pipeline targets: `test-scalar-pipe-dev`, `test-scalar-pipe-alu`, `test-scalar-pipe-forward`, `test-scalar-pipe-control`, and `test-scalar-pipe-redirect`. Their status must be established in the current tree; they are not a substitute for production regression.
- `check-scalar-throughput-experiment` (legacy alias `test-scalar-pipeline`) is a non-blocking expected-fail Phase 1.7 throughput experiment. It instantiates `rv32_core`, not `rv32_core_pipe`, and is excluded from required correctness regressions pending the documented broad pipeline-control redesign.
- Differential targets: `test-scalar-diff-smoke`, `test-scalar-diff-random` (32 seeds), `test-scalar-diff-stall` (seed 17, modes 1/2/3), `test-scalar-diff-seed SEED=<n> MODE=<n>`, `test-scalar-diff-negative`, and `test-scalar-diff-redirect-backpressure`. Subword targets are `test-scalar-diff-subword-directed`, `test-scalar-diff-subword-random` (128 immediate-mode seeds), `test-scalar-diff-subword-stall` (seed 17, modes 1/2/3), `test-scalar-diff-subword-seed SEED=<n> MODE=<n>`, and `test-scalar-diff-subword-negative`.

## Completion rule

A milestone is complete only when every applicable available command named in `docs/current_milestone.md` has passed in the current working tree, or a precise reproducible blocker is reported. Directed tests must verify architectural effects, not merely termination. Review assertions and test changes for weakening or bypasses.

## Planned verification, not currently available

Randomized instruction generation, scoreboards, coverage closure, formal/property checking, vector/sparse golden-model comparison, compiler-built bare-metal regressions, synthesis/timing/area flows, FPGA builds, and ASIC/OpenLane evaluation.

## Production-readiness campaign evidence

At clean commit `5850b69813207055f1f1c7c1eebcb5dd63bda14b`, all Phase-1 commands in `current_milestone.md` passed, including focused pipeline, differential, controlled-negative, lint, and repository checks. Immediate differential seeds 1–500 passed in 18.4 seconds using `make test-scalar-diff-seed SEED=<n> MODE=0`; the testbench has a 4,000-cycle per-run timeout. Seeds 1–16 passed in modes 1 (request backpressure), 2 (delayed response), and 3 (mixed); seed 17 passed modes 0–3. Exact rerun is `make test-scalar-diff-seed SEED=17 MODE=<0|1|2|3>`.

`make check-scalar-throughput-experiment` was run separately and failed as expected (exit 2): 52 cycles, 16 retired instructions, maximum consecutive retirements 1, and 16 gaps. It remains non-blocking and supports no throughput claim.

Human review approved the resulting architecture decisions: `rv32_core` remains the production/reference core; `rv32_core_pipe` remains experimental because its store-retirement trace contract is incomplete; and the blocking one-command scalar-to-vector protocol is an approved RTL-independent v1 specification. No vector RTL has been implemented.

## Milestone regression guidance

Use targeted checks while editing, then run the complete milestone regression, inspect the full diff, repair concrete defects, update implementation status, and report exact command output. Do not claim unavailable planned checks have run.
