#!/usr/bin/env bash
# Launch a Claude Code session in a new cmux workspace to work on an issue in a worktree.
#
# Usage: launch.sh [--base BRANCH --after ISSUE] [--next ISSUE[,ISSUE...]] <ISSUE_ID> [EXTRA_CONTEXT_FILE]
#   ISSUE_ID            e.g. ABC-105
#   EXTRA_CONTEXT_FILE  optional markdown appended to the prompt (background, clarified intent, ...)
#                       If omitted with --base, the latest .local/*_<issue>-session/context.md is used when present.
#   --base BRANCH       stack on BRANCH instead of the default branch (worktree base and PR base)
#   --after ISSUE       the issue whose PR is BRANCH (only used in the prompt text)
#   --next ISSUES       issues to launch in order after this one opens its PR, each stacked on the previous
#
# Can be run from the main repository directory or from any of its worktrees;
# the session always starts in the main repository directory.
set -euo pipefail

usage="usage: launch.sh [--base BRANCH --after ISSUE] [--next ISSUE[,ISSUE...]] <ISSUE_ID> [EXTRA_CONTEXT_FILE]"
base=""
after=""
next=""
while [[ $# -gt 0 ]]; do
  case "$1" in
    --base) base="${2:?$usage}"; shift 2 ;;
    --after) after="${2:?$usage}"; shift 2 ;;
    --next) next="${2:?$usage}"; shift 2 ;;
    -*) echo "$usage" >&2; exit 1 ;;
    *) break ;;
  esac
done

issue="${1:?$usage}"
extra="${2:-}"
lower="$(printf %s "$issue" | tr "[:upper:]" "[:lower:]")"

# The main repository, even when called from a worktree (the previous session in a stack runs in one).
repo="$(dirname "$(git rev-parse --path-format=absolute --git-common-dir)")"
dir="$repo/.local/$(date +%Y-%m-%d)_${lower}-session"
mkdir -p "$dir"
prompt="$dir/prompt.md"

if [[ -z "$extra" && -n "$base" ]]; then
  # A stacked issue is launched later by the previous session, so pick up context written in advance
  # (possibly on an earlier date). Plain launches don't, to avoid attaching stale resume notes.
  extra="$(ls -t "$repo"/.local/*_"${lower}"-session/context.md 2>/dev/null | head -n 1 || true)"
fi

if [[ -n "$base" ]]; then
  base_line="worktree を作る前に \`git fetch origin\` し、最新の \`origin/${base}\` をベースにすること。これは ${after:-前の issue} の PR に積む Stack PR なので、PR の base も \`${base}\` にし、PR 本文の冒頭に「${after:-前の issue} の PR (#番号) に積んだ Stack PR。先にそちらをマージする」と書くこと"
else
  base_line="worktree を作る前に \`git fetch origin\` し、最新の \`origin/<デフォルトブランチ>\` をベースにすること (ローカルのデフォルトブランチは古い可能性がある)"
fi

cat > "$prompt" <<EOF
Linear の ${issue} を worktree で作業して PR を作成して。

- 取りかかる前に issue のステータスを In Progress にし、自分をアサインすること
  - すでに自分以外がアサインされている場合は、ステータスもアサインも変えずに、進めてよいかユーザーに確認すること
- worktree のセットアップ (作成・cd・依存のインストール) は CLAUDE.md の手順に従って自分で行うこと
- ${base_line}
EOF

if [[ -n "$next" ]]; then
  first="${next%%,*}"
  rest=""
  [[ "$next" == *,* ]] && rest="${next#*,}"
  cmd="~/.claude/skills/cmux-issue-session/scripts/launch.sh --base <この作業のブランチ名> --after ${issue}"
  [[ -n "$rest" ]] && cmd="$cmd --next ${rest}"
  cmd="$cmd ${first}"
  cat >> "$prompt" <<EOF

## PR を作成したら

${first} は ${issue} に blocked されていて、この PR の上に Stack PR として積む。
PR を作成してブランチを push し終えたら、次のコマンドで ${first} のセッションを起動すること。

\`\`\`bash
${cmd}
\`\`\`

- \`OK workspace:NN\` が返ったら起動した workspace 番号をユーザーに報告して、この作業を終える
- PR を作れずに止まった場合は起動しないこと。土台のない Stack PR ができてしまうため
EOF
fi

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
