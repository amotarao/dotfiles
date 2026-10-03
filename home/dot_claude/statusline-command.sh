#!/bin/bash

# 標準入力からJSONデータを読み取る
input=$(cat)

# 現在の作業ディレクトリを取得
current_dir=$(echo "$input" | jq -r '.workspace.current_dir')
dir_name=$(basename "$current_dir")

# gitブランチ名を取得
branch=$(cd "$current_dir" 2>/dev/null && git branch --show-current 2>/dev/null || echo "")

# push/pull差分を取得
ahead_behind=""
if [ -n "$branch" ]; then
    # リモートブランチの存在確認とahead/behind情報を取得
    remote_branch=$(cd "$current_dir" 2>/dev/null && git rev-parse --abbrev-ref --symbolic-full-name @{u} 2>/dev/null || echo "")

    if [ -n "$remote_branch" ]; then
        # ahead/behindの数を取得
        counts=$(cd "$current_dir" 2>/dev/null && git rev-list --left-right --count "$remote_branch"...HEAD 2>/dev/null || echo "")

        if [ -n "$counts" ]; then
            behind=$(echo "$counts" | awk '{print $1}')
            ahead=$(echo "$counts" | awk '{print $2}')

            if [ "$ahead" -gt 0 ] && [ "$behind" -gt 0 ]; then
                ahead_behind=" \033[35m↑${ahead}↓${behind}\033[0m"
            elif [ "$ahead" -gt 0 ]; then
                ahead_behind=" \033[35m↑${ahead}\033[0m"
            elif [ "$behind" -gt 0 ]; then
                ahead_behind=" \033[35m↓${behind}\033[0m"
            fi
        fi
    fi
fi

# worktreeかどうかを判別し、プロジェクト名を取得
is_worktree=""
project_name="$dir_name"

if [ -f "$current_dir/.git" ]; then
    # .gitがファイルの場合はworktree
    # .gitファイルからメインリポジトリのパスを取得
    git_content=$(cat "$current_dir/.git")
    main_repo_path=$(echo "$git_content" | sed -n 's/^gitdir: \(.*\)\/\.git\/worktrees\/.*/\1/p')

    if [ -n "$main_repo_path" ]; then
        project_name=$(basename "$main_repo_path")
        is_worktree=" \033[33m[worktree]\033[0m"
    fi
elif [ -d "$current_dir/.git" ]; then
    # .gitがディレクトリの場合は通常のリポジトリ
    # gitリポジトリのルートディレクトリ名を取得
    repo_root=$(cd "$current_dir" 2>/dev/null && git rev-parse --show-toplevel 2>/dev/null || echo "")
    if [ -n "$repo_root" ]; then
        project_name=$(basename "$repo_root")
    fi
fi

# context 利用率を取得 (used_percentage が無い場合は current_usage から計算)
context_usage=""
ctx_pct=$(echo "$input" | jq -r '
    .context_window as $cw
    | if $cw.used_percentage != null then $cw.used_percentage
      elif $cw.current_usage != null and ($cw.context_window_size // 0) > 0 then
        (($cw.current_usage.input_tokens // 0)
         + ($cw.current_usage.cache_creation_input_tokens // 0)
         + ($cw.current_usage.cache_read_input_tokens // 0)) * 100 / $cw.context_window_size
      else empty end
    | floor' 2>/dev/null)

if [ -n "$ctx_pct" ]; then
    # 利用率に応じて色を変える (〜49%: 緑, 50〜79%: 黄, 80%〜: 赤)
    if [ "$ctx_pct" -ge 80 ]; then
        ctx_color="\033[31m"
    elif [ "$ctx_pct" -ge 50 ]; then
        ctx_color="\033[33m"
    else
        ctx_color="\033[32m"
    fi
    context_usage=" \033[90mContext:\033[0m ${ctx_color}${ctx_pct}%\033[0m"
fi

# 出力を構築
if [ -n "$is_worktree" ]; then
    # worktreeの場合: プロジェクト名 [worktree] (ブランチ名) ↑↓
    if [ -n "$branch" ]; then
        printf '\033[36m%s\033[0m%b \033[90m(\033[0m\033[32m%s\033[0m\033[90m)\033[0m%b%b' "$project_name" "$is_worktree" "$branch" "$ahead_behind" "$context_usage"
    else
        printf '\033[36m%s\033[0m%b%b' "$project_name" "$is_worktree" "$context_usage"
    fi
elif [ -n "$branch" ]; then
    # 通常のリポジトリでブランチがある場合: プロジェクト名 (ブランチ名) ↑↓
    printf '\033[36m%s\033[0m \033[90m(\033[0m\033[32m%s\033[0m\033[90m)\033[0m%b%b' "$project_name" "$branch" "$ahead_behind" "$context_usage"
else
    # ブランチがない場合: プロジェクト名のみ
    printf '\033[36m%s\033[0m%b' "$project_name" "$context_usage"
fi
