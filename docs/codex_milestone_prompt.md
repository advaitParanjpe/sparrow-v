# Codex milestone execution prompt

Read `AGENTS.md`, `docs/codex_context.md`, and `docs/current_milestone.md`.
Implement the milestone end to end. Use focused tests while developing, run the
final required regression once after stability, review the diff, update only
required documentation, and continuously update
`docs/codex_milestone_result.md`. Record each focused test command and outcome
as it finishes, and preserve useful partial findings if the run cannot
complete. Use `STATUS: COMPLETE` only after every acceptance criterion and
final check passes. Use `STATUS: FAILED` when required criteria or checks
remain incomplete. Use `STATUS: BLOCKED` only for a genuine human-review stop
condition. Never exit normally while the result status is `IN_PROGRESS`.
Continue until complete or a documented stop condition. The result must include
changed files, commands, results, remaining issues, commit safety, and explicit
confirmation that no commit or push occurred. Do not commit or push.
