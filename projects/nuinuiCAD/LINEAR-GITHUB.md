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

### GitHub Actions Auto-merge reservation（通常経路）

repositoryのrequired `CI`とGitHub Auto-mergeが有効な場合、ChatGPTは**実装Agentの自己申告だけに依存せず**、pushed exact HEADのblocking reviewを行う。以下をfreshなGitHub evidenceで確認し、CIがqueued / in_progressなら、repository所有者のPR Conversation commentに次の**完全一致**requestを1回だけ投稿して予約する。PR番号はcommentを投稿するPRから解決される。

```text
/auto-merge-reviewed
head=<reviewed 40-character lowercase SHA>
base=<fresh authoritative main 40-character lowercase SHA>
review=PASS
```

- `review=PASS`はChatGPTが**そのexact HEADのblocking reviewを実施しPASSと判断した**旨のattestationであり、文字列自体がreviewの代替になるわけではない。commentは`sayosomi`本人のowner権限から投稿する。実装Agentや未検証のPR投稿者へこのcommentを委譲しない。
- 対象は`sayosomi/nuinuiCAD`のopen / non-draft、base=`main`、head / baseがsame repositoryのPR。current authoritative `main`が`base`にexact一致し、reviewed HEADがcurrent `main`をancestorとして取り込んでいること、mergeabilityがunambiguous、既存reservationがないことを確認する。単なるPRの`baseRefOid`はcurrent-main freshness proofとみなさない。
- required protectionはGitHub Actions Appの`CI`であり、reviewed HEADに対応するpull_request CI runがqueued / in_progressかつfailureなし、required aggregatorも未完了であることを確認する。CI runの多重性、check / job状態、head、main、GitHub API、permissionに曖昧さがあればfail closedする。
- owner commentで`.github/workflows/auto-merge-reviewed.yml`が動く。workflowがmutation直前にも上記identity・main・required CIを再検証し、`enablePullRequestAutoMerge(expectedHeadOid, mergeMethod: MERGE)`で**予約だけ**を行う。workflowは`mergePullRequest`、`gh pr merge --auto`、admin / force / bypassや直接mergeへのfallbackを使わない。
- Actionsの成功outputとfreshなPR read-backの両方で`auto_merge.merge_method=merge`および`enabled_by=github-actions[bot]`を証明できた場合だけ「予約完了」とする。comment投稿やworkflow開始だけでは予約成功と呼ばない。失敗・途中state・予期しないreservationは原因を確認するまで再投稿/取消/置換しない。
- **blocking review時点でrequired CIがすべてsuccess**なら予約commentを投稿せず、PR / exact HEAD / fresh main / drift / required CI / mergeability / authorizationを改めて確認し、ordinary merge routeで進める。CI失敗・unresolved / canceled / skippedならmergeしない。必要なcheckが未証明なら停止する。
- reservation request後にCIが先に完了するraceはworkflowのfail-closedとして扱い、workflow内部からdirect mergeしない。ChatGPTがその状態を知って継続可能な場合だけ、fresh remote evidenceと元のmerge authorizationを独立に確認し、既存のordinary merge条件に従う。head / main drift、CI failure、identity ambiguity等は単なるCI完了raceとして扱わない。
- 予約成功後、ChatGPT/実装AgentはCI完了をchatでwait / pollせずexecution trackを終了する。GitHubがrequired CI green後にmergeし、`.github/workflows/discord-bot-automerge-reconcile.yml`がbot mergeを検出・Discord通知し、GitHubにdurable receiptを保存する。通知漏れの再照合には同workflowのbounded scheduleがある。Discord通知だけを根拠に自動resume、CI rerun、修正、merge、Linear更新を行わない。
- CI non-success通知後はHumanの明示resumeがある場合だけfresh PR/head/base/Actions/contract evidenceで診断する。単なるflaky / retry-onlyを推測してCIを繰り返さない。既存のCI incident / blocking-fix safety ruleを維持する。

旧`nuinui pr-auto-merge`ローカル予約helperは、実PRで新方式を実証し、生成元・runtime・テスト・過去の`last-result`読取互換を検証したうえで、dev-context PR #264により廃止済み。新規PRの予約は上記GitHub Actions owner-comment経路のみを使用する。

Auto-merge後のLinear syncはDiscord merge通知だけを根拠に実行しない。Humanがその通知をもとに明示resumeした後、authoritative merge commit / remaining acceptance / Manual E2E stateをfresh確認する。final implementation mergeならexact generationをreleaseし、Lane release checkpointをrecord / read-backした後、このdocumentのstatus ruleで同期する。release失敗 / interruptedではphysical laneをavailableと見なさず、既存のcleanup / status exceptionに従う。

PR前の包括承認は、少なくとも次を値埋めして記録する。

```text
Issue / objective: <key and authority reference>
Approved contract and non-goals: <references>
PR target: <repository>, base <base>, expected head <SHA>
Permission: create/push this PR; after independent ChatGPT blocking review PASS, use the owner-authored exact-head /auto-merge-reviewed GitHub Actions reservation only while required CI is pending, with expectedHeadOid. If required CI is already successful, use a separately fresh-reviewed ordinary merge. No direct merge fallback from the reservation workflow.
CI failure: Discord notification stops the track. No automatic resume, rerun, cancel, repair, merge, or Linear update; resume only on my explicit instruction.
Repair after explicit resume: continue only when the evidence makes one contract/scope/current-architecture fix unique; otherwise return for my decision.
Stop immediately: PR/head/base/auth/GitHub ambiguity, scope or acceptance change, owner/architecture conflict, Manual E2E judgment, destructive/external-state risk.
```

Issue開始 / 継続許可後は、通常のmerge確認そのものをhuman gateにしない。安全停止が必要なのは、new product / UX / scope decision、Contract readiness喪失、unresolved blocker / required failure、unsafe interference / ownership conflict、destructive operation、またはcurrent execution methodでは完了できないrequired work等、実装を安全に一意継続できない条件が発生した場合。

manual mergeまたはHuman明示resume後に確認したfinal implementation mergeでは、current Manual E2E stateに従って次まで同期する。Auto-merge予約だけではstatusを同期しない。

```text
Manual E2E: Not Required
-> implementation execution終了
-> exact current implementation generation release
-> Lane release checkpoint record / read-back
-> Done-before Ready contract freshness check
-> Done

Manual E2E: Required
-> implementation execution終了
-> exact current implementation generation release
-> Lane release checkpoint record / read-back
-> applicable leafはmanual_e2e_onlyへtransition
-> In Review + Manual E2E: Ready to Run / Deferred
```

最初のrelease attemptがfail / interruptedの場合だけ、laneを`BUSY` / `BLOCKED` / `RELEASE-PENDING`等のactual cleanup stateに応じてunavailable capacityとして保持したまま、authoritative merge / remaining Work evidenceに従って`Done`または`In Review`等のstatus synchronizationへ進む。release anomalyだけを理由にcompleted repository implementationを`In Progress`へ戻さない。

Manual E2EがrequiredなIssueでは、implementation開始 / 継続許可をManual E2E実行許可として流用しない。通常のimplementation execution trackはcompleted generation release後の`In Review`へのhandoffで終了し、その先のManual E2E executionは [`MANUAL-E2E.md`](./MANUAL-E2E.md) とexecution-owner ruleに従う。

### Merge completion vs local lane cleanup

GitHub上でrequired merge gateを満たしてfinal implementation PRがintended baseへmergeされた時点で、repository implementation executionは終了する。local checkoutがまだTask branchにいることやidle stateへのdeterministic cleanupが未完了であることを、Issueを`In Progress`へ保持する理由にしない。

normal final-merge pathでは、scarce implementation capacityをbookkeepingより先に解放する。

```text
remote final merge / implementation completion
-> exact current implementation generation release
-> lane = FREE
-> Lane release checkpoint record / read-back
-> Linear statusをactual remaining Workへ同期
```

- status meaning自体はmerge / remaining acceptance / Manual E2E / completion gateに従うが、normal final-merge operation orderではrelease成功とrelease checkpointをstatus writeより先に行う。
- successful complete `IMPLEMENTATION RELEASED` envelope後にphysical FREEを再発見するための別preflightを要求しない。
- 最初のrelease attemptがfail / interruptedした場合、physical lane cleanupは[`CHECKOUTS.md`](./CHECKOUTS.md)のactual `BUSY` / `BLOCKED` / `RELEASE-PENDING` / recovery ruleに従い、new Issueへ割り当てない。その後はauthoritative merged stateからIssue statusを同期し、cleanup anomalyだけを理由にmergeやcompletion stateを巻き戻さない。
- local cleanup中にunmerged / unsaved workが新たに判明した場合は新しいstateとして再評価する。
- intermediate PR merge後にremaining implementation acceptanceがありsame active generationでnext sliceを継続する場合、このfinal-merge release orderingは適用しない。sequential PR ruleに従い、mergeしたという理由だけでcurrent generationをreleaseしない。
- intermediate merge後にcurrent generationをpause / releaseしてnext sliceを待つ場合は[`IMPLEMENTATION-SLICING.md`](./IMPLEMENTATION-SLICING.md)と[`LINEAR-ISSUES.md`](./LINEAR-ISSUES.md)のpause / checkpoint ruleに従う。

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
- manual PR merge → current Manual E2E / execution ownershipを確認し、final implementation mergeならcompleted generation release barrier後にChatGPTがstatusを同期
- auto-merge → Discord通知後のHuman明示resumeでauthoritative merged stateを再確認し、final implementation mergeならcompleted generation release barrier後に同期

通常、実装開始済みTaskはPR作成・blocking review・merge直前まで`In Progress`のまま。

Required Manual E2Eは [`MANUAL-E2E.md`](./MANUAL-E2E.md) に従い**merge後実行をdefault**とする。implementation、automated verification、CI、blocking reviewをmerge前に完了させ、Manual E2Eはmerge後のproduction execution stateで行う。

Pre-merge Manual E2Eは、Task contractがunusual risk等の理由で明示した場合だけの例外。例外的pre-merge E2Eが`Failed`で未解決ならmergeしない。

PR merge checkpointでは少なくとも次を確認する。

- same Issueにremaining acceptanceがあるintermediate PR → `IMPLEMENTATION-SLICING.md`のimplementation checkpointを記録し、Issue completion transitionを行わない。same active generationでnext sliceを継続するならfinal-merge release barrierを適用しない
- final implementation merge → exact current implementation generationのreleaseを最初のlocal lifecycle actionとして試行し、successならLane release checkpointをrecord / read-backしてから以下のstatus transitionを行う
- Manual E2Eが`Passed` → completion条件を確認して`Done`
- Manual E2Eが`Not Required` → completion条件を確認して`Done`
- required Manual E2Eがあり、merge後すぐ実行可能 → leafのexecution ownershipを確認し、通常`In Review + Manual E2E: Ready to Run`
- required Manual E2Eを意図的に後回し → `In Review + Manual E2E: Deferred`
- `manual_e2e_only` transition条件を満たすleaf → [`LINEAR-ISSUES.md`](./LINEAR-ISSUES.md) のlabel/status条件を確認し、[`CHAT-E2E.md`](./CHAT-E2E.md) / [`MANUAL-E2E.md`](./MANUAL-E2E.md) のexecution ownerへhandoff

最初のfinal-merge release attemptがfail / interruptedした場合はphysical laneをunavailable capacityとして保持し、authoritative merge / remaining Work evidenceからstatus transitionを行う。normal E2E startupはrelease anomalyが解消するまで開始しない。

merge後Manual E2Eで`FAIL`した場合は、同じIssueのscopeなら通常のfix → automated verification → review → merge → affected Manual E2E rerunへ戻す。post-merge FAILが起こり得ること自体を理由にdefaultをpre-mergeへ変更しない。

`Done`へ進める場合は [`LINEAR-ISSUES.md`](./LINEAR-ISSUES.md) のDone-before Ready contract freshness checkを実施する。

## No duplicate GitHub Issues update

Linear IssueのGitHub Issues public mirrorはCloudflare Worker syncをauthorityとする。

Linear更新と同じ内容をChatGPTがGitHub Issueへ手動二重記録しない。mirror behavior、対象metadata、exceptionは [`GITHUB-ISSUES-SYNC.md`](./GITHUB-ISSUES-SYNC.md) に従う。
