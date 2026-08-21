# nuinuiCAD Linear / GitHub integration policy

## Purpose

Linear IssueとGitHub Pull Requestのlinking、PR automation、merge checkpointでのstatus同期を定義する。

GitHub Issues public mirrorは [`GITHUB-ISSUES-SYNC.md`](./GITHUB-ISSUES-SYNC.md) が別authority。この文書はLinearのGitHub PR integrationだけをownerとする。

## PR linking

LinearのGitHub integrationを使い、Linear IssueとGitHub Pull Requestをリンクする。

標準的な紐付けはPR descriptionにclosing magic wordとIssue identifierを記載する方式。

例:

```text
Fixes SAY-38
```

`Linear: SAY-38`のような単なるラベルだけを標準linking方法にしない。

branch名へLinear Issue identifierを入れることは必須にしない。

## Pull request automations

Sayosomi TeamのLinear `Workflows & automations > Pull request automations` は**5項目すべて `No action`**を維持する。

- On draft PR open → `No action`
- On PR open → `No action`
- On PR review request or activity → `No action`
- On PR ready for merge → `No action`
- On PR merge → `No action`

GitHub integrationはPRとIssueのlinkに使うが、Issue statusの決定には使わない。

PR eventだけでは`In Progress` / `In Review` / `Done`の意味を判定できないため、status automationを有効化しない。

## PR lifecycle and Issue status

PR lifecycleだけでIssue statusを決めない。

- draft PR open → status変更なし
- PR open → status変更なし
- PR review request / activity → status変更なし
- PR ready for merge → status変更なし
- PR merge → current Manual E2E / execution ownershipを確認してChatGPTがstatusを同期

通常、実装開始済みTaskはPR作成・blocking review・merge直前まで`In Progress`のまま。

PR merge checkpointでは少なくとも次を確認する。

- Manual E2Eが`Passed` → completion条件を確認して`Done`
- Manual E2Eが`Not Required` → completion条件を確認して`Done`
- required Manual E2Eが未実施で後回し → `In Review + Deferred`
- `manual_e2e_only` transition条件を満たすleaf → [`ONLY-CHATGPT.md`](./ONLY-CHATGPT.md) に従い即時handoff
- merge前Manual E2Eが`Failed`で未解決 → 原則mergeしない

`Done`へ進める場合は [`LINEAR-ISSUES.md`](./LINEAR-ISSUES.md) のDone-before Ready contract freshness checkを実施する。

## No duplicate GitHub Issues update

Linear IssueのGitHub Issues public mirrorはCloudflare Worker syncをauthorityとする。

Linear更新と同じ内容をChatGPTがGitHub Issueへ手動二重記録しない。mirror behavior、対象metadata、exceptionは [`GITHUB-ISSUES-SYNC.md`](./GITHUB-ISSUES-SYNC.md) に従う。
