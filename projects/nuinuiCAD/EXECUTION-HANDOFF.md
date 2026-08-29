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

## Durable claim as execution identity

`nuinui` durable implementation slotの`claim`を、same Issue内のslice / generationを区別するlocal execution identityとして使う。

Active laneのdurable slotは少なくとも次を保持する。

```text
issue=<SAY-123>
branch=<current slice branch>
base=<fixed Base checkpoint>
claim=<unique claim>
```

Lunaへbranch / Baseを「expected値として再構成」させない。current branch / Baseはdurable claimからmechanically読み、prompt側はclaimをexact execution tokenとして渡す。

Linear implementation checkpointにはcurrent lane / Base / branch / claim / pushed checkpointを保存する。same Issueのnext sliceではnew startによりnew claimを得る。

## Required execution envelope

Luna promptにはcurrent-runだけのExecution Envelopeを置く。

最低限:

```text
Issue: SAY-123
Slice: <current slice>
Phase: implementation | integration | blocking-fix
Lane: main | sub
Claim: <exact durable claim>
Checkpoint: <exact current lane HEAD expected at handoff>
Current remote main: <fresh exact SHA>
Topic remote mode: absent | exact
```

`Topic remote mode`:

- `absent`: `nuinui start`直後のfresh unpushed branch。remote topicが存在したらBLOCKする。
- `exact`: remote保存済みimplementation / integration / blocking-fix continuation。remote topic HEADがCheckpointとexact一致しなければBLOCKする。

Envelopeへolder slice branch / SHAをhistoryとして併記しない。

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

Current envelopeと異なるolder branch / SHAをLuna自身がexpectedとして持っていたことが判明した場合は`STALE_EXECUTION_CONTEXT`として報告する。actual checkoutをold expectedへ合わせるrepairはしない。

特にsame Issueのprevious slice branchを理由にcheckout / reset / resumeしない。

## Session selection

[`CODING-AGENT.md`](./CODING-AGENT.md)のNew session / Reuse ruleは維持する。ただしNew sessionはcontext hygieneであり、このhandoff gateの代替ではない。

New sessionでもReuseでも、current-run Execution Envelopeとmechanical handoff gateを同じように使う。

## Human / ChatGPT ordering

- New slice: `nuinui start`成功 -> claimをLinear checkpointへ記録 / read-back -> `absent` handoffを生成。
- Existing remote-saved slice resume: `nuinui resume`成功 -> current claim / checkpointをread-back -> `exact` handoffを生成。
- Integration checkpoint: pushed implementation checkpoint + fresh remote main確認 -> `exact` handoffを生成。
- Blocking fix continuation: pushed reviewed/fix checkpoint + fresh remote main確認 -> `exact` handoffを生成。

ChatGPT-side remote freshness gateは各handoff生成直前に行う。

## Versioned helper

- implementation: `projects/nuinuiCAD/scripts/nuinui-handoff-check`
- isolated self-test: `projects/nuinuiCAD/scripts/test-nuinui-handoff-check`

Helperはdurable lane claimをread-only consumeする。lane claim mutation semanticsは[`CHECKOUTS.md`](./CHECKOUTS.md) / [`LOCAL-TOOLS.md`](./LOCAL-TOOLS.md) / current `nuinui` implementationをauthorityとし、このhelperはclaimを作成・修復しない。

## Maintenance rule

このdocumentはnuinuiCAD execution handoff identity / stale-context防止だけをownerする。implementation contract、slicing、lane mutation、Git merge policyを複製しない。
