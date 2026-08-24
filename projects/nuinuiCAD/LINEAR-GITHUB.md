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

### Multiple sequential PRs for one Issue

1つのLinear Issueを複数のsequential implementation PRへ分ける場合は [`IMPLEMENTATION-SLICING.md`](./IMPLEMENTATION-SLICING.md) に従う。

closing magic wordは、そのPRのmergeでIssueのremaining acceptanceが完了する場合だけ使う。

- intermediate PR: `Fixes` / `Closes`等でIssue completionを宣言しない。PR URLをLinear Issueのattachment / checkpoint recordとして明示的に記録する。
- final completion PR: mergeでremaining acceptanceが完了するなら標準のclosing magic wordを使用してよい。
- intermediate PR merge: Issueを`Done`またはManual E2E待ちの`In Review`へ進めない。remaining acceptanceがある限り同じWorkを継続する。
- intermediate merge後のnext sliceはlatest intended baseを再確認し、Linearへimplementation checkpointを記録してから継続する。

GitHub integration上のlink不足を避けるためだけにintermediate PRへ誤ったclosing magic wordを付けない。

## Merge authorization

ユーザーがimplementation Issueの開始またはcurrent execution trackの継続を明示的に許可した時点で、そのexecution trackに必要な**safe implementation work / PR operations / merge / completion status synchronization**まで許可されたものとする。intermediate PRだけでなくfinal implementation PRについても、追加のmerge確認を要求しない。

この開始 / 継続許可は、他policyにある`merge when explicitly authorized`や`PR operations when explicitly authorized`等の表現についても、current Issueを安全に実装完了まで進めるためのexplicit authorizationとして扱う。

各implementation mergeでは、intermediate / finalを問わず少なくとも次を満たす。

- [`IMPLEMENTATION-SLICING.md`](./IMPLEMENTATION-SLICING.md) のMerge checkpointを満たす。
- current sliceに必要なautomated verification / CIとblocking reviewが完了している。
- latest remote `main`と、必要なinterference / freshness checkを再確認してmerge可能である。
- unresolved blocker、新しいproduct / UX / scope decision、未解決のrequired failure、または安全に継続できないownership conflictがない。
- intermediate PRでは`Fixes` / `Closes`等のclosing magic wordを付けず、merge後にimplementation checkpointをLinearへ記録する。
- final completion PRではremaining implementation acceptanceが本当に完了することを確認し、standard closing magic wordを使う。

Issue開始 / 継続許可後は、通常のmerge確認そのものをhuman gateにしない。安全停止が必要なのは、new product / UX / scope decision、Contract readiness喪失、unresolved blocker / required failure、unsafe interference / ownership conflict、destructive operation、またはcurrent execution methodでは完了できないrequired work等、実装を安全に一意継続できない条件が発生した場合。

final implementation merge後は、current Manual E2E stateに従って次まで自動で同期する。

```text
Manual E2E: Not Required
-> Done-before Ready contract freshness check
-> Done

Manual E2E: Required
-> implementation execution終了
-> applicable leafはmanual_e2e_onlyへtransition
-> In Review + Manual E2E: Ready to Run / Deferred
```

Manual E2EがrequiredなIssueでは、implementation開始 / 継続許可をManual E2E実行許可として流用しない。通常のimplementation execution trackは`In Review`へのhandoffで終了し、その先のManual E2E executionは [`MANUAL-E2E.md`](./MANUAL-E2E.md) とexecution-owner ruleに従う。

### Merge completion vs local lane cleanup

GitHub上でrequired merge gateを満たしてimplementation PRがintended baseへmergeされた時点で、repository implementation executionは終了する。local `main` / `sub` checkoutがまだTask branchにいることやidle stateへのdeterministic cleanupが未完了であることを、Issueを`In Progress`へ保持する理由にしない。

merge後の責務を分離する。

```text
remote merge / implementation completion
-> Linear statusをactual remaining Workへ同期
-> local checkoutがidleでなければ lane = RELEASE-PENDING
-> deterministic lane cleanup
-> lane = FREE
```

- Issue statusはmerge / remaining acceptance / Manual E2E / completion gateに従う。
- physical lane cleanupは[`CHECKOUTS.md`](./CHECKOUTS.md)の`RELEASE-PENDING` / release ruleに従う。
- `RELEASE-PENDING` laneは新Issueへ割り当てないが、前Issueのimplementationがまだ実行中であることを意味しない。
- local cleanup failureはlane availabilityのblockerとして扱い、すでに成立したremote mergeやIssue completion stateを巻き戻さない。ただしcleanup中にunmerged / unsaved workが判明した場合は新しいstateとして再評価する。
- intermediate PR merge後にremaining implementation acceptanceがある場合はsequential PR ruleに従い、次sliceを即時開始していなければ`LINEAR-ISSUES.md`のstatus precedenceへ同期する。local cleanup待ちだけで`In Progress`を維持しない。

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

Required Manual E2Eは [`MANUAL-E2E.md`](./MANUAL-E2E.md) に従い**merge後実行をdefault**とする。implementation、automated verification、CI、blocking reviewをmerge前に完了させ、Manual E2Eはmerge後のproduction execution stateで行う。

Pre-merge Manual E2Eは、Task contractがunusual risk等の理由で明示した場合だけの例外。例外的pre-merge E2Eが`Failed`で未解決ならmergeしない。

PR merge checkpointでは少なくとも次を確認する。

- same Issueにremaining acceptanceがあるintermediate PR → `IMPLEMENTATION-SLICING.md`のimplementation checkpointを記録し、Issue completion transitionを行わない
- Manual E2Eが`Passed` → completion条件を確認して`Done`
- Manual E2Eが`Not Required` → completion条件を確認して`Done`
- required Manual E2Eがあり、merge後すぐ実行可能 → leafのexecution ownershipを確認し、通常`In Review + Manual E2E: Ready to Run`
- required Manual E2Eを意図的に後回し → `In Review + Manual E2E: Deferred`
- `manual_e2e_only` transition条件を満たすleaf → [`ONLY-CHATGPT.md`](./ONLY-CHATGPT.md) に従い即時handoff

merge後Manual E2Eで`FAIL`した場合は、同じIssueのscopeなら通常のfix → automated verification → review → merge → affected Manual E2E rerunへ戻す。post-merge FAILが起こり得ること自体を理由にdefaultをpre-mergeへ変更しない。

`Done`へ進める場合は [`LINEAR-ISSUES.md`](./LINEAR-ISSUES.md) のDone-before Ready contract freshness checkを実施する。

## No duplicate GitHub Issues update

Linear IssueのGitHub Issues public mirrorはCloudflare Worker syncをauthorityとする。

Linear更新と同じ内容をChatGPTがGitHub Issueへ手動二重記録しない。mirror behavior、対象metadata、exceptionは [`GITHUB-ISSUES-SYNC.md`](./GITHUB-ISSUES-SYNC.md) に従う。
