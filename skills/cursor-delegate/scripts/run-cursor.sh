#!/usr/bin/env bash
# Runs one headless Cursor Agent round for a brief and stores the outputs next to it.
#
# usage: run-cursor.sh --workspace <repo> --brief <task_dir/brief-N.md> [--model <id>] [--resume <session_id>]
#
# Outputs in the brief's folder:
#   brief-N.result.json   raw cursor-agent JSON
#   brief-N.handoff.md    the final "## HANDOFF" section written by the executor
#   brief-N.stderr.log    stderr of the run
#   session_id            last session id (pass to --resume for fix rounds)
#   base                  commit the task started from (written on the first round only)
set -euo pipefail

usage() {
  echo "usage: run-cursor.sh --workspace <repo> --brief <file> [--model <id>] [--resume <session_id>]" >&2
  exit 2
}

model="${CURSOR_DELEGATE_MODEL:-grok-4.7-high}"
workspace=""
brief=""
resume=""
while [[ $# -gt 0 ]]; do
  case "$1" in
    --workspace) workspace="${2:-}"; shift 2 ;;
    --brief) brief="${2:-}"; shift 2 ;;
    --model) model="${2:-}"; shift 2 ;;
    --resume) resume="${2:-}"; shift 2 ;;
    *) usage ;;
  esac
done
[[ -n "$workspace" && -n "$brief" && -f "$brief" ]] || usage
command -v cursor-agent >/dev/null || { echo "cursor-agent not found in PATH" >&2; exit 3; }
command -v jq >/dev/null || { echo "jq not found in PATH" >&2; exit 3; }

workspace="$(cd "$workspace" && pwd)"
task_dir="$(cd "$(dirname "$brief")" && pwd)"
brief="$task_dir/$(basename "$brief")"
round="$(basename "$brief" .md)"
result="$task_dir/$round.result.json"
handoff="$task_dir/$round.handoff.md"
stderr_log="$task_dir/$round.stderr.log"

is_git=false
if git -C "$workspace" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  is_git=true
  # Keep the task folder out of git without touching the committed .gitignore.
  case "$task_dir/" in
    "$workspace"/*)
      relative="${task_dir#"$workspace"/}"
      pattern="/${relative%%/*}/"
      if ! git -C "$workspace" check-ignore -q "$relative/x" 2>/dev/null; then
        exclude="$(git -C "$workspace" rev-parse --git-path info/exclude)"
        [[ "$exclude" = /* ]] || exclude="$workspace/$exclude"
        mkdir -p "$(dirname "$exclude")"
        grep -qxF "$pattern" "$exclude" 2>/dev/null || echo "$pattern" >>"$exclude"
      fi
      ;;
  esac
  [[ -f "$task_dir/base" ]] || git -C "$workspace" rev-parse HEAD >"$task_dir/base"
fi

args=(-p --output-format json --force --trust --model "$model" --workspace "$workspace")
[[ -n "$resume" ]] && args+=(--resume "$resume")

echo "cursor-delegate: round=$round model=$model workspace=$workspace${resume:+ resume=$resume}"
set +e
cursor-agent "${args[@]}" "$(cat "$brief")" >"$result" 2>"$stderr_log"
exit_code=$?
set -e

if ! jq -e . "$result" >/dev/null 2>&1; then
  echo "cursor-delegate: run failed (exit $exit_code), output is not JSON"
  echo "--- stdout (tail)"; tail -n 20 "$result"
  echo "--- stderr (tail)"; tail -n 20 "$stderr_log"
  exit 1
fi

session_id="$(jq -r '.session_id // empty' "$result")"
[[ -n "$session_id" ]] && echo "$session_id" >"$task_dir/session_id"
jq -r '.result // "" | if contains("## HANDOFF") then "## HANDOFF" + (split("## HANDOFF") | last) else "## HANDOFF\n(missing: the executor did not write a handoff section)" end' \
  "$result" >"$handoff"

echo "exit=$exit_code is_error=$(jq -r '.is_error' "$result") session_id=$session_id"
echo "duration=$(( $(jq -r '.duration_ms // 0' "$result") / 1000 ))s usage=$(jq -c '.usage // {}' "$result")"
echo
head -n 120 "$handoff"

if $is_git; then
  echo
  echo "--- git status --short"
  git -C "$workspace" status --short | head -n 60
  echo "--- git diff --stat $(cut -c1-10 "$task_dir/base")"
  git -C "$workspace" diff --stat "$(cat "$task_dir/base")" | tail -n 40
fi
[[ "$(jq -r '.is_error' "$result")" == "false" ]]
