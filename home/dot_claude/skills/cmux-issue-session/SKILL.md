---
name: cmux-issue-session
description: Linear などの issue ごとに cmux の新しい workspace で Claude Code セッションを起動し、そのセッションに worktree 作業から PR 作成までを任せる。「ABC-101, 102 それぞれ worktree で PR」「cmux でセッション作成して実行」「next: <issue URL>」「ABC-103 開始」「ABC-100 の再開も指示」のように、issue ID や issue URL を渡して作業を並行で回したいとき、また途中の issue の作業を別セッションで再開させたいときに必ず使う。自分でその場の worktree を作って実装する依頼には使わない。
---

# cmux issue session

issue ごとに cmux の workspace を 1 つ作り、その中で Claude Code を起動して作業を任せる。
自分 (起動する側) は入口の役割だけを担う。worktree の作成・`cd`・依存のインストール・実装・PR 作成はすべて起動先のセッションの仕事なので、こちらで先に worktree を作ったり、実装方針を細かく決めたりしない。

## 手順

1. issue ID を決める。URL が渡されたら `/issue/ABC-104/...` の部分から ID を取り出す
2. リポジトリのメインディレクトリ (今いる場所) で、issue ごとにスクリプトを実行する

   ```bash
   ~/.claude/skills/cmux-issue-session/scripts/launch.sh ABC-104
   ```

   複数の issue は 1 つずつ順に実行すればよい。どれも独立しているので、1 回の Bash 呼び出しで for ループにしてもよい

3. 起動を確認する。`OK workspace:NN` が返ったら画面を読み、プロンプトが化けずに届いて動き出していることを確かめる

   ```bash
   CMUX_QUIET=1 cmux read-screen --workspace workspace:NN --lines 20
   ```

4. 起動した workspace の番号を、issue ごとにユーザーへ報告する

## スクリプトがやっていること

- `.local/{YYYY-MM-DD}_{issue}-session/prompt.md` にプロンプトを書き出す
- 起動先には「取りかかる前に issue を In Progress にして自分をアサインする」「worktree で作業して PR を作る」「worktree のセットアップは CLAUDE.md に従って自分で行う」「`git fetch origin` してから最新の `origin/<デフォルトブランチ>` をベースにする」を伝える
  - すでに自分以外がアサインされている issue は、ステータスもアサインも変えずにユーザーへ確認させる。他の人の作業と重なるのを防ぐため
  - ローカルのデフォルトブランチは origin より遅れていることがよくあるため (実際に `↓16` の状態で起動したことがある)
- プロンプトを `claude "$(cat <file>)"` の形で渡す
  - `cmux new-workspace --command` に日本語を直接書くと文字化けして届くため、ファイルを経由させる
- workspace の名前は issue ID にし、`--focus false` にしてユーザーの今の画面を奪わない

## 追加の文脈を渡すとき

再開の依頼や、ユーザーが issue の意図を補足したときは、その内容を起動先に確実に伝える必要がある。起動先のセッションはこの会話を知らないので、補足をしないと以前と同じ誤解のまま作業してしまうからだ。

補足を markdown ファイルに書き、第 2 引数で渡す。

```bash
~/.claude/skills/cmux-issue-session/scripts/launch.sh ABC-100 .local/2026-09-29_abc-100-resume/context.md
```

書く内容の目安:

- **経緯**: 以前の PR や作業の要点。Linear のコメントや添付 PR を読んで、事実だけを短くまとめる
- **本当の要望**: ユーザーの言葉をもとにした、issue の意図の言い直し
- **方針**: どこを主に直し、どこは最小限にするか。ユーザーが決めたことだけを書く

実装の答えまでは書かないこと。判断は起動先に任せ、判断の結果を報告させる。

## 起動後

- 起動先のセッションは自律して動くので、進捗を見に行く必要はない。ユーザーに聞かれたときだけ `cmux read-screen` で状況を確認する
- 起動したあとに方針が変わったら、`cmux send --workspace workspace:NN "<text>"` で追加の指示を送り、続けて `cmux send-key --workspace workspace:NN Enter` を実行する。送る前に画面を読み、入力待ちになっていることを確かめる
- workspace は閉じない。レビューが終わるまではユーザーがその中で続きの作業をする
