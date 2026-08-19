# Shared Development Workflow

複数 project で共通利用する ChatGPT / Coding Agent 開発運用ルール。
Project 固有の repository policy、task contract、仕様、work-management rule がある場合は、それらを優先する。

## 役割分担

- repository 調査、architecture 把握、actual owner の特定、変更箇所の特定、実装方針・implementation contract の決定、blocking review は ChatGPT が行う。
- Coding Agent には architecture 調査をさせない。ChatGPT が確定した contract に従い、具体的な実装・テスト・git 作業だけを依頼する。
- ChatGPT で実行できる調査・設計・管理作業を Coding Agent へ回さない。
- Coding Agent 向け prompt に「architecture を調査する」「既存実装を探して設計を決める」「別設計を探索する」等の指示を入れない。
- Git の remote/local 同期確認、working tree 確認、指定 file の確認は architecture 調査ではない。

## 新しい開発 Task の開始

過去チャットや prompt に書かれた commit hash を現在値として無条件に信用しない。

ChatGPT は implementation contract を確定する前に、GitHub 上の remote state を確認する。
最低限、必要に応じて次を確認する。

- latest remote main
- 対象 branch の remote HEAD
- 関連 PR の状態
- project が利用する work-management / spec source

実装済みの事実について、過去チャットや管理文書と repository が矛盾する場合は latest repository を authoritative とする。

## Coding Agent 開始時の Git 確認

Coding Agent 向け実装 prompt では、実装前に必ず次を実行させる。

```bash
git fetch origin --prune
```

fetch 後、prompt で指定した expected remote commit / branch と actual remote state を照合する。

- 一致する: 指定された手順で実装を開始する。
- 一致しない: stale な local state を前提に実装しない。勝手に rebase / reset / merge / redesign せず、blocking point として報告して停止する。

ローカルの `main`、既存 branch、既存 worktree が最新だと仮定しない。
Expected base は必ずしも `origin/main` とは限らず、連続 Task では前 Task の blocking-review-approved pushed commit を使ってよい。

## Git 作業環境

- 通常の開発では primary repository checkout を使う。Task ごとに worktree を作らない。
- 新しい worktree を作ってよいのは、2本以上の実装を本当に同時並行で走らせる必要があり、同じ checkout では安全に進められない場合だけとする。
- 単に別 branch / 別 base で作業したい、current Task を切り替えたい、既存 branch を保護したい、後で戻る可能性がある、という理由だけでは worktree を作らない。通常の branch switch / fetch / merge 等で対応する。
- 連続 Task、blocking fix、Manual E2E、PR merge 後の追従作業は、原則として同じ primary repository checkout を継続利用する。
- 一時的に作成した worktree は、その並行実装が終了・merge・中止して不要になった時点ですぐ片付ける。放置して次 Task へ持ち越さない。
- worktree を削除する前に `git status --short` 等で未commit変更がないことを確認する。変更が残っている場合は勝手に削除せず、blocking point として報告する。
- 不要な worktree が clean なら、次の通常作業へ進む前に `git worktree remove <path>` で削除する。
- unrelated な user changes がある作業環境を無理に再利用しない。その場合も、並列実装が不要なら新しい worktree を既定解にせず、まず安全な branch / checkout の整理方法を選ぶ。
- Task ごとに main への merge や PR 作成を機械的に要求しない。current track / current plan に従う。
- unrelated な user changes、branch、worktree を勝手に削除・上書き・reset しない。

## Coding Agent 向け prompt

- current Task の実行に必要な情報だけを書く。
- 原則として repository、expected remote state、branch/base、変更対象、具体的な変更内容、必要な test、commit/push、blocking 条件を渡す。
- 装飾目的の区切り線を使わない。`====`、`----`、大量の罫線などを入れない。
- 見出しは可読性に必要な最小限だけ使う。
- 同じ制約を別表現で繰り返さない。
- 実装に不要な背景説明や確定済みの設計経緯を長く再掲しない。
- shared rule や skill にある一般論を、current Task で必要でない限り重複して説明しない。
- Git 安全条件、blocking 条件、current Task 固有の acceptance は省略しない。
- 敬語を使わず、短く直接的な命令文で書く。

### prompt提示とwork-management Issue作成の順序

新規開発Taskでwork-management Issueの新規作成が必要な場合も、Issue作成をCoding Agent開始の前提にしない。

1. 必要なremote state確認、既存Issue / Spec検索、repository調査を行い、implementation contractを確定する。
2. 新規Issueを作る前にbranch名を決め、Coding Agent向けpromptを完成させてユーザーへ提示する。
3. branch名は、まだ存在しないIssue identifierやwork-management systemが自動生成するbranch名に依存させない。
4. ユーザーが選んだCoding Agentで実装を開始できる状態を先に作る。特定のCoding Agent製品を前提にしない。
5. Coding Agentが実装している間に、ChatGPTが必要なIssue作成、description記入、Project紐付け、status更新などの管理作業を行う。

既存Issue / Specの読み取り自体がcontract確定に必要な場合は先に行う。後回しにするのは、contract確定後の新規Issue作成やstatus更新など、Coding Agent開始を待たせる必要のない管理操作である。

既存Issueがすでに存在するTaskではそのIssueを再利用するが、管理更新だけを理由にprompt提示を遅らせない。

## Task execution

- ChatGPT が repository を調査し、architecture 把握・actual owner 特定・変更箇所特定・implementation contract 確定を行う。
- Coding Agent は確定済み contract に従い、実装・テスト・git 作業を行う。
- current Task の scope 外の cleanup や future work を先取りしない。
- 実装後は必要な blocking review と verification を行う。
- repository file を変更した Task は、指定 branch へ意図した変更だけを commit し、`git push origin <branch>` を行う。local-only commit は完了扱いにしない。
- review は pushed GitHub state に対して行う。
- blocking fix は current Task の plan に反しない限り同じ Task branch で commit / push して再 review する。
- blocking-review PASS 後に PR / merge するか、review 済み commit から次 Task を開始するかは current track の plan に従う。

## 引き継ぎ

ユーザーが「引き継ぎを書いて」と依頼した場合は、少なくとも次を含める。

- ChatGPT / Coding Agent の役割分担
- remote state 確認
- worktree は真に同時並行の複数実装が必要な場合だけ使い、不要になったら即削除する原則
- commit / push
- prompt 簡潔化ルール
- current project 固有の work-management / source-of-truth rule
