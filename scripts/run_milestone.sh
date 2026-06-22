#!/usr/bin/env bash
# Launch one bounded Codex implementation session. Keep CLI-version flags here.
set -euo pipefail

CODEX_BIN="${CODEX_BIN:-codex}"
CODEX_ARGS=(exec --sandbox workspace-write)
RESULT_FILE=.codex/milestone_result.md
required=(AGENTS.md docs/codex_context.md docs/current_milestone.md docs/codex_milestone_prompt.md)

repo_root=$(git rev-parse --show-toplevel 2>/dev/null || true)
if [[ -z "$repo_root" || "$PWD" != "$repo_root" || ! -f Makefile ]]; then
  echo "error: run this script from the Sparrow-V repository root" >&2
  exit 2
fi
for file in "${required[@]}"; do
  [[ -f "$file" ]] || { echo "error: missing workflow file: $file" >&2; exit 2; }
done
command -v "$CODEX_BIN" >/dev/null 2>&1 || { echo "error: Codex CLI not found: $CODEX_BIN" >&2; exit 127; }

title=$(sed -n '1s/^# //p' docs/current_milestone.md | head -n 1)
echo "Sparrow-V milestone: ${title:-unknown}"
if [[ -n $(git status --porcelain) ]]; then
  echo "warning: working tree already contains changes; preserve unrelated work" >&2
fi

mkdir -p .codex
rm -f "$RESULT_FILE"
prompt=$(<docs/codex_milestone_prompt.md)

set +e
"$CODEX_BIN" "${CODEX_ARGS[@]}" "$prompt"
codex_status=$?
set -e

if [[ -f "$RESULT_FILE" ]]; then
  echo "Codex result file: $RESULT_FILE"
  sed -n '1,240p' "$RESULT_FILE"
else
  echo "warning: Codex produced no $RESULT_FILE; inspect its terminal output and Git diff" >&2
fi
exit "$codex_status"
