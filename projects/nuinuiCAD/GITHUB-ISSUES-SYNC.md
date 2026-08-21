# nuinuiCAD GitHub Issues public mirror rule

## Purpose

LinearをnuinuiCADの正式なWork管理・仕様管理のsource of truthとして維持しつつ、`sayosomi/nuinuiCAD` のGitHub Issuesを公開mirrorとして使う。

GitHub Issuesへ公開することを前提とするWork informationは、Linear側だけに残さない。

## Authority

- Work / specificationのauthorityはLinear。
- GitHub Issuesはpublic mirror / public discussion surface。
- legacy mirrorについてGitHub側の編集をLinearへ逆同期しない。
- repository implementation factsは従来どおりlatest repositoryがauthority。

## Issue classes

### Official two-way synced issues

Linear ↔ GitHub IssuesのTwo-way syncが有効な状態で作成され、Linear上に対応GitHub Issue attachmentとGitHub sync threadを持つIssue。

通常のfield syncはLinear公式integrationへ任せる。

- title
- description
- status / open-close state
- supported labels / assignee

#### Comments

公開する進捗・結果・判断のcommentは、Linear issue上の **GitHub sync threadへのreply** として投稿する。

GitHub sync threadは、Linearが生成する「This comment thread is synced to a corresponding GitHub issue ...」というthread。

- public commentを通常のLinear top-level discussionとして新規作成しない。
- top-level Linear-only discussionは、明示的にinternal / non-publicとして残す場合だけ使う。
- public commentを投稿する前にGitHub sync threadを確認する。
- official synced issueのはずなのにsync threadが無い場合はintegration faultとして扱い、private-only commentを代替として黙って作らない。

### Legacy manual mirrors

Two-way syncを有効化する前に存在していたIssueはmanual backfillでGitHubへ公開したため、公式sync pairではない。

Current mapping:

- `SAY-9`〜`SAY-38` → GitHub `#186`〜`#215` (`GitHub issue = SAY number + 177`)
- `SAY-40`〜`SAY-74` → GitHub `#216`〜`#250` (`GitHub issue = SAY number + 176`)
- `SAY-39` は移行試験用として削除済みでmirror対象外

Legacy mirrorは **Linear → GitHub one-way** とする。

#### Fields

Linear側でlegacy Issueを変更したcheckpointでは、対応GitHub Issueを同じcheckpointで更新する。

最低限mirrorする:

- title
- current description
- current status
- priority
- Contract / Manual E2E / type labels
- project / dependency / related metadataのうちpublic issue理解に必要なもの

State mapping:

- Linear `Done` → GitHub `closed / completed`
- Linear `Canceled` / `Duplicate` → GitHub `closed / not planned`
- Linear `Backlog` / `Todo` / `In Progress` / `In Review` → GitHub `open`

GitHub body末尾に現在のLinear metadataと元Issue URLを持たせる。

自動reconciliation用にGitHub bodyへ次のhidden markerを持たせてよい。

```html
<!-- linear-mirror-updated-at:2026-08-21T00:00:00+09:00 -->
```

#### Comments

Legacy Issueには公式GitHub sync threadが無い。

公開するLinear commentを作成する場合は、同じ内容を対応GitHub Issueにも投稿する。

GitHub側のmirror commentにはdeduplication用に次のhidden markerを付けてよい。

```html
<!-- linear-comment-id:<Linear comment UUID> -->
```

既存commentを再確認するときは、このmarkerで二重投稿を防ぐ。

### Accidental official-sync shadow for a legacy mirror

Two-way syncが有効な状態でlegacy GitHub mirrorを更新した結果、公式integrationがそのGitHub Issueを新しいLinear Issueとして取り込み、元のcanonical Linear Issueとは別の**sync shadow Issue**を作ることがある。

この状態を検出した場合:

- 元のcanonical Linear Issueをauthorityとして維持する。
- shadow Issueを新しいWork itemとして扱わない。
- shadow Issueからcanonical Issueへcontract / dependency / progressを移し替えない。
- legacy GitHub Issueを新しく作り直さない。
- **GitHub attachment / sync relationが残っているshadow Issueを先にCanceled / Duplicate / Doneへ変更しない。** status変更がGitHub mirrorへ逆伝播する可能性があるため。

他のIssueのmigration / sync / reconciliationを進行中の場合は、shadow cleanupをその場で実行しない。検出だけ記録し、同期作業が落ち着いた明示的なcleanup checkpointまで保留する。

cleanup checkpointでは次の順序を守る。

1. canonical Linear Issueとlegacy GitHub Issueの既存mappingを再確認する。
2. shadow IssueのGitHub attachment / official sync relationを先に解除する。
3. legacy GitHub Issueが削除・close・意図しないfield変更を受けていないことを確認する。
4. sync解除を確認できた場合だけ、shadow Issueをcanonical Linear IssueのDuplicateとして整理する。
5. sync解除を確認できない場合はstatusを変更せず、その場で停止する。

このcleanupは通常のlegacy mirror reconciliationとは別の保守作業として扱う。canonical Linear Issueとlegacy GitHub Issueのone-way mirror運用は維持する。

## ChatGPT operation rule

Linear Issueを参照・更新するときは、そのIssueがofficial syncedかlegacy manual mirrorかを確認する。

### Official synced issue

- field mutationはLinearへ行い、official syncへ任せる。
- public commentはGitHub sync threadへreplyする。
- sync thread / attachmentが欠落している場合はfaultとして報告する。

### Legacy manual mirror

- Linearを先に更新する。
- 同じcheckpointで対応GitHub IssueをLinear current stateへreconcileする。
- public commentはLinear + GitHubへmirrorする。
- GitHub側の独自編集をLinearへ取り込まない。

ChatGPTが直接変更していないLinear UI上の更新も取りこぼさないため、legacy Issueは定期reconciliation対象とする。

## Privacy boundary

GitHub repository / Issuesはpublicである。

Issue description / commentへ公開してよいWork informationだけをmirrorする。明示的にinternal / non-publicと指定された内容はGitHubへmirrorしない。
