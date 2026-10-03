#!/usr/bin/env bash
# Fork the current Claude Code session into a new cmux workspace placed right after
# the current one, optionally sending a first prompt to the fork.
#
# Usage: fork.sh [PROMPT]
set -euo pipefail
export CMUX_QUIET=1

session="${CLAUDE_CODE_SESSION_ID:?CLAUDE_CODE_SESSION_ID is not set (run this from inside Claude Code)}"
# `claude --resume` only finds sessions of the directory it was started in.
cwd="${CMUX_AGENT_LAUNCH_CWD:-$PWD}"
prompt="${1:-}"

command="claude --resume '$session' --fork-session"
if [[ -n "$prompt" ]]; then
  # Pass the prompt via a file: non-ASCII text given directly to --command gets garbled.
  file="$(mktemp "${TMPDIR:-/tmp}/cmux-fork-prompt.XXXXXX")"
  printf '%s\n' "$prompt" > "$file"
  command+=" \"\$(cat '$file')\""
fi

workspace="$(cmux new-workspace --cwd "$cwd" --focus true --command "$command" | awk '/^OK /{print $2}')"
[[ -n "$workspace" ]] || { echo "failed to create a workspace" >&2; exit 1; }

if [[ -n "${CMUX_WORKSPACE_ID:-}" ]]; then
  # A just-created workspace may not be in the window's list yet; reordering it then
  # silently leaves it at the end of the list.
  for _ in {1..20}; do
    cmux workspace list | grep -q "$workspace " && break
    sleep 0.1
  done
  cmux reorder-workspace --workspace "$workspace" --after "$CMUX_WORKSPACE_ID" >/dev/null || true
fi

echo "OK $workspace"
