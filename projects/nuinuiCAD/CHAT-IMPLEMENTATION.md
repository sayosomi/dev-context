# nuinuiCAD Implementation chat

## Purpose

Implementation chatは`Contract: Ready`なIssueのrepository implementation / blocking fix / verification / integration / blocking review / mergeを進めるchat。

実行capacityはchat数ではなく[`CHECKOUTS.md`](./CHECKOUTS.md)のfixed implementation laneで決まる。

- `main`: at most 1 implementation track
- `sub`: at most 1 implementation track
- 合計最大2 implementation track

chatを新しく作っただけではlaneをclaimしない。actual startup gate / lane assignment / Base checkpoint / durable claimが成立した時点でexecutionが開始する。

通常のrepository implementation / blocking fixは[`CODING-AGENT.md`](./CODING-AGENT.md)に従いLuna xhighが担当する。

## Documentation / policy direct execution exception

Repository-owned documentation / specification / policy workはsource-code implementationとは別execution classとする。

次をすべて満たすTaskはimplementation lane / Lunaを使わずChatGPTが直接実行してよい。

- targetが`docs/**`、`AGENTS.md`、repository/project `README.md`、`ARCHITECTURE.md`、CHANGELOG等のdocumentation / specification / policy fileに限定される;
- source code、test code、fixtures、build設定、CI、runtime behavior、generated artifactを変更しない;
- plan、target file、intended changeをユーザーへ事前提示し明示許可を得ている;
- latest remote repositoryとcurrent relevant management/spec stateを確認してから編集する;
- verificationはdocumentation / policy consistencyのfocused read-only checkで足りる;
- scopeがsource-code implementationへmaterially拡大しない。

この例外ではfixed main/sub lane、Base checkpoint、Luna sessionをclaimしない。途中でsource/test/runtime changeが必要になったら停止しplanを更新し、必要なら通常lifecycleへ戻す。

Manual E2Eは[`MANUAL-E2E.md`](./MANUAL-E2E.md) / [`CHAT-E2E.md`](./CHAT-E2E.md)をauthorityとする。

## Implementation start / resume completion rule

Humanがimplementation Issueについて開始 / 再開 / 続行を指示した場合、remote / Linear / policyの再確認やblocker説明だけで停止しない。

その応答は次のどちらかへ到達して完了する。

1. ChatGPT側でactual execution開始まで進み、必要なlane assignment / checkpoint / Luna handoffを開始する。
2. Human actionが必要なら、その応答から直ちに実行できる最初の完全なhandoffを提示する。

Human action待ちになる場合:

- `preflight結果待ち`等だけで停止しない;
- 必要command / instructionを同じ応答に完全な形で出す;
- concrete blockerには解除のnext actionを添える;
- local evidence不足が唯一のblockerなら[`CHECKOUTS.md`](./CHECKOUTS.md)のpreflight diagnostic / routing ruleを使う;
- current helperが使えるなら[`LOCAL-TOOLS.md`](./LOCAL-TOOLS.md)のexact invocationを使う;
- Humanがfresh evidenceを現在conversationで提示済みなら機械的に再取得させない。

### Local-success-before-In-Progress rule

Linear `In Progress`は「開始予定」ではなくactual implementation laneでexecution開始済みを表す。

Human terminal handoffでcanonical `nuinui begin`またはexplicit low-level `nuinui start` / `nuinui resume`を使う場合:

1. fresh remote / Linear current implementation `In Progress`集合をIssue identity単位で照合し、target FREE lane、Base、branch、exact peer expectationを決める。
2. known-Issueの通常startupでは別Human `preflight`を要求せず、`begin`を1つ提示する。
3. `begin`のfull local auditとsuccessful `IMPLEMENTATION STARTED` envelopeが返り、lane / Issue / branch / Base / checkpoint / claimがintended handoffと一致した後で`In Progress`へ変更する。低レベル`start`を使う場合も、そのlocal envelopeを確認する。
4. 同じcontinuationで`Implementation checkpoint`を記録し、[`LINEAR-ISSUES.md`](./LINEAR-ISSUES.md)に従いread-backする。

start / resume後のidentity invariantは、physical BUSYなmain/subから読めるIssue集合とLinear current implementation `In Progress`集合が一致すること。件数<=2だけでは十分ではない。

same active durable generationのcontinuationでは、Luna session変更、blocking reviewからblocking fix、implementationからintegration、remote `main` advance、またはChatGPT chat rotationだけを理由にHuman 3-lane preflightへ戻さない。current Linear checkpoint / last verified envelopeのclaimとcheckpointをcaller expectationとして`nuinui-handoff-check`へ渡し、actual local durable stateとのmatchをその場で検証する。

product / UX decision、approval-gated dev-context write、unsafe/destructive unknown-state recovery等のHuman判断boundaryは自動決定しない。その場合も必要な判断/actionを具体化する。

## Implementation continuation completion rule

Luna implementation / integration result後、残作業がChatGPTから直接扱えるremote / management stateだけならHumanへの細かなhandoffへ分割しない。

典型:

```text
Luna result
-> pushed HEAD / latest main freshness
-> blocking review
-> [Auto-merge: exact-head reservation -> task ends without CI wait]
   or
   [manual merge: fresh CI -> merge -> merged-state verification -> Linear synchronization]
```

Auto-mergeのprecondition / CI failure terminal stop / manual merge continuationは[`LINEAR-GITHUB.md`](./LINEAR-GITHUB.md)をauthorityとする。Humanに何もする必要がないremote-only intermediate stateをhandoff boundaryにしない。

Humanへ戻してよいのはproduct / UX / scope decision、unsafe local state、destructive operation、Human-only observation、required approval boundary、またはcurrent toolsで解消できないconcrete blocker等、Human actionが実際に必要な場合だけ。

local deterministic releaseだけが残る場合はWork completion / Linear statusとphysical lane cleanupを混同しない。

## Final closure declaration rule

Issue `Done`とimplementation laneを含むexecution lifecycle final closureを区別する。

main/subを使用したWorkで「完全終了」「追加作業なし」と宣言してよいのは:

1. Work completion / Issue status synchronization完了;
2. [`CHECKOUTS.md`](./CHECKOUTS.md)に従うlane release成功、actual lane FREE;
3. current Linear Issueへ`Lane release checkpoint`記録;
4. [`LINEAR-ISSUES.md`](./LINEAR-ISSUES.md)のPost-write verification完了。

Human boundaryは次の1回だけにする。

```text
merge / Work completion
-> exact nuinui release command
-> complete IMPLEMENTATION RELEASED envelope
-> Lane release checkpointの記録 / read-back
-> final closure
```

Humanからfresh successful release outputが返った場合はactual local evidenceとして扱い、Linear操作可能なら同じcontinuationでrelease checkpoint記録とread-backまで進める。complete `IMPLEMENTATION RELEASED` envelopeのためだけに別preflightを要求しない。

IssueがDoneでもrelease / release checkpoint / read-backが残る場合はfinal closure未完了として報告する。Linear write失敗でsuccessful physical releaseを巻き戻さない。

## Startup / execution boundary

Implementation開始・再開ではREADME loading ruleに従いcurrent Linear / remote repository / required implementation policyを確認する。

source-code implementationは[`CHECKOUTS.md`](./CHECKOUTS.md)の`begin` full-audit startup gateとdiagnostic preflight rule、slice / Base / integrationは[`IMPLEMENTATION-SLICING.md`](./IMPLEMENTATION-SLICING.md)をauthorityとする。

Documentation / policy direct execution exceptionではimplementation lane claim / Baseは不要だが、write直前にlatest target file SHA、current relevant state、approved plan scopeを再確認する。

web環境からfixed checkoutへ直接accessできないことを理由に代替clone / fourth worktree / direct-GitHub source implementationへ迂回しない。

## Chat rotation

Implementation chat rotation自体はTask pauseではない。rotationだけを理由にstatus、lane ownership、Base、branch、claim、current sliceを変更しない。

Work自体をpause / releaseする場合だけ[`LINEAR-ISSUES.md`](./LINEAR-ISSUES.md) / [`CHECKOUTS.md`](./CHECKOUTS.md) / [`IMPLEMENTATION-SLICING.md`](./IMPLEMENTATION-SLICING.md)のruleを使う。

## Loading rule

Implementation chatでは[`CHAT-WORKFLOW.md`](./CHAT-WORKFLOW.md)とこのdocumentを読み、READMEのimplementation loading ruleに従う。

## Durable ownership handoff

main/sub ownershipはGit-local durable claimで保持する。checkout branchだけからownershipを推測しない。state machine / recoveryは[`CHECKOUTS.md`](./CHECKOUTS.md)、CLIは[`LOCAL-TOOLS.md`](./LOCAL-TOOLS.md)、Luna handoffのfresh execution identity検証は[`EXECUTION-HANDOFF.md`](./EXECUTION-HANDOFF.md)をauthorityとする。

new `nuinui begin`成功outputの`claim=<generation token>`を、`In Progress` transitionと同じcontinuationで`Implementation checkpoint`へ保存する。低レベル`start`を明示的に使った場合も同じく保存する。checkpoint-pause / chat rotation / handoffでもclaimを落とさない。

`resume` handoffはLane、Issue、fixed Base、exact pushed checkpoint、branch、claimをcurrent external stateから復元してhelperへ渡す。Baseをancestryから推測し直したり、local slot claimをcaller expectationの代わりに採用しない。

`release` handoffはexact saved / integration checkpointとclaimを使う。claimless legacy signatureへfallbackしない。

preflightがslot / checkout mismatch、mutation lock、releasing tombstone、uninitialized ownership schema、malformed metadata等をBLOCKEDとして返した場合、laneをFREEと推測しない。known crash stateだけexplicit `nuinui recover`で復旧し、reset / stash / force-switchによる一般repairへ変換しない。

chat rotation / external-state recovery後にLuna handoffを生成するときはpast chatのclaimをauthorityにせず、fresh local durable evidenceからcurrent claimを読み直す。

## Maintenance rule

このdocumentはImplementation chat固有のstart / resume / continuation / handoff lifecycleだけをownerする。checkout state machine、slice semantics、Coding Agent detail、Linear lifecycleは各owner documentへ委譲する。
