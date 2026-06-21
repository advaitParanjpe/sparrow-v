# Sparrow-V agent operating rules

Sparrow-V milestones are defined by a human and architecture/review assistant. This repository file bounds implementation agents; it does not authorize a new architecture or feature by itself.

## Before changing code

1. Read this file and any nested `AGENTS.md` files.
2. Read `docs/architecture.md`, `docs/current_milestone.md`, `docs/implementation_status.md`, and `docs/verification_plan.md`.
3. Audit the relevant RTL, tests, interfaces, and current working tree. Treat repository contents and directly run commands as the source of truth.
4. Keep the change inside the approved milestone. Preserve working behavior unless the milestone explicitly changes it.

Prefer small understandable changes. Do not weaken, bypass, or delete tests/assertions to obtain a pass. Do not alter unrelated dirty files. Do not commit, push, rewrite history, force-reset, or discard user work.

## Required milestone workflow

Audit → concrete plan → incremental implementation → targeted checks → complete milestone regression → full diff review → repair concrete issues → update `docs/implementation_status.md` → grounded final report.

The final report must list work completed, files changed, architecture/implementation decisions, exact commands and pass/fail results, measured results only, limitations, risks, human-review items, and confirmation that no commit or push occurred.

## Stop for human review

Stop rather than deciding independently when requirements materially conflict, a major interface or pipeline/ISA decision is needed, several options have meaningful trade-offs, a destructive rewrite appears necessary, existing tests seem incorrect, documented architecture conflicts with the request, necessary tools are unavailable, measurements undermine a core assumption, or scope must expand substantially.

Small local choices inside an approved architecture are permitted. Major direction remains human-owned.
