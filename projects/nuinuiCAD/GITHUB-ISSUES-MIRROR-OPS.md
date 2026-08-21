# nuinuiCAD GitHub Issues mirror operations

## Purpose

GitHub Issues public mirrorを運用するCloudflare Worker、webhook / Queue / safety sweep、repair / shadow cleanupのruleを定義する。

- authority / public boundary / loading: [`GITHUB-ISSUES-SYNC.md`](./GITHUB-ISSUES-SYNC.md)
- reconciliation field / mapping contract: [`GITHUB-ISSUES-MIRROR-CONTRACT.md`](./GITHUB-ISSUES-MIRROR-CONTRACT.md)

## Automatic mirror owner

通常の自動reconciliation ownerはCloudflare Worker `nuinuicad-linear-github-mirror` とする。

```text
Linear Issue / Comment / Document change
  → Linear webhook
  → Cloudflare Worker
  → HMAC / replay-window validation
  → Cloudflare Queue
  → canonical Linear data refetch
  → GitHub REST API reconcile
```

Webhook対象は`Issue`、`Comment`、`Document`とする。

Webhook gapやrelation-only change、Document / comment driftを回収するため、同じWorkerがCloudflare Cron `0 */12 * * *` (UTC) で12時間ごとのsafety sweepを実行し、同じQueue reconciliation pathへ流す。

旧ChatGPT `Legacy Issue Mirror` scheduled automationはcutover完了後は無効のまま維持し、通常経路として再有効化しない。Cloudflare mirrorが障害で長時間利用できず、明示的なfallback運用を決めた場合だけ別途扱う。

## Reconciliation operation

Webhook / sweepのどちらから入った場合も、canonical Linear current dataをrefetchしてからGitHub REST APIへreconcileする。

GitHub側の状態をそのままLinear authorityとして採用しない。

Issue / Document createのdeduplication、hidden marker、managed commentの識別等の具体的contractは [`GITHUB-ISSUES-MIRROR-CONTRACT.md`](./GITHUB-ISSUES-MIRROR-CONTRACT.md) に従う。

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

Linear Issue / Documentを参照・更新するときはLinearを先に更新し、自動mirrorを通常経路とする。

- 通常のfield / comment更新について、同じcheckpointでGitHub Issueを手動二重更新しない。
- mirror attachmentがまだ無い新規Issueでも、Workerがcreate / attachするため通常は手動GitHub Issueを作らない。
- Linear DocumentもWorkerがGitHub Issueをcreate / reconcileするため通常は手動mirrorしない。
- mirror driftを検出した場合は、まずLinear current stateとCloudflare Worker / Queueの状態を確認する。
- manual reconciliationは自動経路の障害調査または明示的なrepair時だけ行う。
- Linear公式GitHub Issues two-way sync mappingを再度有効化しない。

## Fallback boundary

Cloudflare mirrorの通常経路が一時的に失敗しただけで、旧ChatGPT scheduled mirrorやLinear公式two-way syncを自動的に再有効化しない。

fallback / manual repairが必要な場合も、Linearをauthorityとして [`GITHUB-ISSUES-MIRROR-CONTRACT.md`](./GITHUB-ISSUES-MIRROR-CONTRACT.md) と同じone-way reconciliation contractを維持する。
