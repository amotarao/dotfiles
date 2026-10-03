---
name: cmux-fork-session
description: 今の Claude Code セッションを fork し、今の cmux workspace のすぐ後ろに新しい workspace を作ってその fork を開く。引数があれば fork 先への最初の指示として送る。「このセッションを fork して」「fork して〇〇やらせて」「会話を分岐させたい」「この文脈のまま別の作業をしたい」「セッションを複製して cmux で開いて」のように、今の会話の文脈を引き継いだ別セッションを立てたいときに必ず使う。issue ごとに新規セッションで作業を任せる場合は cmux-issue-session を使う。
---

# cmux fork session

今のセッションを `claude --resume <session-id> --fork-session` で fork し、今の workspace のすぐ後ろに新しい workspace を作って開く。
fork 先は元の会話履歴を引き継いだ別の session ID になるので、元のセッションには影響しない。

## 手順

1. スクリプトを実行する。引数 (skill の ARGUMENTS) があれば、そのまま fork 先への最初の指示として渡す。言い換えたり補足したりしない

   ```bash
   ~/.claude/skills/cmux-fork-session/scripts/fork.sh "<ARGUMENTS>"
   ```

   引数が無ければ引数なしで実行する。fork 先は入力待ちで起動する

2. `OK workspace:NN` が返ったら画面を読み、fork 先が起動していること (指示を渡した場合は動き出していること) を確かめる

   ```bash
   CMUX_QUIET=1 cmux read-screen --workspace workspace:NN --lines 20
   ```

3. 開いた workspace をユーザーへ報告する

## スクリプトがやっていること

- session ID は環境変数 `CLAUDE_CODE_SESSION_ID` から取る
- `claude --resume` は起動ディレクトリに紐づく履歴しか探さないため、セッションを起動したディレクトリ (`CMUX_AGENT_LAUNCH_CWD`、無ければ今のディレクトリ) で fork 先を起動する。worktree に `cd` した後でも元のディレクトリで起動されるので、fork 先では必要に応じて worktree に移ること
- 指示は一時ファイルに書き出し、`claude ... "$(cat <file>)"` で渡す。`cmux new-workspace --command` に日本語を直接書くと文字化けするため
- workspace 名は付けない。fork は今の workspace の続きなので、`reorder-workspace --after` で今の workspace のすぐ後ろに並べる
- fork の時点で書き出し済みの会話までが引き継がれる。このスキルを呼んだターン自体は含まれないことがある
