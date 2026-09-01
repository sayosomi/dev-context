# nuinuiCAD execution handoff authority

## Purpose

nuinuiCADのLuna implementation / integration / blocking-fix handoffで、same Issueのold slice stateがcurrent expected stateへ混入することを防ぐ。

Shared ruleは[`../../shared/EXECUTION-HANDOFF.md`](../../shared/EXECUTION-HANDOFF.md)をauthorityとする。このdocumentはnuinuiCAD固有のdurable implementation claimとfixed laneを使ったmechanical verificationを定義する。

## Authority

Current execution stateは次から再構成する。

1. latest Project Context / policy;
2. current Linear Issue checkpoint;
3. latest GitHub remote state;
4. actual fixed lane durable claim / checkout state。

Luna session、past prompt、past chat、Issue identifier単独はauthorityではない。

Durable claim自体のauthorityはactual fixed lane metadataである。Linearにclaimを複製していても、そのcopyだけをcurrent claimとして使わない。chat rotation / recovery後はfresh local lane evidenceからclaimを読み直す。

## Durable claim as execution identity

`nuinui` durable implementation slotの`claim`を、same Issue内のslice / generationを区別するlocal execution identityとして使う。

Active laneのdurable slotは少なくとも次を保持する。

```text
issue=<SAY-123>
branch=<current slice branch>
base=<fixed Base checkpoint>
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
Lane: main | sub
Branch: <exact durable claimed branch>
Base: <exact claimed Base>
Claim: <exact durable claim from fresh lane evidence>
Checkpoint: <exact current lane HEAD expected at handoff>
Current remote main: <fresh exact SHA>
Topic remote mode: absent | exact
```

`Topic remote mode`:

- `absent`: `nuinui begin`（または低レベル`nuinui start`）直後のfresh unpushed branch。remote topicが存在したらBLOCKする。
- `exact`: remote保存済みimplementation / integration / blocking-fix continuation。remote topic HEADがCheckpointとexact一致しなければBLOCKする。

`Topic remote mode: exact`の場合、current execution envelopeへChatGPTが次の2つのexact prefilled commandを置く。

```text
Handoff command:
/Users/yosomi/Code/dev-context/projects/nuinuiCAD/scripts/nuinui-handoff-check <lane> <Issue> <Claim> <Checkpoint> <Current remote main> exact

Recovery command:
/Users/yosomi/Code/dev-context/projects/nuinuiCAD/scripts/nuinui resume <lane> <Issue> <Base> <Checkpoint> <Branch> <Claim>
```

Envelopeへolder slice branch / SHA / claimをhistoryとして併記しない。

## Mechanical handoff gate

Lunaはrepository operation前に、ChatGPTが値を埋めた次のcommandを**そのまま**最初に実行する。

```text
/Users/yosomi/Code/dev-context/projects/nuinuiCAD/scripts/nuinui-handoff-check <main|sub> <SAY-123> <claim> <checkpoint-sha> <current-main-sha> <absent|exact>
```

Lunaはこのcommandのargumentをpast session / memoryから再生成・置換しない。branch / Baseを別途expectedとして推論しない。

Helperはread-onlyで次を検証する。

- assigned fixed lane / repository identity;
- active durable claimが存在しvalid;
- Issue / claim exact match;
- durable claimのbranchとactual checkout branchの一致;
- checkpointとactual HEADのexact一致;
- checkpointがclaimed Baseのdescendant;
- clean working tree;
- mutation lock / release-pending stateがない;
- remote topicが`absent`またはcheckpointへ`exact`一致;
- authoritative remote mainがcaller-supplied current mainへexact一致;
- verification中にlocal / remote stateが変化していない。

`git fetch`、checkout、switch、reset、stash、merge、rebase、ref update等は行わない。

成功時だけ:

```text
HANDOFF VERIFIED
```

を返す。

### `HANDOFF VERIFIED` is terminal startup proof

For the current Execution Envelope, `HANDOFF VERIFIED` is terminal startup proof for the startup facts owned by the canonical `nuinui-handoff-check`:

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

この場合だけ、envelopeにあるexact prefilled `Recovery command`を1回実行する。resume outputは次のcanonical envelopeを完全に返さなければならない。

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

canonical evidenceの後、最初に渡したexact `Handoff command`をargument変更なしで再実行する。second handoff outputが`HANDOFF VERIFIED`で始まる場合だけrepository operationを続行する。resumeが失敗、evidenceがmissing / noncanonical、またはsecond handoffが失敗した場合は停止し、recoveryをretryしない。

`CALLER_EXPECTED` / `ACTUAL` diagnosticsは、LunaがBranch、Base、Issue、Claim、Checkpoint、Current remote main、またはreplacement commandをsubstituteするauthorizationではない。identity valueとcommandはsession contextやrepository historyから推測・再生成しない。`absent` modeにはこのautomatic recoveryを適用しない。

Current envelopeと異なるolder branch / SHA / claimをLuna自身がexpectedとして持っていたことが判明した場合は`STALE_EXECUTION_CONTEXT`として報告する。actual checkoutをold expectedへ合わせるrepairはしない。

特にsame Issueのprevious slice branchを理由にcheckout / reset / resumeしない。

## Session selection

[`CODING-AGENT.md`](./CODING-AGENT.md)のNew session / Reuse ruleは維持する。ただしNew sessionはcontext hygieneであり、このhandoff gateの代替ではない。

New sessionでもReuseでも、current-run Execution Envelopeとmechanical handoff gateを同じように使う。

## Human / ChatGPT ordering

- New slice: ChatGPTがfresh remote / Linear occupancy / parallel-admission decisionからtarget FREE lane、Base、branch、expected peerを決める -> Humanが`nuinui begin <main|sub> <SAY-123> <expected-base-sha> <branch> <FREE|SAY-123>`を1回実行 -> complete `IMPLEMENTATION STARTED` envelopeを確認 -> existing Linear checkpoint ruleを完了 -> `absent` handoffを生成。
- Same active durable generation continuation: last verified lifecycle envelopeまたはcurrent Linear checkpointからBranch / Base / Claim / Checkpointをcaller expectationとして渡す -> Human preflightなしでLunaが最初にexact prefilled `nuinui-handoff-check`を実行 -> first lineが`BLOCKED: handoff claimed branch mismatch`でmodeが`exact`の場合だけ、exact prefilled resumeを1回実行してcanonical `IMPLEMENTATION RESUMED`を確認し、同じhandoffを再実行する -> `HANDOFF VERIFIED`後に続行する。それ以外のfailureは[`CHECKOUTS.md`](./CHECKOUTS.md)へroutingする。
- Integration checkpoint: pushed implementation checkpoint + fresh remote main確認 -> 通常はsame-generation claim / checkpointを`exact` Luna handoffへ渡す。already-reviewed headについてChatGPTがsemantic `NON-INTERFERING` + current-base freshness-only merge gateをauthorizeした場合だけ、same durable identityをcaller inputにしてHuman `nuinui integrate-clean`へrouteできる。
- Blocking fix continuation: pushed reviewed/fix checkpoint + fresh remote main確認 -> same-generation claim / checkpointを`exact` handoffへ渡す。blocking fixだけを理由にHuman preflightへ戻さない。
- Chat rotation: rotation aloneではpreflightを要求しない。current Issue / lane / generation / checkpointをdurable external stateから復元できる場合は、caller expectationを構成して`nuinui-handoff-check`へ進む。
- Crash、Issue #84 exception外のBLOCKED、unexpected checkout / branch / dirty state、identity不明、explicit diagnosis / recoveryでは[`CHECKOUTS.md`](./CHECKOUTS.md)のpreflight diagnostic / routing ruleを使う。exact pushed-checkpoint continuationのinitial failureがexactly `BLOCKED: handoff claimed branch mismatch`の場合だけは、上記one-attempt recoveryを先に適用し、recovery失敗・ambiguous evidence・second handoff failure時にCHECKOUTS.mdへroutingする。

ChatGPT-side remote freshness gateは各handoff生成直前に行う。remote main freshnessはこのGitHub-side checkとhandoff-check inputであり、それだけではHuman 3-lane preflightのinvalidationではない。

## Conflict-free Human integration handoff

`nuinui integrate-clean`は`nuinui-handoff-check`のreplacementではなく、same durable execution identityをconsumeする別のmutation boundary。

ChatGPTは実行前にlatest remote main、saved Review Head / Integration Watermark / claim、post-integration driftをfresh確認し、semantic `NON-INTERFERING`とcurrent-base freshness-only merge gateをauthorizeする。helper自身がmutation直前・verification後・push後にexact durable/local/remote stateを再検証するため、過去の`HANDOFF VERIFIED`だけでmutationをauthorizeしない。

checkout / branch / claim mismatchがある場合、`integrate-clean`はsilent resume / repairをしない。exact pushed-checkpoint continuationが既存Issue 84 recovery条件を満たす場合は先にそのresume + handoff recoveryを完了し、clean exact checkpointを再構成してから別 invocationとして`integrate-clean`へ進む。

success envelopeのnew `head`はmerge-only integration checkpoint、`integration_watermark`はmerged exact main。helper成功だけでblocking review freshnessやrequired PR CIをPASS扱いにしない。

## Versioned helper

- implementation: `projects/nuinuiCAD/scripts/nuinui-handoff-check`
- isolated self-test: `projects/nuinuiCAD/scripts/test-nuinui-handoff-check`

Helperはdurable lane claimをread-only consumeする。lane claim mutation semanticsは[`CHECKOUTS.md`](./CHECKOUTS.md) / [`LOCAL-TOOLS.md`](./LOCAL-TOOLS.md) / current `nuinui` implementationをauthorityとし、このhelperはclaimを作成・修復しない。

## Maintenance rule

このdocumentはnuinuiCAD execution handoff identity / stale-context防止だけをownerする。implementation contract、slicing、lane mutation、Git merge policyを複製しない。
