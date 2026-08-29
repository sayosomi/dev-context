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
Claim: <exact durable claim from fresh lane evidence>
Checkpoint: <exact current lane HEAD expected at handoff>
Current remote main: <fresh exact SHA>
Topic remote mode: absent | exact
```

`Topic remote mode`:

- `absent`: `nuinui begin`（または低レベル`nuinui start`）直後のfresh unpushed branch。remote topicが存在したらBLOCKする。
- `exact`: remote保存済みimplementation / integration / blocking-fix continuation。remote topic HEADがCheckpointとexact一致しなければBLOCKする。

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

Helperが`BLOCKED:`を返した場合、Lunaはrepository mutationへ進まない。

Current envelopeと異なるolder branch / SHA / claimをLuna自身がexpectedとして持っていたことが判明した場合は`STALE_EXECUTION_CONTEXT`として報告する。actual checkoutをold expectedへ合わせるrepairはしない。

特にsame Issueのprevious slice branchを理由にcheckout / reset / resumeしない。

## Session selection

[`CODING-AGENT.md`](./CODING-AGENT.md)のNew session / Reuse ruleは維持する。ただしNew sessionはcontext hygieneであり、このhandoff gateの代替ではない。

New sessionでもReuseでも、current-run Execution Envelopeとmechanical handoff gateを同じように使う。

## Human / ChatGPT ordering

- New slice: ChatGPTがfresh remote / Linear occupancy / parallel-admission decisionからtarget FREE lane、Base、branch、expected peerを決める -> Humanが`nuinui begin <main|sub> <SAY-123> <expected-base-sha> <branch> <FREE|SAY-123>`を1回実行 -> complete `IMPLEMENTATION STARTED` envelopeを確認 -> existing Linear checkpoint ruleを完了 -> `absent` handoffを生成。
- Same active durable generation continuation: last verified lifecycle envelopeまたはcurrent Linear checkpointからclaim / checkpointをcaller expectationとして渡す -> Human preflightなしでLunaが最初に`nuinui-handoff-check`を実行 -> actual local durable claim / checkout / remote stateとのmatch後に`exact` handoffを続行する。
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
