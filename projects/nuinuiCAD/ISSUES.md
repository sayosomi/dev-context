# nuinuiCAD GitHub Issues — prepared policy (inactive)

この文書は `sayosomi/nuinuiCAD` の **Phase C向け GitHub-native Work / Issue contract** の準備版である。入口は [nuinuiCAD Project Context](./README.md)、移行全体の契約は [dev-context #268](https://github.com/sayosomi/dev-context/issues/268) が所有する。

## Activation boundary

**C0では非適用。** この文書を作成・参照・mergeしただけでは GitHub Issues を正式な Work authority にしない。現行の [Project Context](./README.md)、[Linear policy](./LINEAR.md)、[GitHub public mirror policy](./GITHUB-ISSUES-SYNC.md) が定める Linear authority / Work lifecycle はそのまま維持する。既存Issueのtitle、body、comments、labels、open/closed、Linear linkageを変更せず、新しいGitHub-native Issueもこの準備作業だけでは作成しない。

本policyを運用開始するには、Phase Bの本番 write barrier の記録を確認したうえで、**別途明示承認された Phase C1 の統合変更**により Project Context と関係ownerの authority / loading / lifecycle を整合させ、review・CI・merge後に発効を宣言する必要がある。Worker停止だけでもこの切替は成立しない。以下は **C1以降に適用する設計済みルール**である。

## Authority after activation

責務を次のように分ける。

- **Current Work scope / acceptance / implementation contract:** `sayosomi/nuinuiCAD` の GitHub Issue **body**。
- **Material evidence / decisions / historical checkpoints:** 当該Issueの **comments**。本文に代わるcurrent contractにはしない。
- **Actual implementation facts:** latest remote `sayosomi/nuinuiCAD` repositoryとそのnormative source / spec。
- **Execution / review / merge facts:** GitHub branch、commit、PR、Actions checks、merge read-back。
- **Durable engineering / DSL specifications:** 対応するrepository Markdown owner。Issueコメントをlong-term normative specの代わりにしない。
- **Linear Issue / Document:** 原則として読み取り専用の履歴参照。旧SAY識別子は保つが、新規Workのauthorityにはしない。

dev-context自身のIssueは引き続き [root ISSUES.md](../../ISSUES.md) がownerし、この文書はnuinuiCADにだけ適用する。root policyからIssue contractの原則だけを再利用し、dev-contextのpersistent worktree / execution routingは持ち込まない。

## Native Issue authoring and identity

新規WorkはGitHubの `sayosomi/nuinuiCAD#N` をcanonical IDとし、**SAY番号とGitHub Issue番号は一致するものと扱わない**。新しいSAY Issue、Linear mirror marker、Linearへの逆同期を作らない。Linearの枠不足を理由にBug報告を止めない。

作成前にlatest remote repository、関連owner / spec、GitHub IssueとPR、必要な既存SAY・mirrored Issueを調べ、同じWorkの重複起票を避ける。既存Issueへ安全に追記できるならそれを使う。新規作成時はproblem、scope、依存、実行可能な acceptance / verification、non-goals、関連する歴史的リンクを具体化する。ChatGPTが新規Issueを提案する場合はdraft / scopeを示してHumanの承認を得る。「起票して」等の明示依頼はその範囲の承認として扱う。

**Same Issue / new Issue:** 独立scope、semantic owner、acceptance oracle、単独完了の安全性、durable tracking valueを持つ場合だけ分離する。単に小さなPRを複数作る目的でIssueを増やさず、必要なら同一Issueに複数PRを結びつける。

## Contract and state

GitHubの `open` はWork未完了、`closed` は検証済み完了を表す。旧Linearの `Backlog / Todo / In Progress / In Review / Done` を機械的にラベルへ複製しない。branch、PR、checks等のexecution stateはGitHubの実記録から判断する。

Current contract readinessが必要な場合は `contract:pending` / `contract:ready` / `contract:blocked` の3ラベルだけを使い、open Work Issueは通常exactly oneにする。ラベル導入はC1/C2の承認された設定・運用変更で行う。**C0では作成も既存Issueへの付与も行わない。**

- `pending`: investigation、contract、acceptance、Humanが決めるべき分岐が未完了。
- `ready`: current authority、scope、依存、verificationが確認済みで、開始前re-audit可能。
- `blocked`: required prerequisite / external capability が利用できずcontractを確定できない。単なる実装待ちはblockedではない。

Issue bodyはSummary / Scope / Required contract / Dependencies / Acceptance / Non-goalsをcurrent meaningで保持する。commentsにはinvestigation evidence、rationale、review、audits、PR checkpointsを残す。obsoleteなdecisionを本文へ累積させない。Priorityは必要ならIssue bodyのテキストで扱い、新しいpriority taxonomyやGitHub Projectの導入は必須にしない。

## Freshness, concurrent writes and re-audit

Issue作成・更新・実装開始直前に、current Issue body、material comments、関連Issue / PR、latest remote code / specを再取得する。複数chatやHumanのconcurrent updateをlast-write-winsで消さない。scope / acceptance / product decisionの衝突が一意に解消できなければ停止し、Human判断を求める。

`contract:ready` は実装開始済みという意味ではない。開始前にowner、依存、acceptance、最新コードと実行ルートをre-auditし、実質的選択が生じたら `pending`、required prerequisite喪失なら `blocked` とする。checkout・lane・audit・Manual E2E手順は切替後の専用ownerが定める。**この準備文書は現行 `nuinui` lifecycleを廃止しない。**

## History preservation and completion

旧Linear由来のcanonical GitHub Issue / Document mirrorsを **recreate、renumber、bulk rewrite、delete** しない。既存 `SAY-xxx` URL、hidden `linear-issue-id` / `linear-document-id` / `linear-comment-id` markers、本文、comment、close reason、添付mappingを保持する。duplicate / shadowは個別判定とし、自動削除・統合しない。旧Linear Documentに未移管の規範的内容があれば現行性を審査し、適切なrepository ownerへ限定的に昇格する。

PRは `Refs #N` で関連づける。required implementation、review、CI、**必要なHuman Manual E2E**、その他acceptanceがすべて完了すると証明できる場合だけ `Closes #N` を使い、close前に最新mainとverificationを確認する。required Manual E2Eを免除したり、PR mergeだけで未完了Issueをclosedにしない。protected PR / independent exact-head review / safe auto-mergeの詳細は別ownerに従い、ここでは置き換えない。

## Maintenance boundary

本documentは **C1発効後のnuinuiCAD GitHub Issue authoring / contract / state / history境界** のみownerする。移行実施計画・cutover証拠は [#268](https://github.com/sayosomi/dev-context/issues/268)、local checkoutと実行は [CHECKOUTS.md](./CHECKOUTS.md) 等、既存mirrorのreconciliation詳細は [GITHUB-ISSUES-SYNC.md](./GITHUB-ISSUES-SYNC.md) 側がownerする。個別TaskのSHA / branch / progressをここへ保存しない。
