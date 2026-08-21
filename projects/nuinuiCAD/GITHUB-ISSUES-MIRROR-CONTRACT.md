# nuinuiCAD GitHub Issues mirror contract

## Purpose

LinearのnuinuiCAD Work / specificationをGitHub Issuesへone-way public mirrorするときの**reconciliation contract**を定義する。

- authority / public boundary / loading: [`GITHUB-ISSUES-SYNC.md`](./GITHUB-ISSUES-SYNC.md)
- Worker / webhook / Queue / sweep / repair operation: [`GITHUB-ISSUES-MIRROR-OPS.md`](./GITHUB-ISSUES-MIRROR-OPS.md)

## Issue mapping contract

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

## Explicit migration / shadow exclusions

次はpublic Work itemではないmigration / shadow artifactなので、自動mirror対象外とする。

- `SAY-39`
- `SAY-75`
- `SAY-84`
- `SAY-85`

これらから新しいGitHub Issueを作らない。

## Mirrored Issue fields

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

## Comments

Linearで書かれたコメントは公開情報として扱い、すべてGitHubへone-way mirrorする。public marker、privacy marker、opt-in markerは使わない。

- Linear Issue comment → 対応するGitHub Issue comment
- Linear Document comment → そのDocumentを表すGitHub Issue comment
- comment create / update / removeをreconcileする
- managed GitHub commentには `<!-- linear-comment-id:<Linear comment UUID> -->` を付ける
- Linear側で編集されたmanaged commentはGitHub側を更新してよい
- Linear側で削除されたmanaged commentはGitHub側から削除してよい
- GitHub-only commentはLinearへ逆同期しない
- GitHub-only commentはsweep / reconcileで上書き・削除しない

Linearへ保存する前にpublicにしてよい内容かを判断する。internal / non-public情報をLinear commentへ書いた後にmirror側で非公開扱いにする仕組みは設けない。

## Linear Document mirror

nuinuiCAD Initiative subtree内のLinear DocumentをGitHub Issueとして公開mirrorする。

- 1 Linear Document = 1 GitHub Issue
- GitHub Issueへ `Linear Document` labelを付ける
- bodyへ `<!-- linear-document-id:<Linear Document UUID> -->` markerを付ける
- title / body / commentsをLinear current stateからreconcileする
- Document archive / trash / removeはGitHub Issueを`closed / not planned`へreconcileする
- GitHub側のtitle / body / state / comment editをLinearへ逆同期しない
- authenticated mediaはmirrorのために再hostしない

対象scopeはnuinuiCAD Initiativeそのもの、およびそのProject / child Initiative等から辿れるsubtreeに限定する。workspace内の無関係なDocumentをmirrorしない。

Document create時はGitHub側のread-after-write delayを考慮し、hidden `linear-document-id` markerがrepository issue listingから観測可能になるまでserialized Queueを解放しない。同じLinear Documentについてqueued create eventが重なっても、canonical GitHub Issueを1件だけ維持する。

## GitHub-side edits

GitHub Issuesはpublic mirrorでありauthorityではない。

- GitHub側の独自field / status編集をLinearへ取り込まない。
- 次回Linear webhookまたは12-hour safety sweepで、managed fieldはLinear current stateへ戻ってよい。
- GitHub側の独自commentはLinearへ逆同期しない。
- GitHub-only commentはmanaged Linear commentと区別し、reconciliationで保持する。
