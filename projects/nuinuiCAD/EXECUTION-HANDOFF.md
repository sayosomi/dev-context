# nuinuiCAD execution handoff authority

## Purpose

nuinuiCADのLuna implementation / integration / blocking-fix handoffで、same Issueのold slice stateがcurrent expected stateへ混入することを防ぐ。

Shared ruleは[`../../shared/EXECUTION-HANDOFF.md`](../../shared/EXECUTION-HANDOFF.md)をauthorityとする。このdocumentはnuinuiCAD固有のdurable implementation claimとmanifest-declared laneを使ったmechanical verificationを定義する。

## Authority

Current execution stateは次から再構成する。

1. latest Project Context / policy;
2. current Linear Issue checkpoint;
3. latest GitHub remote state;
4. actual declared lane durable claim / checkout state。

Luna session、past prompt、past chat、Issue identifier単独はauthorityではない。

Durable claim自体のauthorityはactual declared lane metadataである。Linearにclaimを複製していても、そのcopyだけをcurrent claimとして使わない。chat rotation / recovery後はfresh local lane evidenceからclaimを読み直す。

## Durable claim as execution identity

`nuinui` durable implementation slotの`claim`を、same Issue内のslice / generationを区別するlocal execution identityとして使う。

Active laneのdurable slotは少なくとも次を保持する。

```text
issue=<SAY-123>
branch=<current slice branch>
base=<durable Base checkpoint>
claim=<unique claim>
```

Lunaへbranch / Baseを「expected値として再構成」させない。current branch / Baseはdurable claimからmechanically読み、prompt側はfresh local evidenceから取得したclaimをexact execution tokenとして渡す。

same Issueのnext sliceではnew startによりnew claimを得る。previous sliceのclaimをIssue identityだけから再利用しない。

## Required execution envelope

Luna promptにはcurrent-runだけのExecution Envelopeを置く。

最低限:

```text
Issue: SAY-123
Slice: <current slice>
Phase: implementation | integration | blocking-fix
Lane: <manifest-declared implementation lane>
Claim: <exact durable claim from fresh lane evidence>
Checkpoint: <exact current lane HEAD expected at handoff>
Current remote main: <fresh exact SHA>
Topic remote mode: absent | exact
```

Branch and Base remain durable-slot facts. They are derived by the public
handoff façade only after the caller Lane / Issue / Claim identity matches;
they are not caller-supplied handoff arguments.

`Topic remote mode`:

- `absent`: `nuinui begin`（または低レベル`nuinui start`）直後のfresh unpushed branch。remote topicが存在したらBLOCKする。
- `exact`: remote保存済みimplementation / integration / blocking-fix continuation。remote topic HEADがCheckpointとexact一致しなければBLOCKする。

`Topic remote mode: exact`の場合も、current execution envelopeへChatGPTが置くcommandは1つだけである。

```text
/Users/yosomi/Code/dev-context/projects/nuinuiCAD/scripts/nuinui handoff --lane <lane> --issue <Issue> --claim <Claim> --checkpoint <Checkpoint> --main <Current remote main> --topic exact
```

Envelopeへolder slice branch / SHA / claimをhistoryとして併記しない。

## Mechanical handoff gate

Lunaはrepository operation前に、ChatGPTが値を埋めた次のcommandを**そのまま**最初に実行する。

```text
/Users/yosomi/Code/dev-context/projects/nuinuiCAD/scripts/nuinui handoff --lane <implementation-lane> --issue <SAY-123> --claim <claim> --checkpoint <checkpoint-sha> --main <current-default-sha> --topic <absent|exact>
```

Lunaはこのcommandのargumentをpast session / memoryから再生成・置換しない。Branch / Baseを別途caller expectationとして推論しない。

Helperはread-onlyで次を検証する。

- assigned declared lane / repository identity;
- active durable claimが存在しvalid;
- Issue / claim exact match;
- durable claimのbranchとactual checkout branchの一致;
- checkpointとactual HEADのexact一致;
- checkpointがclaimed Baseのdescendant;
- clean working tree;
- mutation lock / release-pending stateがない;
- remote topicが`absent`またはcheckpointへ`exact`一致;
- authoritative remote default branchがcaller-supplied current defaultへexact一致;
- verification中にlocal / remote stateが変化していない。

`git fetch`、checkout、switch、reset、stash、merge、rebase、ref update等は行わない。

成功時だけ:

```text
HANDOFF VERIFIED
```

を返す。

### `HANDOFF VERIFIED` is terminal startup proof

For the current Execution Envelope, `HANDOFF VERIFIED` is terminal startup proof for the startup facts owned by the canonical `nuinui handoff` façade and its standalone `nuinui-handoff-check` authority:

- assigned repository / lane identity;
- durable Issue and claim;
- claimed branch;
- checkpoint / HEAD;
- claimed Base ancestry;
- clean state;
- absence of mutation / release-pending state;
- exact remote topic presence / checkpoint according to `absent` or `exact` mode;
- authoritative remote main;
- no local / remote identity drift during the check.

After `HANDOFF VERIFIED`, do not require a second command solely to re-prove those same facts. In particular, do not treat any of the following as a second post-success handoff gate merely for reconfirmation:

- `git fetch origin --prune`;
- `refs/remotes/origin/<branch>`;
- `git branch -r`;
- shorthand or ambiguous remote branch lookup;
- another ad-hoc `ls-remote` query.

This does not prohibit a fetch or remote inspection with a genuinely new material reason during a later implementation or integration operation. A genuinely new race-sensitive topic-branch fact must use exact remote authority:

```text
git ls-remote --heads origin "refs/heads/<exact branch>"
```

Local `refs/remotes/origin/*` refs are never authoritative remote-topic evidence against a successful canonical handoff. A later fetch must not override the successful handoff or turn a remote-tracking ref into topic authority.

If a secondary observation conflicts with `HANDOFF VERIFIED` without a repository mutation or a genuinely new material external event, preserve the canonical handoff result for the facts owned by the helper. Do not send the Human back through diagnosis, preflight, state paste, or regenerated handoff merely because of that secondary observation. A genuinely new material drift signal still routes to the appropriate existing owner.

Keep Topic remote mode semantics exact: `absent` means fresh unpushed generation, and `exact` means pushed-checkpoint continuation. The helper must not infer the mode.

## Failure handling

Generic defaultはhard-stopである。Helperが`BLOCKED:`または`ERROR:`を返した場合、Lunaはrepository mutationへ進まない。

唯一のautomatic recovery exceptionは、`Topic remote mode: exact`のpushed-checkpoint continuationで、initial exact handoff-checkがnonzero終了し、first output lineがexactly次の場合だけである。

```text
BLOCKED: handoff claimed branch mismatch
```

この場合だけ、canonical `nuinui handoff` façadeがdurable slotを再読し、caller Lane / Issue / Claimを再照合してBranch / Baseを導出し、既存のguarded `nuinui resume` mutation semanticsを1回だけ実行する。resume outputは次のcanonical evidenceを返さなければならない。

```text
IMPLEMENTATION RESUMED
lane=<lane>
issue=<Issue>
branch=<Branch>
base=<Base>
checkpoint=<Checkpoint>
claim=<Claim>
clean=yes
state=BUSY
```

canonical evidenceの後、同じcaller expectationでhandoff proofを1回だけ再実行する。second proofが`HANDOFF VERIFIED`で始まる場合だけrepository operationを続行する。resumeが失敗、evidenceがmissing / noncanonical、またはsecond proofが失敗した場合は停止し、recoveryをretryしない。

`CALLER_EXPECTED` / `ACTUAL` diagnosticsは、LunaがBranch、Base、Issue、Claim、Checkpoint、Current remote main、またはreplacement commandをsubstituteするauthorizationではない。identity valueとcommandはsession contextやrepository historyから推測・再生成しない。`absent` modeにはこのautomatic recoveryを適用しない。

Current envelopeと異なるolder branch / SHA / claimをLuna自身がexpectedとして持っていたことが判明した場合は`STALE_EXECUTION_CONTEXT`として報告する。actual checkoutをold expectedへ合わせるrepairはしない。

特にsame Issueのprevious slice branchを理由にcheckout / reset / resumeしない。

## Session selection

[`CODING-AGENT.md`](./CODING-AGENT.md)のNew session / Reuse ruleは維持する。ただしNew sessionはcontext hygieneであり、このhandoff gateの代替ではない。

New sessionでもReuseでも、current-run Execution Envelopeとmechanical handoff gateを同じように使う。

## Human / ChatGPT ordering

- New slice: ChatGPTがfresh remote / current occupancy / parallel-admission decisionからtarget FREE declared implementation lane、Base、branch、complete inventoryを決める -> Humanが`nuinui begin <implementation-lane> <SAY-123> <expected-base-sha> <branch> <complete-implementation-inventory>`を1回実行 -> complete `IMPLEMENTATION STARTED` envelopeを確認 -> existing checkpoint ruleを完了 -> `absent` handoffを生成。
- Same active durable generation continuation: current Linear checkpoint / last verified envelopeからLane / Issue / Claim / Checkpoint / Current remote main / Topic remote modeをcaller expectationとして渡す -> Human preflightなしでLunaが最初に短い`nuinui handoff`を実行 -> `exact` modeのexact branch-mismatch classifierだけはfaçadeがexisting resumeを1回実行し、canonical `IMPLEMENTATION RESUMED`とsecond `HANDOFF VERIFIED`まで完了する -> 続行する。それ以外のfailureは[`CHECKOUTS.md`](./CHECKOUTS.md)へroutingする。
- Integration checkpoint: pushed implementation checkpoint + fresh remote main確認 -> 通常はsame-generation claim / checkpointを`exact` Luna handoffへ渡す。already-reviewed headについてChatGPTがsemantic `NON-INTERFERING` + current-base freshness-only merge gateをauthorizeした場合だけ、same durable identityをcaller inputにしてHuman `nuinui integrate-clean`へrouteできる。
- Blocking fix continuation: pushed reviewed/fix checkpoint + fresh remote main確認 -> same-generation claim / checkpointを`exact` handoffへ渡す。blocking fixだけを理由にHuman preflightへ戻さない。
- Chat rotation: rotation aloneではpreflightを要求しない。current Issue / lane / generation / checkpointをdurable external stateから復元できる場合は、caller expectationを構成して`nuinui handoff`へ進む。
- Crash、Issue #84 exception外のBLOCKED、unexpected checkout / branch / dirty state、identity不明、explicit diagnosis / recoveryでは[`CHECKOUTS.md`](./CHECKOUTS.md)のpreflight diagnostic / routing ruleを使う。exact pushed-checkpoint continuationのinitial failureがexactly `BLOCKED: handoff claimed branch mismatch`の場合だけは、上記one-attempt façade recoveryを先に適用し、recovery失敗・ambiguous evidence・second proof failure時にCHECKOUTS.mdへroutingする。

ChatGPT-side remote freshness gateは各handoff生成直前に行う。remote main freshnessはこのGitHub-side checkとhandoff-check inputであり、それだけではHuman declared-lane preflightのinvalidationではない。

## Conflict-free Human integration handoff

`nuinui integrate-clean-command`は`nuinui-handoff-check`のreplacementではなく、same durable execution identityをconsumeする既存`nuinui integrate-clean` mutation boundaryへのread-only canonical façadeである。`nuinui integrate-clean`自体は従来どおり別のmutation boundaryとして残る。

ChatGPTは実行前にlatest remote main、saved Review Head / Integration Watermark / claim、post-integration driftをfresh確認し、semantic `NON-INTERFERING`とcurrent-base freshness-only merge gateをauthorizeする。helper自身がmutation直前・verification後・push後にexact durable/local/remote stateを再検証するため、過去の`HANDOFF VERIFIED`だけでmutationをauthorizeしない。

checkout / branch / claim mismatchがある場合、`integrate-clean`はsilent resume / repairをしない。exact pushed-checkpoint continuationが既存Issue 84 recovery条件を満たす場合は先にそのresume + handoff recoveryを完了し、clean exact checkpointを再構成してから別 invocationとして`integrate-clean`へ進む。

通常のeligible freshness-only handoffでは、ChatGPTはsemantic `NON-INTERFERING` authorizationとsettled verification planをfreshに確定した後、named `integrate-clean-command` inputをHumanへ渡す。Humanは同じterminalでそのhelperを実行し、出力された1行のshell-safe positional `integrate-clean` invocationをverbatimで実行する。helperはIssue / claim / reviewed topic head / expected mainをcaller-controlledのまま保持し、verification scriptとoptional manifestのquoting / sentinel placementだけをcanonicalizeする。

success envelopeのnew `head`はmerge-only integration checkpoint、`integration_watermark`はmerged exact main。helper成功だけでblocking review freshnessやrequired PR CIをPASS扱いにしない。

## Versioned helper

- implementation: `projects/nuinuiCAD/scripts/nuinui-handoff-check`
- canonical façade: `projects/nuinuiCAD/scripts/nuinui handoff`
- isolated self-test: `projects/nuinuiCAD/scripts/test-nuinui-handoff-check`
- façade regression: `projects/nuinuiCAD/scripts/test-nuinui-handoff`

Helperはdurable lane claimをread-only consumeする。lane claim mutation semanticsは[`CHECKOUTS.md`](./CHECKOUTS.md) / [`LOCAL-TOOLS.md`](./LOCAL-TOOLS.md) / current `nuinui` implementationをauthorityとし、このhelperはclaimを作成・修復しない。

## Maintenance rule

このdocumentはnuinuiCAD execution handoff identity / stale-context防止だけをownerする。implementation contract、slicing、lane mutation、Git merge policyを複製しない。
