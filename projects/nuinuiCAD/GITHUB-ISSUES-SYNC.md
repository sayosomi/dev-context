# nuinuiCAD GitHub Issues public mirror rule

## Purpose

LinearをnuinuiCADの正式なWork管理・仕様管理のsource of truthとして維持しつつ、`sayosomi/nuinuiCAD` のGitHub Issuesを公開mirrorとして使う。

GitHub Issuesへ公開することを前提とするWork informationは、Linear側だけに残さない。

## Authority

- Work / specificationのauthorityはLinear。
- GitHub Issuesはpublic mirror / public discussion surface。
- GitHub IssuesからLinearへfield / status / commentを逆同期しない。
- repository implementation factsは従来どおりlatest repositoryがauthority。
- Linear公式GitHub Issues repo↔team two-way sync mappingはOFFのまま維持する。
- GitHub PR integration / PR workflow automationはGitHub Issues mirrorとは別物として維持してよい。

## Automatic mirror owner

通常の自動reconciliation ownerはCloudflare Worker `nuinuicad-linear-github-mirror` とする。

```text
Linear Issue change
  → Linear webhook (Issue only)
  → Cloudflare Worker
  → HMAC / replay-window validation
  → Cloudflare Queue
  → canonical Linear Issue refetch
  → GitHub REST API reconcile
```

Webhook gapやrelation-only changeを回収するため、同じWorkerがCloudflare Cron `0 */12 * * *` (UTC) で12時間ごとのsafety sweepを実行し、Sayosomi teamのIssueを同じQueue reconciliation pathへ流す。

旧ChatGPT `Legacy Issue Mirror` scheduled automationはcutover完了後は無効のまま維持し、通常経路として再有効化しない。Cloudflare mirrorが障害で長時間利用できず、明示的なfallback運用を決めた場合だけ別途扱う。

## Mapping contract

GitHub Issueは次の順序でresolveする。

1. Linear Issueに既に付いている `https://github.com/sayosomi/nuinuiCAD/issues/<n>` attachment。
2. legacy mapping fallback。
   - `SAY-9`〜`SAY-38` → GitHub `#186`〜`#215` (`GitHub issue = SAY number + 177`)
   - `SAY-40`〜`SAY-74` → GitHub `#216`〜`#250` (`GitHub issue = SAY number + 176`)
   - `SAY-39` は移行試験用としてmirror対象外
3. GitHub bodyのunique hidden marker `<!-- linear-issue-id:<Linear UUID> -->`。
4. どれも無ければ新しいGitHub Issueを作成する。

GitHub Issueをresolve / createした後、そのURLをLinear Issueへattachmentとして保存する。

GitHub create成功後にLinear attachment createだけ失敗しても、次回はhidden Linear UUID markerから既存GitHub Issueをrecoverし、重複createしない。

### Explicit migration / shadow exclusions

次はpublic Work itemではないmigration / shadow artifactなので、自動mirror対象外とする。

- `SAY-39`
- `SAY-75`
- `SAY-84`
- `SAY-85`

これらから新しいGitHub Issueを作らない。

## Mirrored fields

自動mirrorするもの:

- title
- description
- Linear status → GitHub state / close reason
  - `Done` → `closed / completed`
  - `Canceled` / `Duplicate` → `closed / not planned`
  - `Backlog` / `Todo` / `In Progress` / `In Review` → `open`
- Linear labels
- priority
- project
- parent
- blocks / blocked-by / related metadata

GitHub bodyにはoriginal Linear issue URL、`linear-issue-id` marker、`linear-mirror-updated-at` markerを付加する。

Linearに存在するlabelがGitHub側に無い場合はneutral default colorで作成してから適用してよい。

## Comments / privacy boundary

Linear commentsはv1では自動mirrorしない。

既存Linear top-level discussionにはinternal / non-public内容が入り得るため、comment全自動公開は禁止する。将来comment bridgeを追加する場合は、explicit public marker等のprivacy-safe contractを別途決める。

GitHub repository / Issuesはpublicである。Issue descriptionへ公開してよいWork informationだけを置く。明示的にinternal / non-publicと指定された内容はGitHubへmirrorしない。

## GitHub-side edits

GitHub Issuesはpublic mirrorでありauthorityではない。

- GitHub側の独自field / status編集をLinearへ取り込まない。
- 次回Linear webhookまたは12-hour safety sweepで、managed fieldはLinear current stateへ戻ってよい。
- GitHub側の独自commentはLinearへ逆同期しない。

## Shadow cleanup rule

過去にLinear公式two-way syncが有効だった際、legacy GitHub mirrorの更新を新しいLinear Issueとして再取り込み、canonical Issueとは別のsync shadowを作ったことがある。

同様の状態を検出した場合:

- 元のcanonical Linear Issueをauthorityとして維持する。
- shadow Issueを新しいWork itemとして扱わない。
- legacy GitHub Issueを新しく作り直さない。
- GitHub attachment / sync relationが残っているshadow Issueを先にCanceled / Duplicate / Doneへ変更しない。

cleanup checkpointでは次の順序を守る。

1. canonical Linear Issueとlegacy GitHub Issueの既存mappingを再確認する。
2. shadow IssueのGitHub attachment / official sync relationを先に解除する。
3. legacy GitHub Issueが削除・close・意図しないfield変更を受けていないことを確認する。
4. sync解除を確認できた場合だけ、shadow Issueをcanonical Linear IssueのDuplicateとして整理する。
5. sync解除を確認できない場合はstatusを変更せず、その場で停止する。

## ChatGPT operation rule

Linear Issueを参照・更新するときはLinearを先に更新し、自動mirrorが通常経路であることを前提にする。

- 通常のfield更新について、ChatGPTが同じcheckpointでGitHub Issueを手動二重更新しない。
- mirror attachmentがまだ無い新規Issueでも、Workerがcreate / attachするため通常は手動GitHub Issueを作らない。
- mirror driftを検出した場合は、まずLinear current stateとCloudflare Worker / Queueの状態を確認する。
- manual reconciliationは自動経路の障害調査または明示的なrepair時だけ行う。
- Linear公式GitHub Issues two-way sync mappingを再度有効化しない。
