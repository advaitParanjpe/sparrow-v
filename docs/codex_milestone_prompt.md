# Codex milestone execution prompt

Read `AGENTS.md`, `docs/codex_context.md`, and `docs/current_milestone.md`.
Implement the milestone end to end. Use focused tests while developing, run the
final required regression once after stability, review the diff, update only
required documentation, and continuously update the existing
`.codex/milestone_result.md`. Record each focused test command and outcome as
it finishes, and preserve useful partial findings if the run cannot complete.
Use `STATUS: COMPLETE` only after every acceptance criterion and final check
passes. Use `STATUS: BLOCKED` only for a genuine human-review stop condition;
use `STATUS: FAILED` when required checks fail and the run cannot repair them.
Never exit normally while the result status is `IN_PROGRESS`. Continue until
complete or a documented stop condition. Do not commit or push.
