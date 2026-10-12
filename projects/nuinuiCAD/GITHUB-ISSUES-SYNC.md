# nuinuiCAD historical GitHub Issues mirror

このdocumentはC1 cutover以前のLinear-to-GitHub public mirrorのhistory、mapping、provenance、preservation境界を案内する。現在のWork / contract authorityは[`ISSUES.md`](./ISSUES.md)、旧reconciliation pipelineの記録は[`GITHUB-ISSUES-MIRROR-OPS.md`](./GITHUB-ISSUES-MIRROR-OPS.md)と[`GITHUB-ISSUES-MIRROR-CONTRACT.md`](./GITHUB-ISSUES-MIRROR-CONTRACT.md)がownerする。

## Current authority after C1

C1 policyが有効になった後、GitHub Issuesはcurrent Work / contract recordであり、既存のLinear-mirrored GitHub IssueはLinear変更で上書きされるactive public mirrorではない。Current Issue contract、material evidence、execution factsは[`ISSUES.md`](./ISSUES.md)に従う。

Cloudflare Worker `nuinuicad-linear-github-mirror` は、[#268のproduction shutdown read-back](https://github.com/sayosomi/dev-context/issues/268#issuecomment-6120792472)と[post-disabled barrier verification](https://github.com/sayosomi/dev-context/issues/268#issuecomment-6120985293)に記録されたとおりdisabled modeで稼働している。記録version `41736512-dc33-440b-b292-e470e2541519` とdisabled read-backを保持し、mirror writeを再開しない。Linear公式GitHub Issues two-way syncもOFFのまま維持する。C1はWorker設定、deployment、Queue、Cron、DLQを変更しない。

新しいWorkのために既存mirrorを修復・reconcileしたり、Linearへreverse-syncしたりしない。旧recordの不整合や欠落はhistoryとして保持し、機械的に直さない。C1 cutover後、通常の作業でreconciliationを実行しない。

## Historical mapping and preservation

以前のpipelineはLinear Issue / Comment / Documentを公開GitHub Issueへ一方向にmirrorし、managed fields、comments、statusをreconcileしていた。以前Linearへ保存したIssue / Document commentはpublic mirrorへ公開される前提で扱い、privacy markerによる非公開化は行わなかった。このpublic-information boundaryも過去記録として扱う。mapping、hidden provenance marker、対象field、comment ownership、Document履歴、GitHub-side editの意味は[`GITHUB-ISSUES-MIRROR-CONTRACT.md`](./GITHUB-ISSUES-MIRROR-CONTRACT.md)にhistorical referenceとして残す。

既存GitHub IssueのnumberはLinear SAY identifierと同一ではない。既存Issue / Document / comment identity、original URL、hidden marker、comments、close reason、attachment mappingを保持する。Issue / Documentをrecreate、renumber、bulk rewrite、deleteせず、duplicateやmirror driftを自動修復しない。

旧pipelineのPhase B shutdown / lossless repair実装履歴は[#268](https://github.com/sayosomi/dev-context/issues/268)にある。Cloudflare Worker、webhook、Queue、Cron、DLQの動作・disable evidence・未解決履歴を調べるときだけ[`GITHUB-ISSUES-MIRROR-OPS.md`](./GITHUB-ISSUES-MIRROR-OPS.md)を読む。読み取りは許可するが、ordinary reconciliation、fallback、DLQ replayを指示するものではない。

## Loading rule

1. 新規 / 既存Workのcurrent contractには[`ISSUES.md`](./ISSUES.md)を読む。
2. 旧mirror mapping、provenance、preservation historyを調査する場合は[`GITHUB-ISSUES-MIRROR-CONTRACT.md`](./GITHUB-ISSUES-MIRROR-CONTRACT.md)をhistorical referenceとして読む。
3. Disabled Workerや過去pipelineの調査で必要な場合だけ[`GITHUB-ISSUES-MIRROR-OPS.md`](./GITHUB-ISSUES-MIRROR-OPS.md)を読む。ChatGPTは通常reconciliationを実行しない。
4. 現在のGitHub PR linking / review / merge policyは[`LINEAR-GITHUB.md`](./LINEAR-GITHUB.md)を読む。

このdocumentは過去のmirror authorityを現在のWork authorityへ混同せず、mappingとpreservationの参照先を保つ。
