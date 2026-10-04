---
name: cmux-issue-session
description: Linear などの issue ごとに cmux の新しい workspace で Claude Code セッションを起動し、そのセッションに worktree 作業から PR 作成までを任せる。issue 同士に blocking 関係があれば、前の PR ができてから次を自動で起動して Stack PR にする。「ABC-101, 102 それぞれ worktree で PR」「cmux でセッション作成して実行」「next: <issue URL>」「ABC-103 開始」「ABC-100 の再開も指示」「sub-issues を順番に起動」「Stack PR で順番に」「親 issue の子を全部回して」のように、issue ID や issue URL を渡して作業を並行・連続で回したいとき、また途中の issue の作業を別セッションで再開させたいときに必ず使う。自分でその場の worktree を作って実装する依頼には使わない。
---

# cmux issue session

issue ごとに cmux の workspace を 1 つ作り、その中で Claude Code を起動して作業を任せる。
自分 (起動する側) は入口の役割だけを担う。worktree の作成・`cd`・依存のインストール・実装・PR 作成はすべて起動先のセッションの仕事なので、こちらで先に worktree を作ったり、実装方針を細かく決めたりしない。

## 手順

1. issue ID を決める。URL が渡されたら `/issue/ABC-104/...` の部分から ID を取り出す
   - 親 issue が 1 つだけ渡され、sub-issues を持っているなら、作業対象はその sub-issues にする (「起票した sub-issues を回して」という依頼でよくある形)
     - `get_issue` では子の一覧が取れないので、`list_issues({ parentId: "ABC-100", fields: ["id", "title", "statusType"] })` で取る
     - `statusType` が `completed` / `canceled` のものは除く。途中まで進んだ親で再実行したとき、終わった issue まで起動しないため
2. issue が 2 つ以上なら、blocking 関係を調べて起動計画を立てる (次の節)。1 つなら飛ばしてよい
3. リポジトリのメインディレクトリ (今いる場所) で、計画どおりにスクリプトを実行する

   ```bash
   # 独立した issue
   ~/.claude/skills/cmux-issue-session/scripts/launch.sh ABC-104

   # ABC-101 → ABC-102 → ABC-103 の Stack (先頭だけ起動すれば、残りは順に自動で起動される)
   ~/.claude/skills/cmux-issue-session/scripts/launch.sh --next ABC-102,ABC-103 ABC-101
   ```

   独立した issue 同士やチェーン同士は並行してよいので、1 回の Bash 呼び出しで続けて実行してよい

4. 起動を確認する。`OK workspace:NN` が返ったら画面を読み、プロンプトが化けずに届いて動き出していることを確かめる

   ```bash
   CMUX_QUIET=1 cmux read-screen --workspace workspace:NN --lines 20
   ```

5. ユーザーへ報告する。起動した workspace の番号と、Stack にした issue はその順番 (どれが後から自動で起動されるか) を伝える

## blocking 関係があるとき (Stack PR)

blocked な issue は、blocker の変更がないと実装もテストもできないことが多い。同時に起動して両方 main から切ると、後ろの issue が前の変更を知らずに作業したり、あとでコンフリクトしたりする。そこで、前の issue の PR ができてから、そのブランチの上に次の issue を積む。

### 関係を調べる

渡された issue をすべて `get_issue({ id, includeRelations: true })` で並列に取得し、`blocks` / `blockedBy` を見る。対象は**渡された issue 同士の関係だけ**。セットの外の issue (すでにマージ済みの blocker など) は無視する。

### 計画の立て方

- 関係でつながった issue のまとまりごとに、blocker が先に来る順 (トポロジカル順) で 1 本のチェーンに並べる
  - A が B と C を両方 blocks しているような枝分かれも 1 本にする (A → B → C)。PR の base は 1 つしか持てず、B と C の両方に依存する issue があると枝分かれでは表現できないため、常に一直線にしておくほうが崩れない
  - 順番が決まらない部分は、issue 番号の若い順にする
- どことも関係のない issue は、それぞれ独立して起動する
- blocking 関係があっても、変更が完全に別ルートなら Stack にせず、同時に独立して起動する
  - 別ルートとは、後ろの issue が前の issue の変更を読まずに main の上で実装もテストもでき、触るファイルも重ならない状態のこと。関係が表しているのが、マージやリリースの順番だけのこともよくある
  - 例: skill の install と、その skill を毎日更新させる schedule の追加。どちらも main から切れる
  - Stack にすると、待ち時間もレビューの順番待ちも増える。関係があるというだけで積まない
- 関係を自分で足して Stack を作らない。「揃えたほうがきれい」くらいの理由で、関係のない issue を後ろに積まない
- 関係が循環していたら起動せず、ユーザーに確認する

### チェーンの起動

先頭の issue を `--next` に残りをカンマ区切りで渡して起動する。起動先には「PR を作ったら、自分のブランチを `--base` にして次の issue を起動せよ」という指示が入るので、あとはセッションどうしが順にバトンを渡していく。こちらで完了を待ったり、監視したりする必要はない。

前の issue のブランチ名は、前のセッションが作業を始めるまで決まらない。そのため、こちらで次の起動まで済ませておくことはできず、前のセッションに起動させる形にしている。

報告のときに、次の 2 点もユーザーに伝える。

- 前のセッションが `launch.sh` を実行するときに許可を求められると、承認されるまでチェーンが止まる。動きが止まっていたら、前の workspace で承認待ちになっていないかを見てもらう
- 前の PR をマージしてもそのブランチが削除されなければ、後ろの PR の base は main に付け替わらない。そのままマージすると main ではなく前のブランチに入ってしまうので、マージ前に base を確認してもらう (起動先には PR 本文に Stack PR であることを書かせている)

## スクリプトがやっていること

- `.local/{YYYY-MM-DD}_{issue}-session/prompt.md` にプロンプトを書き出す
- 起動先には「取りかかる前に issue を In Progress にして自分をアサインする」「worktree で作業して PR を作る」「worktree のセットアップは CLAUDE.md に従って自分で行う」「`git fetch origin` してから最新の `origin/<デフォルトブランチ>` (`--base` があればそのブランチ) をベースにする」を伝える
  - すでに自分以外がアサインされている issue は、ステータスもアサインも変えずにユーザーへ確認させる。他の人の作業と重なるのを防ぐため
  - ローカルのデフォルトブランチは origin より遅れていることがよくあるため (実際に `↓16` の状態で起動したことがある)
- `--next` があれば、PR 作成後に次の issue を起動するコマンドをプロンプトに入れる。PR を作れずに止まったときは起動させない
- worktree から呼ばれても、起動先はメインディレクトリで始める
- プロンプトを `claude "$(cat <file>)"` の形で渡す
  - `cmux new-workspace --command` に日本語を直接書くと文字化けして届くため、ファイルを経由させる
- workspace の名前は issue ID にし、`--focus false` にしてユーザーの今の画面を奪わない

## 追加の文脈を渡すとき

再開の依頼や、ユーザーが issue の意図を補足したときは、その内容を起動先に確実に伝える必要がある。起動先のセッションはこの会話を知らないので、補足をしないと以前と同じ誤解のまま作業してしまうからだ。

補足を markdown ファイルに書き、第 2 引数で渡す。

```bash
~/.claude/skills/cmux-issue-session/scripts/launch.sh ABC-100 .local/2026-09-29_abc-100-resume/context.md
```

Stack の後ろの issue に補足があるときは、`.local/{YYYY-MM-DD}_{issue 小文字}-session/context.md` に書いておく。その issue が後で自動起動されるとき (`--base` 付きの起動のとき) だけ、スクリプトがいちばん新しいものを拾って渡す。普通の起動では拾わないので、補足は第 2 引数で渡す。

書く内容の目安:

- **経緯**: 以前の PR や作業の要点。Linear のコメントや添付 PR を読んで、事実だけを短くまとめる
- **本当の要望**: ユーザーの言葉をもとにした、issue の意図の言い直し
- **方針**: どこを主に直し、どこは最小限にするか。ユーザーが決めたことだけを書く

実装の答えまでは書かないこと。判断は起動先に任せ、判断の結果を報告させる。

## 起動後

- 起動先のセッションは自律して動くので、進捗を見に行く必要はない。ユーザーに聞かれたときだけ `cmux read-screen` で状況を確認する
- 起動したあとに方針が変わったら、`cmux send --workspace workspace:NN "<text>"` で追加の指示を送り、続けて `cmux send-key --workspace workspace:NN Enter` を実行する。送る前に画面を読み、入力待ちになっていることを確かめる
- workspace は閉じない。レビューが終わるまではユーザーがその中で続きの作業をする
