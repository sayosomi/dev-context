# nuinuiCAD Implementation Coding Agent Policy

## Purpose

nuinuiCADのimplementation / blocking-fix executionを定義する。

Shared role boundary / prompt content / Git handoffは [`../../shared/CODING-AGENT-WORKFLOW.md`](../../shared/CODING-AGENT-WORKFLOW.md) に従う。Prompt language / formattingは [`../../shared/AGENT-PROMPT-STYLE.md`](../../shared/AGENT-PROMPT-STYLE.md) に従う。

Project-specific overrideとして、nuinuiCADのrepository implementation / blocking fixは**Codex Luna xhigh**を標準かつ唯一のimplementation executorとする。web ChatGPTがdirect GitHub editingでimplementationを代替するexecution routeは持たない。

Manual E2E executorはこのpolicyではなく [`MANUAL-E2E.md`](./MANUAL-E2E.md) がauthority。

## Role boundary

ChatGPT owns:

- latest Project Context / remote repository / Linear stateの取得;
- repository / architecture / semantic owner調査;
- product / architecture / implementation contract決定;
- implementation slicingとsafe checkpoint決定;
- execution lane選択;
- Luna prompt生成;
- blocking review / merge判断;
- Linear / GitHub management。

Luna owns:

- current executable sliceの具体的implementation;
- focused / required test execution;
- implementation-side failure diagnosis and fix within the settled contract;
- branch commit / push;
- integration checkpointで必要なlatest-main integration / conflict resolution / integration fix。

Lunaへopen-ended product designやarchitecture選択を委ねない。

## Fixed execution lanes

Implementation executionは [`CHECKOUTS.md`](./CHECKOUTS.md) の2 laneだけを使う。

- `main`: `/Users/yosomi/Code/nuinuiCAD`
- `sub`: `/Users/yosomi/Code/nuinuiCAD-sub`

同時implementationは最大2 track。3つ目のimplementation checkout / worktree / cloneを作らない。

Manual E2Eは`/Users/yosomi/Code/nuinuiCAD-e2e`専用で、implementationへ転用しない。

## Base checkpoint semantics

新しいimplementation sliceをlaneへ載せる直前にChatGPTがlatest remote stateを確認し、**Base checkpoint SHA**を固定する。

Shared Coding Agent Workflowのpre-prompt freshness gateは、nuinuiCADでは次のように適用する。

### New lane / new slice

- prompt生成直前にlatest remote `main`を確認する;
- relevant driftを判断する;
- current sliceのbaseを確定する;
- Linearへlane / Base checkpoint / branchをrecordする。

### Same active slice continuation

active slice中にremote `main`が進んでもroutine merge / rebaseはしない。

ChatGPTはremote advanceを観測し、次だけ判断する。

- unrelated / non-invalidating drift → Base checkpointを変えずcurrent slice継続;
- contract / ownershipをmaterially invalidateするdrift → current workをremoteへ保存し、safe checkpointで停止して再評価。

remote advanceを理由にactive slice途中でbaseをrefreshしない。

### Integration checkpoint

current sliceの実装とfocused verificationが完了し、remoteへ保存された時点でlatest remote `main`を再確認する。

必要なintegrationはそのlaneのLunaが行う。

```text
slice implementation complete
-> push checkpoint
-> inspect latest main
-> Luna merge/rebase/conflict resolution/integration fix
-> required verification
-> blocking review
-> merge
```

相手implementation laneのunfinished branchを直接取り込まない。必要なdependencyは先にintended baseへmergeされること。

## Before Luna run — ChatGPT preparation

Lunaへ渡す前にChatGPTがcurrent Project Contextとlatest relevant repository stateを使って次を確定する。

- current Issue / current slice;
- selected lane;
- Base checkpoint SHA;
- branch;
- concrete change owner / files / symbols / API boundary;
- settled acceptance;
- required verification;
- explicit non-goals;
- blocking / stop conditions。

Lunaへrepository全体のarchitecture探索やscope決定を依頼しない。

## Luna prompt contract

Promptにはcurrent executable sliceだけを書く。

必須:

- repository
- lane checkout path
- expected current lane branch / HEAD / Base checkpoint
- current slice / change target
- concrete required changes
- required tests / verification
- commit / push requirement
- no-mid-slice-main-sync rule
- blocking conditions

Luna start時の`git fetch origin --prune`はrace検出に使ってよいが、active sliceのbaseを自動更新する指示にはしない。

Expected lane stateが違う、dirty workがある、ownership不明、Base checkpointから勝手に進んでいる等の場合は変更せず停止して報告させる。

## Scope control

Lunaが次に当たったら広域探索・redesignへ進ませない。

- settled contractから一意に決められないproduct / architecture decision;
- current slice外のsemantic owner変更が必要;
- unrelated user changes;
- required dependencyが未merge;
- current implementationがnatural safe boundaryを越えて拡大する。

その場合はcurrent workを安全に保存できるならcheckpointし、ChatGPTが再調査 / re-sliceする。

## Rerun minimization

失敗runを同じ曖昧promptで繰り返さない。

1. ChatGPTがLuna result / failure evidenceを読む。
2. failure classとownerを特定する。
3. contract / slice / verificationを必要範囲だけ更新する。
4. same active sliceのnarrow blocking fixなら同lane / same session reuseを検討する。
5. new slice / checkpoint後なら原則new Luna session。

## Luna session selection

Default: **New session**。

Reuse current sessionは次をすべて満たすときだけ。

- same lane;
- same current executable slice;
- same branch;
- narrow blocking-fix / direct continuation;
- retained contextがreconstruction costを明確に下げる。

New sessionを使う典型:

- new Issue / new slice;
- integration checkpoint後;
- execution lane変更;
- semantic owner / contract変更;
- major remote drift後;
- previous sessionにstale / broad explorationが多い。

ユーザーへLuna promptを提示するとき、prompt外側に次を明示する。

```text
Luna lane: main | sub
Luna session: New session | Reuse current session
```

Reuse時だけ短い理由を添える。

## E2E failure fix

Manual E2Eでconfirmed implementation failureが出たら、`e2e` checkoutでは修正しない。

ChatGPTがfailureをclassify / sliceし、`FREE`な`main`または`sub`へfixを割り当て、Lunaが実装する。fix merge後、new exact tested commitで`e2e`へ戻す。

## Cross-chat continuity

別ChatGPT conversationへ継続するために長いhandoff proseを標準化しない。

current Linear Issueへ最低限記録する。

- lane;
- Base checkpoint;
- branch / PR / pushed head;
- completed acceptance;
- remaining acceptance;
- current verification / blocker;
- next safe checkpoint。

次conversationはlatest Project Context、remote repository、Linearから再構成する。
