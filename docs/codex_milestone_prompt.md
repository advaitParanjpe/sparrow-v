# Codex milestone execution prompt

Work only on the approved milestone in `docs/current_milestone.md`. First read `AGENTS.md`, `docs/architecture.md`, `docs/current_milestone.md`, `docs/implementation_status.md`, and `docs/verification_plan.md`, then audit the relevant implementation and working tree.

Follow this sequence: audit → concrete plan → incremental implementation → targeted verification → full milestone regression → full diff review → repair concrete issues → documentation/status update → final report. Preserve working behavior outside milestone scope. Do not weaken tests/assertions, make unsupported claims, modify unrelated dirty files, commit, push, rewrite history, reset, or discard user work.

Stop and request human review for material requirement conflicts, major interface/ISA/pipeline decisions, meaningful architectural trade-offs, destructive rewrites, suspect existing tests, unavailable required tools, or substantial scope expansion.

Report changed files, decisions, exact commands and results, measured evidence only, known limitations, remaining risks, human-review items, and confirmation that no commit or push was performed. Continue until acceptance criteria are met or a documented stop condition occurs; do not use unbounded retries.
