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
- Integration checkpoint: pushed implementation checkpoint + fresh remote main確認 -> same-generation claim / checkpointを`exact` handoffへ渡す。`nuinui-handoff-check`がactual local evidenceを再検証する。
- Blocking fix continuation: pushed reviewed/fix checkpoint + fresh remote main確認 -> same-generation claim / checkpointを`exact` handoffへ渡す。blocking fixだけを理由にHuman preflightへ戻さない。
- Chat rotation: rotation aloneではpreflightを要求しない。current Issue / lane / generation / checkpointをdurable external stateから復元できる場合は、caller expectationを構成して`nuinui-handoff-check`へ進む。
- Crash、BLOCKED、unexpected checkout / branch / dirty state、identity不明、explicit diagnosis / recoveryでは[`CHECKOUTS.md`](./CHECKOUTS.md)のpreflight diagnostic / routing ruleを使う。

ChatGPT-side remote freshness gateは各handoff生成直前に行う。remote main freshnessはこのGitHub-side checkとhandoff-check inputであり、それだけではHuman 3-lane preflightのinvalidationではない。

## Versioned helper

- implementation: `projects/nuinuiCAD/scripts/nuinui-handoff-check`
- isolated self-test: `projects/nuinuiCAD/scripts/test-nuinui-handoff-check`

Helperはdurable lane claimをread-only consumeする。lane claim mutation semanticsは[`CHECKOUTS.md`](./CHECKOUTS.md) / [`LOCAL-TOOLS.md`](./LOCAL-TOOLS.md) / current `nuinui` implementationをauthorityとし、このhelperはclaimを作成・修復しない。

## Maintenance rule

このdocumentはnuinuiCAD execution handoff identity / stale-context防止だけをownerする。implementation contract、slicing、lane mutation、Git merge policyを複製しない。
