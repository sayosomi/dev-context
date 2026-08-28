# nuinuiCAD local tools

## Purpose

nuinuiCADで繰り返すmechanical / deterministicなHuman terminal operationを、長いcopy/paste shellへ毎回展開せず、version管理されたlocal helperとして安全に再利用する。

このdocumentはlocal helperの配置、利用、同期、実機verification、promotion / repair lifecycleをownerする。checkout / lane safety semanticsそのものは[`CHECKOUTS.md`](./CHECKOUTS.md)をauthorityとする。

## Authority and local checkout

GitHub上の`sayosomi/dev-context`がauthoritative sourceであり、local cloneはcache / toolboxである。local cloneや過去chatをProject Contextのsource of truthにしない。

ChatGPTはnuinuiCAD作業開始時、local cloneの有無にかかわらず、常にGitHub上のlatest [`README.md`](./README.md)を取得し、そのloading ruleに従う。

標準local clone path:

```text
/Users/yosomi/Code/dev-context
```

versioned helper paths:

```text
/Users/yosomi/Code/dev-context/projects/nuinuiCAD/scripts/nuinui
/Users/yosomi/Code/dev-context/projects/nuinuiCAD/scripts/nuinui-e2e-prepare
```

この`dev-context` cloneはnuinuiCAD repositoryの4th checkoutではない。

## Local sync rule

ChatGPTが承認済みdev-context create / update / deleteをGitHubへ反映した場合、同じ応答でlocal cloneへ反映するgit commandを必ず提示する。

既存cloneの標準sync:

```bash
git -C /Users/yosomi/Code/dev-context pull --ff-only
```

cloneがまだ存在しないことが分かっている場合は、初回clone commandを提示する。

```bash
git clone https://github.com/sayosomi/dev-context.git /Users/yosomi/Code/dev-context
```

ChatGPTはHumanが実行する前にlocal sync済みとみなさない。

`nuinui context-sync`は既存cloneをsafe fast-forwardするconvenience commandとして利用できるが、ChatGPTがdev-contextを書き換えた後にraw git sync commandをHumanへ案内する義務の代替にはしない。

local cloneがdirty、`main`以外、またはfast-forward不可能なら、syncは勝手にreset / stash / forceせず`BLOCKED:`で停止する。

## Versioned `nuinui` helper

`projects/nuinuiCAD/scripts/nuinui`は、実機verification済みのmechanical operationだけを持つ。

current commands:

| Command | Purpose |
| --- | --- |
| `nuinui preflight` | fixed main / sub / e2e 3-lane stateのread-only audit |
| `nuinui start <main\|sub> <SAY-123> <expected-base-sha> <branch>` | verified FREE laneをexact baseからTask branchへ開始 |
| `nuinui resume <main\|sub> <SAY-123> <expected-checkpoint-sha> <branch>` | safe idle laneをremote保存済みexisting Task branchのexact checkpointへ復帰 |
| `nuinui release <main\|sub> <checkpoint-sha>` | merged checkpointを確認してimplementation laneをidleへrelease |
| `nuinui pr-auto-merge <pr-number> <expected-head-sha> <expected-main-sha>` | blocking-review済みexact headへ、required CI pending時だけGitHub Auto-mergeを予約 |
| `nuinui e2e-start <SAY-123> <tested-ref>` | idle e2e laneをexact tested refへ固定しmarker作成 |
| `nuinui e2e-start-local-main <SAY-123> <tested-ref>` | Active interim workflow時だけ、cleanな`codex/interim-sequential` main laneのlocal checkpointをe2e laneへ安全に固定しmarker作成 |
| `nuinui e2e-release` | verified e2e stateをlatest `origin/main` detachedへ戻しmarker削除 |
| `nuinui context-sync` | cleanなlocal dev-context `main`をsafe fast-forward |
| `nuinui doctor` | helper / lane / local dev-contextのdiagnostic表示 |
| `nuinui doctor --full` | preflight、E2E session status、local dev-context stateを1回で収集するread-only handoff snapshot |
| `nuinui verify <main\|sub> <SAY-123> <expected-base-sha> <branch>` | lane start前のbranch / base / clean stateをread-only検証 |
| `nuinui transition-audit` | Active interimを変更せず、解除準備に必要なremote/local/worktree/E2E条件をread-only監査 |
| `nuinui context-check` | dev-context全体のMarkdown local link、router、`nuinui` CLI-doc整合をread-only検査 |
| `nuinui self-test` | isolated temporary Git repositoriesでsupported mutation safetyをexercise |

`nuinui resume`は、remote保存済みactive implementation branchへfixed laneを再接続するためのnarrow restore commandである。新しいTaskやsliceを開始するcommandではなく、既存branchのlocal / authoritative remote HEADがcaller指定のexact checkpointと一致し、laneがcleanなsafe idle stateで、同branchが別worktreeに占有されていない場合だけ既存branchへswitchする。既に同branch / exact checkpointならidempotent successとする。

`resume`はactive sliceのBaseを更新しない。authoritative remote main確認のためのfetchは`git fetch origin main`へ限定し、`--prune`や他remote-tracking refのcleanupを行わない。`origin/main`のmerge / rebase / fast-forward、reset、stash、force-switch、force-push、branch作成、dirty workのrepairも行わない。remoteまたはlocal branchのcheckpoint mismatch、idle state mismatch、worktree occupancy、raceを検出した場合は`BLOCKED:`で停止する。

`nuinui pr-auto-merge`は`sayosomi/nuinuiCAD`だけを対象とするreservation-only mutation commandである。PRがOPEN / non-draft / base=`main` / exact reviewed headであり、PRのcurrent `baseRefOid`が`expected-main-sha`と一致し、mergeabilityがunambiguousで、required checksにfailure / cancel / skip / unknown stateがなく少なくとも1件pendingである場合だけ予約へ進む。visibleなrequired checkがある通常pathでは`gh pr checks --required`のbucketを使い、pending / passだけを許可する。

`gh pr checks --required`が空の場合は、それだけで「required checkが0件」と判断しない。current `main` branch protectionの`required_status_checks.contexts[]`とsource-bound `checks[]`を完全照合し、各required checkにpositive numeric `app_id`がある場合だけsecond proofへ進む。exact reviewed headについて`event=pull_request`のActions workflow runとcheck runsを取得し、missing required contextごとに、workflow名がrequired contextと一致するqueued / in-progress run、同じ`check_suite_id`からmaterialize済みのcheck run、required checkと同じGitHub App idを相関できる場合だけ、そのmissing aggregatorをpendingとして扱う。required context自身がmaterialize済みならstatus / conclusionを直接分類する。branch protectionが本当にrequired check 0件、contexts/checks不一致、source-unbound / invalid app id、API failure、pagination ambiguity、workflow/check-suite/app correlation欠落、required failure / cancel / skip / neutral / unknown、または全required checks passの場合はfail-closedで`BLOCKED:`とする。

`pr-auto-merge`はmutation直前に同じsafety-critical preconditionを再確認し、GitHub GraphQLの`enablePullRequestAutoMerge` mutationを直接使う。blocking-review済みheadは`expectedHeadOid`へ渡し、merge methodは`MERGE`へ固定する。reservation pathでは`gh pr merge --auto`や`mergePullRequest`など、即時mergeへ分岐し得るoperationを使わない。precondition確認後にrequired CIが完了したraceではGitHubの`clean status` rejectionをsafe stopとして扱い、direct mergeへfallbackしない。

mutation後はPRが同じexact head / expected mainのままOPENで、`autoMergeRequest.mergeMethod=MERGE`になったことをread-backしてから`AUTO-MERGE RESERVED`を返す。head / main / state / read-back mismatch、mutation failureでは成功扱いにせず`BLOCKED:`で停止する。Auto-merge cancel、CI rerun、rebase、reset、force、bypass、direct merge、repairは自動実行しない。

pre-materialization fallbackのrepair / promotion verificationでは、observed production response shapeを使うdeterministic replayでchanged pathをexerciseし、Human Macからcurrent GitHub branch-protection / workflow-run / check-run API shapeとapp-id correlationをread-only照合する。ephemeralなaggregator未materialize windowを偶然待つこと自体をsuccess条件にしない。GraphQL reservation / read-back、race rejection、failure path、direct-merge禁止はisolated self-testで継続検証する。

`nuinui doctor --full`はfetch、checkout変更、cleanup、process停止を行わない。3 laneまたはlocal dev-contextがdirty、lane構成が不整合、E2E statusがBLOCKED、E2E status helperが欠落している場合は、観測結果を出力してnonzeroで停止する。Issue選択、lane割当、release可否、次のoperationの決定は行わない。

`nuinui transition-audit`と`nuinui context-check`もread-onlyであり、fetch、checkout / branch変更、worktree削除、marker / session操作、process停止、Issue選択、Linear / GitHub更新、merge判断を行わない。`transition-audit`は解除の承認や通常routeへの切替を決定せず、`context-check`はMarkdownの意味内容・外部URL疎通・product実装を判定しない。

## Human Manual E2E preparation helper

`projects/nuinuiCAD/scripts/nuinui-e2e-prepare`は、`nuinui e2e-start`またはActive interim workflow中の`nuinui e2e-start-local-main`で固定済みのdedicated e2e laneを使って、Human Manual E2Eのhostを一発で準備するversioned helperである。

current commands:

```text
nuinui-e2e-prepare check <SAY-123> <tested-ref> <fixture-path>
nuinui-e2e-prepare prepare <SAY-123> <tested-ref> <fixture-path> [cdp-port]
nuinui-e2e-prepare status
nuinui-e2e-prepare cleanup
```

`prepare`は、exact tested ref / e2e marker / clean detached checkoutを検証し、lockfileに従ってdevDependenciesをmaterializeし、VS Code extensionと`evaluation_stdio`をbuildし、fresh profile / empty extensions / fixture / caller-selected CDP portでExtension Development Hostを起動し、CDP readinessとHuman handoffを確認する。成功時は`READY FOR HUMAN E2E`を出す。

`prepare`は専用session metadataへexact E2E root / handoff / launch PIDを記録する。`cleanup`はそのmetadataとE2E markerを再検証してから、同rootに属するprocessだけを終了し、root・handoff・session metadataを削除する。cleanup未完了の間、E2E laneはreleaseできない。

`status`はread-onlyでE2E checkout、marker、active session metadata、記録済みroot / handoff / launch PIDの状態、および同じtemporary parent直下のunmanaged artifact候補を表示する。unmanaged artifactは削除可能と判定しない。`status`はcleanup、process停止、checkout変更、fetchを行わない。

このhelperはproduct source、tested marker、既存の無関係なVS Code processを自動repairしない。fixtureはdedicated e2e checkoutの外側でなければならず、dependency準備またはbuildによるtracked-file mutationはBLOCKされる。

`projects/nuinuiCAD/scripts/test-nuinui-e2e-prepare`は、temporary Git checkoutとfake hostを使ってprepare失敗時のcleanup、成功したsessionのcleanup、`status`の正常/不整合session・unmanaged artifact表示を検証するisolated self-testである。実機のVS Code / dependency / CDP lifecycleは別途actual laneで確認する。

Humanへcommandを渡すときは、Issue key、tested ref、fixture path、必要ならCDP port等、確定値を埋めたcopy/paste-ready commandにする。Humanにplaceholder判断を委ねない。

ChatGPTがHumanへhelper commandを渡すときは、path、Issue key、expected base、checkpoint、branch、tested ref等、ChatGPT側で確定できる値を埋めたcopy/paste-ready commandにする。Humanにplaceholder判断を委ねない。

helperはproduct / UX / scope判断、Linear checkpoint判断、implementation、conflict resolution、dirty workの保存判断を自動化しない。helperの責務は`CHECKOUTS.md`でHumanに許されるmechanical / deterministic operationだけである。

helper commandの存在は、current workflowでの利用許可を意味しない。executor / lane / interim commandの利用可否はREADME routerとActive overrideがauthorityであり、helperは許可済みoperationのpreconditionとmechanicsだけを担う。

mutation commandは実行直前にsafety-critical stateを再確認し、precondition mismatchでは`BLOCKED:`で停止する。reset / stash / force-switch / force-push / unrelated work破棄を自動repairとして行わない。

## Tool discovery and promotion rule

ChatGPTはnuinuiCAD作業中、繰り返し発生するmechanical / deterministicなHuman terminal operationを見つけた場合、ユーザーから明示的に依頼されなくてもtool化候補としてtrialを提案してよい。

ただし、**未検証のoperationをversioned helperまたはLOCAL-TOOLSへ正式追加してはならない。**

正式追加をChatGPTから提案できる最低条件:

1. intended operationとsafety preconditionが明確である。
2. Humanへ任せてよいmechanical / deterministic scopeである。
3. ユーザーのMac上で、そのoperationをexerciseするtrialが少なくとも1回SUCCESSしている。
4. mutationを含む場合、可能ならisolated temporary repository / dry-runでfailure pathとsafe stopも確認している。
5. trialでfailureが見つかった場合、修正版がSUCCESSするまで正式化しない。

isolated self-testは、production commandと同じmechanics / safety conditionを実際にexerciseしている場合にsuccess evidenceとして使える。real environmentとの差がmaterialでself-testだけでは保証できない場合は、その差に対応する実機successを追加で確認してから正式化する。

正式promotionするcandidateは、success evidenceを得たexact commit / blobから変更してはならない。trial後に別worktreeや手作業の再実装をformal helperへ写す場合は、target candidateで同じverificationを再実行し、tested candidate identityを確認してからpromotionする。

一度成功したtrialへ、未検証の追加featureを混ぜてそのまま正式化しない。新しいbehaviorを追加するなら、そのbehaviorもsuccess evidenceを得てからpromotion対象にする。

success evidenceが得られたら、ChatGPTは「このoperationをversioned helper / LOCAL-TOOLSへ正式追加すると反復作業を減らせる」とproactiveに提案する。dev-contextへのwriteは[`../../shared/DEVELOPMENT.md`](../../shared/DEVELOPMENT.md)のapproval ruleに従い、target file / purpose / intended changeを提示して明示承認を得てから行う。

successful trialは自動promotionではない。Human approvalなしにdev-contextへ追加しない。

## Failure repair loop

versioned helperを実運用してunexpected error、hang、wrong output、unsafe-looking behaviorが出た場合、one-off workaroundだけで終わらせずhelper defectの可能性を確認する。

標準repair loop:

```text
failure evidence
-> exact blocker / cause確認
-> local trial fix
-> isolated / relevant self-test
-> SUCCESSするまで修正と再試験
-> exact tested candidate identityを確認
-> dev-context fix planを提示して承認
-> GitHub authoritative helperへ反映
-> local clone用git sync commandを提示
-> synced helperで必要な再確認
```

repair中もunsafe recoveryは行わない。failureを通すためにsafety checkを弱めたり、dirty workをreset / stash / overwriteしたりしない。

GitHubへ反映する修正版は、少なくとも1回SUCCESSしたbehaviorに限定する。実機でまだ成功していない推測修正をauthoritative helperへ直接入れない。

## Fallback

versioned helperが未install、stale / broken、またはcurrent operationをまだsupportしていない場合は、helper利用を強行しない。

mandatory preflight等でHuman actionが必要なら、[`CHECKOUTS.md`](./CHECKOUTS.md)とshared `human-terminal-instructions` skillに従ったcomplete inline commandをfallbackとして提示する。

fallbackで得られた反復可能なoperationが安定して成功した場合は、上記promotion ruleに従ってChatGPTからtool化を提案する。
