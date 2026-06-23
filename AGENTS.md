# Sparrow-V agent operating rules

Milestones are human-defined and stored in `docs/current_milestone.md`. This
file is permanent operating policy; it does not authorize architecture or
feature work outside the active milestone.

## Safety

- Inspect the working tree, relevant implementation, tests, and interfaces
  before editing. Read nested `AGENTS.md` files when present.
- Preserve unrelated user changes and working behavior outside milestone scope.
- Do not weaken, bypass, or delete tests/assertions to obtain a pass. Do not
  fabricate results or claim checks that did not run.
- Do not commit, push, rewrite history, force-reset, discard user work, or use
  destructive Git operations.
- Stop for human review on genuine architectural ambiguity: material interface
  or ISA/pipeline decisions, meaningful alternatives, conflicting requirements,
  destructive redesign, suspect existing tests, unavailable required tools, or
  substantial scope expansion. Small local choices within approved architecture
  are permitted.

## Lean implementation workflow

1. Read `docs/codex_context.md` and `docs/current_milestone.md`.
2. Read only architecture files or ADRs explicitly named by the milestone or
   clearly required by the affected subsystem.
3. Inspect relevant implementation, tests, interfaces, and working tree.
4. Implement incrementally and use focused development checks.
5. Do not rerun complete repository regression after every edit.
6. Run the milestone-required full regression once after implementation is
   stable. If a late correction is bounded, rerun affected focused tests and
   only the necessary aggregate regression.
7. Review the final diff, update only materially affected documentation, and
   write `docs/codex_milestone_result.md`.
8. Stop only at completion or a documented human-review condition.

A partial implementation without a genuine documented stop condition is not a
valid completion point. Continue implementing, testing, and repairing until
acceptance criteria are met or a real stop condition is reached.

## Testing policy

### Development checks

Use the smallest relevant focused test, relevant lint/syntax check, and a
repository check when useful.

### Final acceptance

Run milestone-required aggregate tests and the full regression once after
stability. Run `git diff --check`; run documentation checks when documentation
changes. Record exact commands and outcomes in the result file.

## Documentation and reporting

Update only files directly affected by the milestone. Normally this includes
`docs/implementation_status.md`, `docs/milestone_history.md`, and one relevant
architecture or verification document when behavior or interfaces changed.
Update README only for public usage changes and ADRs only for architectural
decisions.

Keep the final response short; do not restate the milestone. The authoritative
compact handoff is `docs/codex_milestone_result.md`, overwritten for each
milestone. It must honestly record status, changed files, focused/final checks,
meaningful measurements, bugs, stop condition, diff findings, reference-core
status, and commit/push status.
