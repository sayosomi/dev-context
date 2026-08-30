# nuinuiCAD Implementation Coding Agent Policy

## Purpose

nuinuiCADのimplementation / blocking-fix executionを定義する。

Shared role boundary / prompt content / Git handoffは [`../../shared/CODING-AGENT-WORKFLOW.md`](../../shared/CODING-AGENT-WORKFLOW.md) に従う。Prompt language / formattingは [`../../shared/AGENT-PROMPT-STYLE.md`](../../shared/AGENT-PROMPT-STYLE.md) に従う。

Project-specific overrideとして、nuinuiCADの**source-code implementation / blocking fix**は**Codex Luna xhigh**を標準かつ唯一のimplementation executorとする。web ChatGPTがdirect GitHub editingでsource-code implementationを代替するexecution routeは持たない。

### Documentation / policy direct execution exception

Repository-owned documentation / specification / policy workはsource-code implementationとは別のexecution classとする。

次の条件をすべて満たすdocumentation/policy Taskは、Luna xhighを使わずChatGPTがremote repository上で直接実行してよい。

- 変更対象が`docs/**`、`AGENTS.md`、repository/project `README.md`、`ARCHITECTURE.md`、CHANGELOG等のrepository-owned documentation / specification / policy fileに限定される;
- source code、test code、fixtures、build設定、CI、runtime behavior、generated artifactを変更しない;
- target file、current problem、change purpose、intended change summaryをユーザーへ事前提示し、ユーザーの明示的な許可を得ている;
- 文面修正だけでなく、新しいproduct / UX / architecture / engineering / operational ruleを決定する変更も、この明示的なplanのscope内であれば対象にできる;
- latest remote repository、current management/spec state、関連するpolicy ownerを確認してから編集する;
- verificationがdocumentation/policy consistencyを確認するread-only / focused checkで足り、source-code implementation-side test-debug loopを必要としない;
- scopeがdocumentation / specification / policy workからsource-code implementationへmaterially拡大しない。

この例外ではimplementation lane、Base checkpoint、Luna sessionを要求しない。ChatGPTが編集、必要なfocused verification、blocking review、commit / push / merge、Linear synchronizationまで担当してよい。

ユーザーの許可なしに新しいrepository policy / product ruleをChatGPT判断だけで直接commitしてはならない。許可済みplanの意味上のscopeを越える場合はwrite前にplanを更新して再承認を得る。

途中でsource code / test / generated outputの変更、broad implementation-side debugging、または許可済みplanを越える変更が必要になった場合は例外を解除し、通常のLuna xhigh lifecycleへ戻す。

### Narrow CI/tooling direct execution exception

CI / repository tooling / automation workのうち、product implementationから独立した**狭く一意なCI/tooling-only変更**は、source-code implementationとは別のexecution classとする。

次の条件をすべて満たすTaskは、Luna xhighを使わずChatGPTが直接実行してよい。

- targetがCI workflow / CI config、repository-only automation / tooling、またはrepository checkの狭い配線変更に限定される;
- product source implementation、runtime semantics、DSL semantics、fixtures、generated artifacts、product build output / packaging semanticsを変更しない;
- latest remote repositoryからintended changeが一意に決まり、implementation scopeが狭い;
- target file、current problem、change purpose、intended change summaryをユーザーへ事前提示し、ユーザーの明示的な許可を得ている;
- verificationがread-onlyまたはfocusedなCI/tooling checkで完結し、broad test-debug loopを必要としない;
- Manual E2Eを必要としない;
- conflict resolution、integration-heavy work、またはambiguous failure diagnosisを必要としない。

典型例は、既存CI jobへrepository内にすでに存在するcheck commandを1 step追加するだけで、上記条件をすべて満たす変更である。

この例外ではfixed main/sub/e2e lane、Base checkpoint、Luna sessionをclaimしない。ChatGPTがbranch、edit、focused verification、blocking review、commit / push、PR、merge、relevant work-management synchronizationまで担当してよい。

write直前にlatest remote SHAとtarget file freshnessを再確認する。freshness driftによってintended change、scope、またはverification routeが一意でなくなった場合はwriteせず再評価する。

途中でproduct source / runtime behavior / DSL semantics側の変更、broad debugging、conflict resolution、integration-heavy work、またはその他の除外scopeが必要になった場合はdirect executionを停止し、通常のLuna xhigh + fixed implementation lane lifecycleへ戻す。

このexceptionは旧 `only_chatgpt` execution model全体を復活させるものではない。

Manual E2E executorはこのpolicyではなく [`MANUAL-E2E.md`](./MANUAL-E2E.md) がauthority。

## Role boundary

ChatGPT owns:

- latest Project Context / remote repository / Linear stateの取得;
- repository / architecture / semantic owner調査;
- product / architecture / implementation contract決定;
- implementation slicingとsafe checkpoint決定;
- execution lane選択;
- Human terminal assistanceとLuna handoffの使い分け;
- Luna prompt生成;
- blocking review / merge判断;
- Linear / GitHub management;
- documentation / specification / policy direct execution exceptionとnarrow CI/tooling direct execution exceptionのplan策定、承認取得、remote edit、focused verification、review、merge判断。

Luna owns:

- current executable source-code implementation sliceの具体的implementation;
- focused / required test execution;
- implementation-side failure diagnosis and fix within the settled contract;
- branch commit / push;
- integration checkpointで必要なlatest-main integration / conflict resolution / integration fix。

Lunaへopen-ended product designやarchitecture選択を委ねない。

## Human terminal assistance vs Luna

Humanがcopy/pasteできる単純なlocal terminal operationはimplementation executorではない。

ChatGPTがlocal checkoutの観測・準備・cleanupを必要とするときは、まず[`CHECKOUTS.md`](./CHECKOUTS.md)のHuman terminal operations ruleに照らし、**mechanical / deterministicで安全条件をcommand内に固定できるならHuman terminal assistanceを優先**する。

典型例:

- checkout / branch / HEAD / status / worktree inventory;
- exact ref確認;
- safety条件が確定した単純なfetch / fast-forward / checkout;
- cleanで不要と証明済みのworktree整理;
- E2E markerやhost起動などimplementationを伴わないlocal preparation。

Human terminal assistanceを使う場合、ChatGPTはshared `human-terminal-instructions` skillに従ったcopy/paste-ready commandを生成する。

一方、次はHuman terminal assistanceへ委譲せずLuna xhighへ渡す。

- product codeのimplementation;
- blocking fix;
- code changeを伴うimplementation-side failure diagnosis;
- broad local iteration / test-debug loop;
- merge / rebase conflict resolution;
- integration checkpointのintegration fix;
- branch commit / pushを含むsource-code implementation execution。

Documentation / policy direct execution exceptionのdocumentation / policy editingと、narrow CI/tooling direct execution exceptionのCI/tooling editing / focused verification / review / mergeは、この一覧のsource-code implementationには含めない。

Default routing:

```text
ChatGPT determines the operation
-> documentation / policy direct-execution exception? YES -> ChatGPT direct execution after explicit user plan approval
-> narrow CI/tooling direct-execution exception? YES -> ChatGPT direct execution after explicit user plan approval
-> simple deterministic local operation? YES -> Human terminal assistance
-> NO / source-code implementation work -> Luna xhigh
```

Humanがterminal commandを実行したことを理由にsource-code implementation ownershipをHumanへ移さない。source-code implementation contract、lane、Base checkpoint、Luna ownershipはそのまま維持する。

## Fixed execution lanes

Source-code implementation executionは [`CHECKOUTS.md`](./CHECKOUTS.md) の2 laneだけを使う。

- `main`: `/Users/yosomi/Code/nuinuiCAD`
- `sub`: `/Users/yosomi/Code/nuinuiCAD-sub`

同時source-code implementationは最大2 track。3つ目のimplementation checkout / worktree / cloneを作らない。

Manual E2Eは`/Users/yosomi/Code/nuinuiCAD-e2e`専用で、source-code implementationへ転用しない。

Documentation / policy direct execution exceptionとnarrow CI/tooling direct execution exceptionでは、これらのimplementation laneをclaimしない。

### Codex project / initial cwd is not lane ownership

CodexのProject root、Luna processのinitial working directory、またはsession開始時の`pwd`はimplementation laneを定義しない。

implementation laneのauthorityは、ChatGPTがcurrent sliceへ割り当ててLinear checkpointへ記録したfixed checkout pathである。

- `main` laneなら`/Users/yosomi/Code/nuinuiCAD`;
- `sub` laneなら`/Users/yosomi/Code/nuinuiCAD-sub`。

Lunaは別のcwdから開始してよい。Git safety check、repository file read、test、edit、commit、pushを行う前に、assigned fixed checkoutを明示的にtargetし、そのcheckoutへ移動するか`git -C <assigned-checkout>`で検証する。

session開始時の`pwd`がassigned laneと違うことだけを理由に`LANE_MISMATCH`として停止してはならない。`LANE_MISMATCH`は、assigned checkoutをtargetした後にrepository identity / branch / HEAD / clean state等のrequired lane conditionが一致しない場合だけ使う。

sub laneを使うために別Codex Project、別VS Code window、4つ目のcheckout/worktreeを作る必要はない。同じCodex Projectからfixed sub checkoutをtargetしてよい。

ChatGPTがLuna promptを生成するときは、initial `pwd`一致をpreconditionにせず、`assigned checkoutをtargetする -> そのcheckoutでbranch / HEAD / clean / remote stateを検証する`順序で書く。

## Base checkpoint semantics

新しいsource-code implementation sliceをlaneへ載せる直前にChatGPTがlatest remote stateを確認し、**Base checkpoint SHA**を固定する。

Documentation / policy direct execution exceptionとnarrow CI/tooling direct execution exceptionには、このBase checkpoint requirementを適用しない。ただしwrite直前にlatest remote SHA、対象fileのfreshness、許可済みplanとのscope一致を確認する。

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

current source-code sliceの実装とfocused verificationが完了し、remoteへ保存された時点でlatest remote `main`を再確認する。

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
- complete current-run handoff identity: Branch, Base, Claim, Checkpoint, Current remote main, Topic remote mode, exact handoff command, and exact recovery command for exact-mode continuation;
- concrete change owner / files / symbols / API boundary;
- settled acceptance;
- required verification;
- explicit non-goals;
- blocking / stop conditions。

Lunaへrepository全体のarchitecture探索やscope決定を依頼しない。

## Luna prompt contract

Promptにはcurrent executable source-code sliceだけを書く。

必須:

- repository
- lane checkout path
- expected current lane branch / HEAD / Base checkpoint
- current-run Execution Envelope with Branch / Base / Claim / Checkpoint / Current remote main / Topic remote mode
- exact prefilled handoff command and, for `exact` mode, exact prefilled recovery command
- current slice / change target
- concrete required changes
- required tests / verification
- commit / push requirement
- no-mid-slice-main-sync rule
- blocking conditions

Luna start時の`git fetch origin --prune`はrace検出に使ってよいが、active sliceのbaseを自動更新する指示にはしない。

Promptのstartup sequenceでは、Luna processのinitial cwdをlane validationに使わない。assigned lane checkoutを先にtargetし、そのcheckout上でrepository identity、branch、HEAD、clean state、remote stateを検証する。

Expected lane stateが違う、dirty workがある、ownership不明、Base checkpointから勝手に進んでいる等の場合は、下記 `Luna startup handoff gate` が明示する exact pushed-checkpoint `claimed branch mismatch` recoveryだけを例外とし、それ以外は変更せず停止して報告させる。

### Luna startup handoff gate

Repository operation前に、Lunaはcurrent-run Execution Envelopeからsupplied exact handoff commandをargument変更なしで実行する。

```text
handoff succeeds
-> continue

handoff exits nonzero and first output line exactly
BLOCKED: handoff claimed branch mismatch
and Topic remote mode = exact
-> execute the supplied exact recovery command once
-> require the canonical IMPLEMENTATION RESUMED envelope
-> rerun the supplied original handoff command unchanged
-> require HANDOFF VERIFIED
-> continue

anything else
-> stop
```

The recovery command is the prefilled same-generation `nuinui resume` command. Luna must not infer or regenerate Issue, lane, Branch, Base, Claim, Checkpoint, Current remote main, handoff command, or recovery command from retained session context or repository history. `CALLER_EXPECTED` / `ACTUAL` output never authorizes identity substitution. A failed or ambiguous resume, or a failed second handoff, is a hard-stop with no retry. The existing stale-context, dirty-state, ownership, and remote-mismatch hard-stop rules remain unchanged; `absent` mode is not eligible for this exception.

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

Documentation / policy direct execution exceptionではlane / Base checkpointは記録せず、代わりに対象file、latest remote file SHA、commit SHA、verification outcome、remaining acceptanceをLinearへ記録する。

次conversationはlatest Project Context、remote repository、Linearから再構成する。
