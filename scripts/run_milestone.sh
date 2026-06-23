#!/usr/bin/env bash
# Launch one bounded Codex implementation session. Keep CLI-version flags here.
set -euo pipefail

CODEX_BIN="${CODEX_BIN:-codex}"
CODEX_ARGS=(exec --sandbox workspace-write)
RESULT_FILE=docs/codex_milestone_result.md
required=(AGENTS.md docs/codex_context.md docs/current_milestone.md docs/codex_milestone_prompt.md)

repo_root=$(git rev-parse --show-toplevel 2>/dev/null || true)
current_dir_identity=$(stat -f '%d:%i' . 2>/dev/null || true)
repo_root_identity=$(stat -f '%d:%i' "$repo_root" 2>/dev/null || true)
if [[ -z "$repo_root" || -z "$current_dir_identity" || "$current_dir_identity" != "$repo_root_identity" || ! -f Makefile ]]; then
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

started_at=$(date -u '+%Y-%m-%dT%H:%M:%SZ')
printf 'STATUS: IN_PROGRESS\nMILESTONE: %s\nSTARTED_AT: %s\n\n' "${title:-unknown}" "$started_at" >"$RESULT_FILE"

handle_interrupt() {
  local signal=$1
  echo "warning: milestone run interrupted by $signal; leaving $RESULT_FILE intact" >&2
  exit 130
}
trap 'handle_interrupt INT' INT
trap 'handle_interrupt TERM' TERM

prompt=$(<docs/codex_milestone_prompt.md)

set +e
cd "$repo_root"
"$CODEX_BIN" "${CODEX_ARGS[@]}" "$prompt"
codex_status=$?
set -e

if [[ ! -f "$RESULT_FILE" ]]; then
  echo "error: internal launcher error: Codex result file is absent: $RESULT_FILE" >&2
  if (( codex_status != 0 )); then
    exit "$codex_status"
  fi
  exit 1
fi

status=$(sed -n 's/^STATUS: \([^[:space:]]*\).*$/\1/p' "$RESULT_FILE" | head -n 1)
case "$status" in
  COMPLETE|BLOCKED|FAILED)
    echo "Codex result file: $RESULT_FILE"
    sed -n '1,240p' "$RESULT_FILE"
    ;;
  IN_PROGRESS)
    echo "warning: Codex exited or was interrupted before finalizing $RESULT_FILE" >&2
    ;;
  *)
    echo "warning: Codex result file has missing or unrecognized status: ${status:-missing}" >&2
    ;;
esac
exit "$codex_status"
