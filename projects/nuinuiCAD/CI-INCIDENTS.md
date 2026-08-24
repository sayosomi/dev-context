# nuinuiCAD shared CI incident escalation

## Purpose

Issue-local regressionではなくshared `main` / common CI infrastructure由来のCI障害が疑われる場合のdiagnosis / local reproductionを定義する。

通常のCI failureでは読まない。目的は4つ目のdiagnostic checkoutを作ることではなく、web evidenceで原因を絞り、local reproductionが本当に必要な場合だけ**FREEなimplementation lane**を一時利用すること。

## When to enter

strong signal:

- semantic footprintが独立した複数PRで同じrequired job / stepが失敗;
- failing ownerがcurrent Issue diffから外れ、Base checkpoint以降のmain advanceと相関;
- latest mainまたはunrelated branchでも同じfailure signature;
- current changeからfailing ownerへのplausible causal pathがない。

単独PRの普通のtest failureやcurrent diffが直接触るownerのfailureはshared incident扱いしない。

## Incident authority

local reproduction前にChatGPTが確定する。

- repository;
- workflow run ID / URL;
- failing head SHA;
- failing job / step;
- failing stepのexact command;
- failing SHA時点のworkflow definition / setup sequence。

環境authorityはlatest mainではなく**失敗したhead SHAで実行されたworkflow**。

## Web evidence first

local executionを最初のfallbackにしない。

まずwebから取得できるrun / job / logs / artifacts / diff / workflow / relevant source / testsを確認する。

web evidenceだけでexact failureとcauseが十分ならlocal reproductionしない。

## Fixed-lane local reproduction

local reproductionが必要なら [`CHECKOUTS.md`](./CHECKOUTS.md) の`FREE`なimplementation laneを使う。

候補:

1. `main` laneがFREEなら`/Users/yosomi/Code/nuinuiCAD`;
2. `main` BUSYかつ`sub` FREEなら`/Users/yosomi/Code/nuinuiCAD-sub`;
3. 両方BUSYならincident reproductionのために新checkoutを作らない。どちらかがsafe checkpointでrelease可能になるまで既存Taskを保全する。

禁止:

- `/Users/yosomi/Code/nuinuiCAD-ci-repro`の作成 / 使用;
- additional worktree / clone;
- `e2e` laneの転用;
- BUSY laneをreset / stash / force-switchして空けること。

## Executor

local CI reproductionは原則Luna xhighへnarrow diagnostic Taskとして渡す。

ChatGPTがworkflow evidence、exact failing SHA、selected FREE lane、exact commands / expected evidenceを確定する。Lunaへproduct redesignやunrelated cleanupを依頼しない。

Human terminal executionが不可避なcapability gapとして残る場合も同じFREE laneだけを使用し、人間へcheckout / SHA / command選択を委ねない。

## Lane preparation

selected laneについて変更前に確認する。

- current stateがFREE / clean;
- remote access;
- failing SHA availability;
- no current Issue ownership。

reproductionはfailing SHAをdetached HEADで行ってよい。product branch ownershipを持たない。

state-changing Git operationはdiagnostic setupに必要なnon-destructive switchだけに限定する。reset / clean / stash / force operationは禁止。

## Environment matching

failing workflowからlocalで再現可能な条件を最大限一致させる。

- exact failing SHA;
- Node / Rust toolchain;
- lockfile install (`npm ci`等);
- environment variables;
- prerequisite build / fixture generation;
- failing step exact command。

OS / architecture等一致できない条件はevidenceへ明示する。MacでPASSしてもCI failure不存在を意味しない。

## Reproduction sequence

1. selected laneがFREE / cleanであることを再確認。
2. `git fetch origin --prune`。
3. failing SHAへdetached checkout。
4. failing workflowのsetupを同じ順序で再現。
5. exact failing CI commandを最初に実行。
6. failing file / suite / test / first relevant errorを特定。
7. race / flakyが疑われる場合だけfocused bounded repeat。
8. evidenceをcurrent Issue / incident ownerへ戻す。
9. laneをcleanなidle stateへrelease。

focused testから推測で始めず、まずexact CI commandを再現する。

## If local does not reproduce

local PASSをresolved扱いしない。

-一致できなかったOS / architecture / environmentを記録;
- plausible race evidenceがある場合だけbounded repeat;
- それでも再現しなければ`not reproduced locally`をevidenceとして返す。

## From diagnosis to fix

shared incident fixが必要なら、diagnostic detached stateのままproduct changeを始めない。

1. incident scope / contractをChatGPTが確定;
2. same selected implementation laneをrelease / normal startし直す、またはもう一方のFREE laneを使う;
3. fresh Task branch + Base checkpointをLinearへ記録;
4. Luna implementation / verification;
5. integration checkpoint / blocking review / merge。

CI diagnosisからimplementationへroleが変わる地点を明確にする。

## Lane release

reproduction後は:

- repository changeなし;
- generated artifact / dependency stateがworking treeをdirtyにしていない;
- detached diagnosis stateからlane固有idle stateへ安全に戻す;
- actual FREE stateを確認。

安全にreleaseできなければ`BLOCKED / UNKNOWN`として報告し、強制cleanupしない。
