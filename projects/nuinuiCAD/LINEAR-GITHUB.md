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

各implementation mergeまたはGitHub Auto-merge予約では、intermediate / finalを問わず少なくとも次を満たす。

- [`IMPLEMENTATION-SLICING.md`](./IMPLEMENTATION-SLICING.md) のMerge checkpointを満たす。
- current sliceに必要なautomated verification / CIとblocking reviewが完了している。
- latest remote `main`と、必要なinterference / freshness checkを再確認してmerge可能である。
- unresolved blocker、新しいproduct / UX / scope decision、未解決のrequired failure、または安全に継続できないownership conflictがない。
- intermediate PRでは`Fixes` / `Closes`等のclosing magic wordを付けず、merge後にimplementation checkpointをLinearへ記録する。
- final completion PRではremaining implementation acceptanceが本当に完了することを確認し、standard closing magic wordを使う。

### GitHub Auto-merge reservation

repository settingでrequired `CI`とGitHub Auto-mergeが有効な場合、blocking review PASS後に次の条件をすべてfresh remote evidenceで確認して、`nuinui pr-auto-merge <pr-number> <expected-head-sha> <expected-main-sha>`でreservationしてよい。helperはGitHub GraphQLの`enablePullRequestAutoMerge` mutationを直接使い、`expectedHeadOid`へblocking-review済みexact headを渡す。reservation pathでは`gh pr merge --auto`、`mergePullRequest`、`--admin`、force、bypass等、即時mergeへ分岐し得るoperationを使わない。

- PRがopenかつnon-draftで、intended baseとexpected head SHAがcurrent contractに一致する。
- PR identity、head、base、remote drift、mergeability、GitHub authorizationにambiguityがない。
- required check `CI`がPRをgateする設定であり、現在のrequired failureがなく、少なくとも1件がqueued / in_progressである。required checksがすべて完了済みならreservation helperは`BLOCKED:`で停止し、即時mergeへ切り替えない。
- current sliceのautomated verificationとblocking reviewがPASSし、product / UX / scope / architecture owner / acceptanceの未解決decisionがない。
- reservation直前にhead / base / expected main / required CI stateを再確認し、`expectedHeadOid`でheadを固定する。GitHub上でauto-mergeが有効になったことをread-backする。
- precondition確認後にCIが完了したraceでは、`enablePullRequestAutoMerge`の`clean status` rejectionをsafe stopとして扱い、direct mergeへfallbackしない。

reservation helperが`BLOCKED: all required checks are already complete`で停止したことは、reservation-only pathが成立しなかったことだけを意味し、CI failure、implementation pause、lane release、Issueの`Todo` transitionを意味しない。helper自身からdirect mergeへfallbackしてはならないが、Humanがその`BLOCKED`結果を返してcurrent executionを明示resumeした場合は、それを新しいcontinuation boundaryとしてPR / head / base / main / CI / mergeabilityをfreshに確認する。required CIがsuccessで通常のmerge gateを満たすなら、既存のmerge authorizationに基づきordinary manual merge pathを継続し、追加のmerge確認を要求しない。local lane releaseの依頼または成功だけからIssue statusを`Todo`へ変更せず、statusはmerge state / remaining acceptance / Manual E2E stateから独立に決定する。

予約後、agentはCI完了・mergeをwait / pollせずexecution trackを終了する。GitHubのrequired CIがgreenならmergeし、merge Discord通知をexisting routeで送る。CI non-successなら同じDiscord routeのfailure通知が送られ、Humanが必要なら明示的にCodexをresumeする。Discord通知は自動resume、CI rerun、cancel、failure diagnosis、repair、merge、Linear updateを許可しない。

Humanがfailure後に明示resumeした時だけ、fresh PR/head/base/Actions/contract evidenceから再開する。failure evidenceによりapproved contract・scope・current architecture内の次の修正が一意なら継続してよい。複数の妥当なimplementation案、product / UX / contract判断、scope拡大、authority conflict、architecture owner変更、acceptance変更、Manual E2E judgment、destructive / external-state riskではHumanへ再承認を求める。同一failureの反復やflaky / retry-onlyは根拠なくgreenまでretryせず、まずCI incident routeとmodel escalationを使う。PR/head/base identity ambiguity、auth / permission、GitHub outageは実装判断ではなく`BLOCKED`として停止・報告する。

Auto-merge後のLinear syncは、Discord merge通知だけを根拠に実行しない。Humanの明示resume後、authoritative merged commit、remaining acceptance、Manual E2E stateを再確認してからこのdocumentのstatus ruleに従う。

PR前の包括承認は、少なくとも次を値埋めして記録する。

```text
Issue / objective: <key and authority reference>
Approved contract and non-goals: <references>
PR target: <repository>, base <base>, expected head <SHA>
Permission: create/push this PR; after blocking review PASS, reserve GitHub Auto-merge for this exact head through the reservation-only helper with expectedHeadOid. Do not use a direct merge path.
CI failure: Discord notification stops the track. No automatic resume, rerun, cancel, repair, merge, or Linear update; resume only on my explicit instruction.
Repair after explicit resume: continue only when the evidence makes one contract/scope/current-architecture fix unique; otherwise return for my decision.
Stop immediately: PR/head/base/auth/GitHub ambiguity, scope or acceptance change, owner/architecture conflict, Manual E2E judgment, destructive/external-state risk.
```

Issue開始 / 継続許可後は、通常のmerge確認そのものをhuman gateにしない。安全停止が必要なのは、new product / UX / scope decision、Contract readiness喪失、unresolved blocker / required failure、unsafe interference / ownership conflict、destructive operation、またはcurrent execution methodでは完了できないrequired work等、実装を安全に一意継続できない条件が発生した場合。

manual mergeまたはHuman明示resume後に確認したfinal implementation mergeでは、current Manual E2E stateに従って次まで同期する。Auto-merge予約だけではstatusを同期しない。

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
- manual PR merge → current Manual E2E / execution ownershipを確認してChatGPTがstatusを同期
- auto-merge → Discord通知後のHuman明示resumeでauthoritative merged stateを再確認してから同期

通常、実装開始済みTaskはPR作成・blocking review・merge直前まで`In Progress`のまま。

Required Manual E2Eは [`MANUAL-E2E.md`](./MANUAL-E2E.md) に従い**merge後実行をdefault**とする。implementation、automated verification、CI、blocking reviewをmerge前に完了させ、Manual E2Eはmerge後のproduction execution stateで行う。

Pre-merge Manual E2Eは、Task contractがunusual risk等の理由で明示した場合だけの例外。例外的pre-merge E2Eが`Failed`で未解決ならmergeしない。

PR merge checkpointでは少なくとも次を確認する。

- same Issueにremaining acceptanceがあるintermediate PR → `IMPLEMENTATION-SLICING.md`のimplementation checkpointを記録し、Issue completion transitionを行わない
- Manual E2Eが`Passed` → completion条件を確認して`Done`
- Manual E2Eが`Not Required` → completion条件を確認して`Done`
- required Manual E2Eがあり、merge後すぐ実行可能 → leafのexecution ownershipを確認し、通常`In Review + Manual E2E: Ready to Run`
- required Manual E2Eを意図的に後回し → `In Review + Manual E2E: Deferred`
- `manual_e2e_only` transition条件を満たすleaf → [`LINEAR-ISSUES.md`](./LINEAR-ISSUES.md) のlabel/status条件を確認し、[`CHAT-E2E.md`](./CHAT-E2E.md) / [`MANUAL-E2E.md`](./MANUAL-E2E.md) のexecution ownerへhandoff

merge後Manual E2Eで`FAIL`した場合は、同じIssueのscopeなら通常のfix → automated verification → review → merge → affected Manual E2E rerunへ戻す。post-merge FAILが起こり得ること自体を理由にdefaultをpre-mergeへ変更しない。

`Done`へ進める場合は [`LINEAR-ISSUES.md`](./LINEAR-ISSUES.md) のDone-before Ready contract freshness checkを実施する。

## No duplicate GitHub Issues update

Linear IssueのGitHub Issues public mirrorはCloudflare Worker syncをauthorityとする。

Linear更新と同じ内容をChatGPTがGitHub Issueへ手動二重記録しない。mirror behavior、対象metadata、exceptionは [`GITHUB-ISSUES-SYNC.md`](./GITHUB-ISSUES-SYNC.md) に従う。
