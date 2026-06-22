# Awaiting milestone definition

## Objective

State the bounded outcome and why it matters.

## Baseline

State the relevant current behavior, known evidence, and constraints.

## Relevant context files

- List only architecture files, ADRs, RTL, tests, and scripts needed beyond
  `AGENTS.md` and `docs/codex_context.md`.

## In scope

- Bounded implementation, verification, or documentation work.

## Out of scope

- Explicitly name nearby work that must not be done.

## Required behavior

- Observable behavior, interfaces, ordering, error handling, and invariants.

## Focused development tests

- Smallest relevant commands and expected evidence while editing.

## Final acceptance regression

- Required feature aggregate(s), `make test-full-regression` when applicable,
  `git diff --check`, and documentation checks when documentation changes.

## Acceptance criteria

1. List measurable completion conditions.
2. Include preservation requirements for protected behavior.

## Stop conditions

- List only milestone-specific human-review conditions. Permanent safety rules
  are in `AGENTS.md`.

## Required documentation

- List only materially affected documentation.

## Result-file requirements

- Write `.codex/milestone_result.md` using the compact format below.

```markdown
STATUS: COMPLETE | BLOCKED
MILESTONE: <short title>
SUMMARY:
- <at most five concise lines>
CHANGED_FILES:
- <path> — <purpose>
FOCUSED_TESTS:
- `<command>` — PASS | FAIL | NOT RUN
FINAL_REGRESSION:
- `<command>` — PASS | FAIL | NOT RUN
MEASUREMENTS:
- <meaningful values only, or none>
BUGS_FIXED:
- <concise entry, or none>
STOP_CONDITION: none | <concise explanation and exact failed command>
DIFF_REVIEW:
- <concise findings>
REFERENCE_CORE_CHANGED: no | yes
COMMIT_CREATED: no
PUSH_PERFORMED: no
```
