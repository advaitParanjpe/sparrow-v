#!/usr/bin/env bash
# Launch one bounded Codex milestone session. Tested with codex-cli 0.141.0;
# adjust CODEX_ARGS locally if the CLI changes.
set -euo pipefail

CODEX_BIN="${CODEX_BIN:-codex}"
CODEX_ARGS=(exec --sandbox workspace-write)
required=(AGENTS.md docs/architecture.md docs/current_milestone.md docs/implementation_status.md docs/verification_plan.md docs/codex_milestone_prompt.md)

if [[ ! -f Makefile || ! -d .git ]]; then
  echo "error: run this script from the Sparrow-V repository root" >&2
  exit 2
fi
for file in "${required[@]}"; do
  [[ -f "$file" ]] || { echo "error: missing workflow file: $file" >&2; exit 2; }
done
command -v "$CODEX_BIN" >/dev/null 2>&1 || { echo "error: Codex CLI not found: $CODEX_BIN" >&2; exit 127; }

title=$(sed -n '/^## Title$/,/^## /p' docs/current_milestone.md | sed '1d;$d' | head -n 1)
status=$(sed -n '/^## Status$/,/^## /p' docs/current_milestone.md | sed '1d;$d' | head -n 1)
echo "Sparrow-V milestone: ${title:-${status:-unknown}}"
if [[ -n $(git status --porcelain) ]]; then
  echo "warning: working tree already contains changes; preserve unrelated work" >&2
fi

prompt=$(<docs/codex_milestone_prompt.md)
"$CODEX_BIN" "${CODEX_ARGS[@]}" "$prompt"
