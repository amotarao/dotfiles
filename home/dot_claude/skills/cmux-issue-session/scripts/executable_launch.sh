#!/usr/bin/env bash
# Launch a Claude Code session in a new cmux workspace to work on an issue in a worktree.
#
# Usage: launch.sh <ISSUE_ID> [EXTRA_CONTEXT_FILE]
#   ISSUE_ID            e.g. ABC-105
#   EXTRA_CONTEXT_FILE  optional markdown appended to the prompt (background, clarified intent, ...)
#
# Run from the main repository directory; the session starts in the same directory.
set -euo pipefail

issue="${1:?usage: launch.sh <ISSUE_ID> [EXTRA_CONTEXT_FILE]}"
extra="${2:-}"

repo="$(git rev-parse --show-toplevel)"
dir="$repo/.local/$(date +%Y-%m-%d)_$(printf %s "$issue" | tr "[:upper:]" "[:lower:]")-session"
mkdir -p "$dir"
prompt="$dir/prompt.md"

cat > "$prompt" <<EOF
Linear の ${issue} を worktree で作業して PR を作成して。

- 取りかかる前に issue のステータスを In Progress にし、自分をアサインすること
  - すでに自分以外がアサインされている場合は、ステータスもアサインも変えずに、進めてよいかユーザーに確認すること
- worktree のセットアップ (作成・cd・依存のインストール) は CLAUDE.md の手順に従って自分で行うこと
- worktree を作る前に \`git fetch origin\` し、最新の \`origin/<デフォルトブランチ>\` をベースにすること (ローカルのデフォルトブランチは古い可能性がある)
EOF

if [[ -n "$extra" ]]; then
  printf '\n' >> "$prompt"
  cat "$extra" >> "$prompt"
fi

# Pass the prompt via a file: non-ASCII text given directly to --command gets garbled.
rel="${prompt#"$repo"/}"
CMUX_QUIET=1 cmux new-workspace \
  --name "$issue" \
  --cwd "$repo" \
  --focus false \
  --command "claude \"\$(cat '$rel')\""
