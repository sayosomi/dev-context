# nuinuiCAD historical GitHub Issues mirror operations

## Purpose and status

このdocumentはC1 cutover前に使われていたCloudflare Workerのwebhook / Queue / Cron reconciliation pipelineを、調査可能なhistorical operationとして記録する。通常のWork authoring、contract、status更新の手順ではない。Current authorityは[`ISSUES.md`](./ISSUES.md)、mirror historyとmappingの案内は[`GITHUB-ISSUES-SYNC.md`](./GITHUB-ISSUES-SYNC.md)がownerする。

Cloudflare Worker `nuinuicad-linear-github-mirror` は、[#268のproduction read-back](https://github.com/sayosomi/dev-context/issues/268#issuecomment-6120792472)と[post-disabled barrier verification](https://github.com/sayosomi/dev-context/issues/268#issuecomment-6120985293)に記録されたdisabled modeで維持する。記録versionは`41736512-dc33-440b-b292-e470e2541519`。Workerは無効のままとし、HTTP / webhook、Queue consumer、CronのいずれからもGitHub writeを再開しない。

## Historical pipeline behavior

以前はLinearのIssue / Comment / Document eventをone-wayで公開GitHub Issueへ反映していた。

```text
Linear Issue / Comment / Document change
  → webhook signature / replay-window validation
  → Cloudflare Worker
  → Queue
  → canonical Linear data refetch
  → GitHub REST API reconcile
```

Cloudflare Cronは以前`0 */12 * * *` UTCでsafety sweepを行い、webhook gapやrelation-only changeをQueue経由で回収した。Issue / Documentのdeduplication、hidden marker、managed comment識別などは[`GITHUB-ISSUES-MIRROR-CONTRACT.md`](./GITHUB-ISSUES-MIRROR-CONTRACT.md)に記録される。この説明は過去挙動の調査用であり、再稼働手順ではない。

## Cutover operation boundary

- C1後のGitHub Issueを過去のmirror destinationとして扱わず、Linear側の値で上書きしない。
- ordinary reconciliation、repair sweep、手動GitHub issue update、reverse syncを実行しない。
- 旧ChatGPT `Legacy Issue Mirror` automation、Linear公式two-way sync、Workerのautomatic fallbackを再有効化しない。
- Cloudflare Workerを再deploy / reactivateせず、webhook、Queue、Cron設定を変更しない。
- 8件のhistorical DLQ messageはuntouchedのまま保つ。DLQをpurge、ack、replay、再投入しない。
- mirror drift、duplicate、欠落historyが見つかっても、自動修復、destructive cleanup、Issueの作り直しをしない。必要ならevidenceをread-onlyで調査し、#268の新たな明示決定がない限り停止する。

過去のshutdown / verification / DLQ evidenceを確認する必要がある場合は、[#268](https://github.com/sayosomi/dev-context/issues/268)と[`GITHUB-ISSUES-SYNC.md`](./GITHUB-ISSUES-SYNC.md)を参照する。Disabled stateはworker sourceやhealth endpoint単独ではなく、記録済みのdeployment / mode / route guards / read-back evidenceに基づく。

## Historical shadow cleanup and fallback record

以前Linear公式two-way syncが有効だった時期には、legacy GitHub mirror updateからduplicate sync shadow Issueが生じた。Historical investigation recordには次の順序が残っている。

1. canonical Linear Issueとlegacy GitHub Issueの既存mappingを再確認する。
2. shadow IssueのGitHub attachment / official sync relationを先に解除する。
3. legacy GitHub Issueが削除・close・意図しないfield変更を受けていないことを確認する。
4. relation解除を確認できた場合に限り、shadow Issueをcanonical Linear IssueのDuplicateとして整理する。
5. relation解除が確認できなければstatusを変更せず停止する。

これは過去手順の調査記録であり、C1後にこのcleanupを実行してshadowを変更・close・deleteしない。

過去の運用でも、Cloudflare mirror failureだけを理由にChatGPT scheduled mirrorやLinear two-way syncへautomatic fallbackすることは禁止されていた。この禁止は引き続き有効であり、明示的なPhase C1 approvalや一般reconciliation permissionを意味しない。

## Loading rule

このdocumentはdisabled Worker / historical webhook・Queue・Cron behavior / preserved DLQ evidenceの調査にだけ読む。通常のGitHub Issue Workを扱うときは[`ISSUES.md`](./ISSUES.md)を読み、mirror reconciliationは行わない。
