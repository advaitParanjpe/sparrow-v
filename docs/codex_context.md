# Codex context map

Read this file with `AGENTS.md` and `docs/current_milestone.md` before a
milestone. Read linked detail only when the milestone affects that subsystem.

## Core implementation

- `rtl/core/rv32_core.sv` — protected production/reference scalar core.
- `rtl/core/rv32_core_pipe.sv` — experimental scalar pipeline and current
  integration candidate; it is not promoted.
- `rtl/vector/rv32_vec_stub_engine.sv` — protocol-only deterministic vector
  stub. Future vector RTL belongs under `rtl/vector/`.
- `rtl/core/rv32_decoder.sv`, `rv32_immediate.sv`, `rv32_alu.sv`, and
  `rv32_regfile.sv` — shared scalar blocks.
- `rtl/common/sparrowv_scalar_pkg.sv` — shared scalar types/constants.

## Verification map

- `tb/integration/tb_scalar_core.sv` — reference-core directed test.
- `tb/integration/tb_scalar_pipe_*.sv` — focused pipeline ALU, forwarding,
  control, redirect, memory, trap, and store-retirement tests.
- `tb/integration/tb_scalar_differential.sv` — normalized reference/pipe
  differential harness, including memory timing modes and negative modes.
- `tb/integration/tb_scalar_pipe_vec_stub.sv` — command/completion stub tests.
- `tb/integration/vec_pipe_idle_ports.svh` — inactive vector port connections
  used by scalar-only pipeline tests.
- `scripts/check_repo.py` — repository and documentation checks.

## Canonical commands

| Purpose | Command |
| --- | --- |
| Repository checks | `make check` |
| Documentation checks | `make docs-check` |
| Lint | `make lint` |
| Reference scalar directed test | `make test-scalar-directed` |
| Focused pipeline tests | `make test-scalar-pipe-dev`, `test-scalar-pipe-alu`, `test-scalar-pipe-forward`, `test-scalar-pipe-control`, `test-scalar-pipe-redirect`, `test-scalar-pipe-memory`, `test-scalar-pipe-trap`, or `test-scalar-pipe-store-retire` |
| Differential tests | `make test-scalar-diff-smoke`, `test-scalar-diff-random`, `test-scalar-diff-stall`, and relevant negative/subword/store-retirement targets |
| Vector-stub focused tests | `make test-scalar-pipe-vec-stub-all` or its named subtargets |
| Scalar aggregate | `make test-scalar-regression` |
| Vector aggregate | `make test-vector-regression` |
| Full final regression | `make test-full-regression` |
| Whitespace review | `git diff --check` |

`check-scalar-throughput-experiment` is a known expected-fail historical
experiment and is not part of correctness regression.

## Protected boundaries

- Do not modify `rtl/core/rv32_core.sv` unless the milestone explicitly has
  human approval.
- Major ISA, interface, pipeline, memory, or promotion decisions require human
  review. Preserve unrelated working-tree changes.
- Codex does not commit, push, reset, or use destructive Git operations.
- Generated artifacts must remain untracked.

## Durable approved architecture

- `rv32_core_pipe` remains the experimental integration core; `rv32_core`
  remains production/reference.
- Scalar/vector issue is blocking, in-order, non-speculative, and permits one
  outstanding command.
- Vector state belongs to the vector engine. Future vector memory is separate
  from scalar `dmem` and is owned through a future top-level memory/scratchpad
  boundary.
- Current Custom-0 stub encodings are experimental integration evidence, not a
  final vector ISA.

Details: [architecture overview](architecture.md),
[scalar interface freeze](architecture/scalar_interface_freeze.md),
[scalar/vector interface](architecture/scalar_vector_interface.md),
[production readiness](architecture/scalar_production_readiness.md),
[canonical final results](final_results.md), and `docs/decisions/`.

## Lean workflow

1. A human defines a concise milestone externally and puts it in
   `docs/current_milestone.md`, then commits that definition.
2. Run `./scripts/run_milestone.sh` from a normal terminal for one primary
   Codex implementation session.
3. Review `docs/codex_milestone_result.md` and the Git diff. Request a focused
   repair only for a concrete finding; a separate read-only Codex audit is not
   the normal path.
4. Human review and a manual commit remain required.
