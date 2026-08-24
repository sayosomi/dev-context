# nuinuiCAD Implementation chat

## Purpose

Implementation chatは`Contract: Ready`なIssueのrepository implementation / blocking fix / verification / integration / blocking review / mergeを進めるchat。

実行capacityはchat数ではなく [`CHECKOUTS.md`](./CHECKOUTS.md) のfixed implementation laneで決まる。

- `main`: at most 1 implementation track
- `sub`: at most 1 implementation track
- 合計最大2 implementation track

Implementation chatを新しく作っただけではlaneをclaimしない。実際のstartup gate / lane assignment / Base checkpoint記録が完了した時点でexecutionが開始する。

repository implementation / blocking fixは [`CODING-AGENT.md`](./CODING-AGENT.md) に従いLuna xhighが担当する。

## Implementation start / resume completion rule

Humanがimplementation Issueについて`開始` / `再開` / `続ける` / `進める`等を指示した場合、ChatGPTはremote / Linear / policyの再確認やblocker説明だけで停止しない。

その応答は、次のどちらかに到達して初めてstart / resume handoffとして完了する。

1. ChatGPT側で次のexecutionを実際に開始できる状態まで進み、必要なlane assignment / checkpoint / Luna handoffを開始する。
2. Human actionが必要なら、Humanが**その応答から直ちに実行できる最初の完全なhandoff**を同じ応答内に提示する。

Human action待ちになる場合の原則:

- `Xの出力待ち`、`preflight結果待ち`、`上のaudit結果待ち`等とだけ述べて停止しない。
- そのXを取得するためのcommand / instructionが必要なら、同じ応答内に完全な形で提示する。
- 実際には提示していないcommand / blockを`上のcommand`、`先ほどのaudit`等として参照しない。
- concrete blockerを報告するときは、blockerの説明と**解除するための次のaction**をセットで出す。
- local lane evidence不足が唯一のblockerなら、[`CHECKOUTS.md`](./CHECKOUTS.md) のmandatory preflight handoff ruleに従い、その場で最初の実行可能なread-only handoffまで出す。
- Humanが必要なfresh evidenceをすでに現在の会話で提示している場合は、同じ取得手順を機械的に要求し直さない。

product / UX decision、approval-gated dev-context write、unsafe / destructive unknown-state recoveryなど、Human判断そのものが必要なboundaryはこのruleで自動決定しない。その場合も「何を判断 / 実行すれば先へ進めるか」を具体化して返す。

## Implementation continuation completion rule

HumanがLuna implementation / integration checkpoint等の結果を返した後、残る作業がChatGPTから直接扱えるremote / management stateだけで完結する場合、その工程をHumanへの細かなhandoffへ分割しない。

典型的なremote-only continuation:

```text
Luna result
-> pushed HEAD / latest main freshness
-> fresh CI completion
-> blocking review
-> merge
-> merged-state verification
-> Linear synchronization
```

原則:

- fresh CIが`queued` / `in_progress`でも、それ自体を理由に`CI結果をまた返してください`等のHuman actionへ変換しない。ChatGPTが同じexecution trackでremote stateを追跡し、PASS / FAIL / concrete blockerまで進める。
- progress updateは出してよいが、Humanが何もする必要のないremote-only intermediate stateをconversation handoff boundaryにしない。
- blocking reviewに必要なGitHub diff / code / review thread / CI evidenceをChatGPTが取得できるならHumanに再取得させない。
- safe merge authorizationが既にcurrent execution trackへ与えられている場合、通常のmerge confirmationを再要求しない。merge gateは`LINEAR-GITHUB.md`に従う。
- merge後のGitHub / Linear synchronizationも、Human-only actionがなければ同じcontinuationで完了する。

Humanへ戻してよいのは、product / UX / scope decision、unsafe local state、destructive operation、Human-only environment / observation、required approval boundary、またはcurrent toolsでは解消できないconcrete blocker等、**Human actionが実際に必要な場合だけ**。

local checkoutのdeterministic releaseだけが残る場合は、Work completion / Linear statusと物理lane cleanupを混同しない。lane stateは`CHECKOUTS.md`、Issue statusは`LINEAR-ISSUES.md` / `LINEAR-GITHUB.md`をauthorityとする。

## Startup / execution boundary

Implementation開始・再開では、READMEのloading ruleに従ってcurrent Linear / remote repository / required implementation policiesを確認する。

local executionが必要なら[`CHECKOUTS.md`](./CHECKOUTS.md)の3-lane preflightとstartup gateを使う。slice / Base checkpoint / integration checkpointは[`IMPLEMENTATION-SLICING.md`](./IMPLEMENTATION-SLICING.md)をauthorityとする。

ChatGPT web環境からfixed checkoutへ直接アクセスできないことを理由に、代替clone / fourth worktree / direct-GitHub implementationへ迂回しない。必要なHuman handoffは上記completion ruleに従って同じ応答内に提示する。

## Chat rotation

Implementation chatのrotation自体はTask pauseではない。status、lane ownership、Base checkpoint、branch、current sliceをrotationだけで変更しない。

Work自体をpause / releaseする場合だけ`LINEAR-ISSUES.md` / `CHECKOUTS.md` / `IMPLEMENTATION-SLICING.md`の該当ruleを使う。

## Loading rule

Implementation chatでは [`CHAT-WORKFLOW.md`](./CHAT-WORKFLOW.md) とこのdocumentを読み、READMEのimplementation loading ruleに従う。

## Maintenance rule

このdocumentはImplementation chat固有のstart / resume / continuation / handoff lifecycleだけをownerする。checkout操作、slice semantics、Coding Agent detail、Linear lifecycleは各owner documentを参照し、ここへ複製しない。