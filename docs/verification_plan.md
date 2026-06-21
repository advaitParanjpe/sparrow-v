# Verification plan

## Checks available now

- `make check`: repository structure/documentation validation.
- `make test-repo`: Python repository/reference tests.
- `make test-scalar-directed`: self-checking production scalar directed simulation, including delayed/backpressured memory behavior.
- `make lint`: Verilator lint over RTL.
- Focused development-pipeline targets: `test-scalar-pipe-dev`, `test-scalar-pipe-alu`, `test-scalar-pipe-forward`, `test-scalar-pipe-control`, and `test-scalar-pipe-redirect`. Their status must be established in the current tree; they are not a substitute for production regression.
- Differential targets: `test-scalar-diff-smoke`, `test-scalar-diff-random` (32 seeds), `test-scalar-diff-stall` (seed 17, modes 1/2/3), `test-scalar-diff-seed SEED=<n> MODE=<n>`, `test-scalar-diff-negative`, and `test-scalar-diff-redirect-backpressure`.

## Completion rule

A milestone is complete only when every applicable available command named in `docs/current_milestone.md` has passed in the current working tree, or a precise reproducible blocker is reported. Directed tests must verify architectural effects, not merely termination. Review assertions and test changes for weakening or bypasses.

## Planned verification, not currently available

Randomized instruction generation, scoreboards, coverage closure, formal/property checking, vector/sparse golden-model comparison, compiler-built bare-metal regressions, synthesis/timing/area flows, FPGA builds, and ASIC/OpenLane evaluation.

## Milestone regression guidance

Use targeted checks while editing, then run the complete milestone regression, inspect the full diff, repair concrete defects, update implementation status, and report exact command output. Do not claim unavailable planned checks have run.
