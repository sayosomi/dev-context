# nuinuiCAD Chat workflow

## Purpose and authority

ChatGPT ProjectのchatはWork / repository / execution stateと独立した作業UIであり、source of truthではない。
同じIssueを複数chatで扱ってよく、chatが重い・不正確・不要になればWorkの途中でもrotationできる。
過去chatやそのsummaryをcurrent stateのauthorityにしない。

Current stateは責務ごとの外部authorityから再構築する。

- **Work / contract / decisions:** current GitHub Issue bodyとmaterial comments。[ISSUES.md](./ISSUES.md)がWork lifecycle、[CONTRACT-DECISIONS.md](./CONTRACT-DECISIONS.md)がIssue boundary、[IMPLEMENTATION-SLICING.md](./IMPLEMENTATION-SLICING.md)がsliceをownerする。
- **Implementation / review:** latest remote `sayosomi/nuinuiCAD` repository、branch、commit、PR、checks、authoritative merge read-back。
- **Policy:** latest `sayosomi/dev-context` の[README.md](./README.md)と適用されるowner documents。
- **Execution / occupancy:** actual declared checkout state、current Issue/checkpoints、該当するlegacy ownership。GitHub commentsはoperational checkpointでありmachine lockではない。物理capacity / admission / recoveryは[LANES.conf](./LANES.conf)、[CHECKOUTS.md](./CHECKOUTS.md)と各role ownerが定める。

## Chat roles and Work identity

Chat roleは会話の分類であり、Issue status、claim、physical admission、lane occupancyではない。

| Role | Purpose | Owner |
| --- | --- | --- |
| Coordinator | Current Workの選択・優先順位・routing | [CHAT-COORDINATOR.md](./CHAT-COORDINATOR.md) |
| Issue Authoring | 調査、Issue / contract / dependency整理 | [CHAT-AUTHORING.md](./CHAT-AUTHORING.md) |
| Implementation | 実装・修正・検証・review / merge | [CHAT-IMPLEMENTATION.md](./CHAT-IMPLEMENTATION.md) |

`1 Issue = 1 chat`は要求しない。
同じIssueを複数chatで続けても、新chatを作っただけではWorkや実行状態は変化しない。
Human Manual E2Eは専用chat roleを設けず、[MANUAL-E2E.md](./MANUAL-E2E.md)へrouteする。

CoordinatorとIssue Authoringの非実行活動はchat数によるexecution capacity制限を受けない。
一方、実行には独立したphysical admissionが必要である。
**新しいGitHub-native D1は登録済み単一implementation checkoutによるsequential Git-only実行**である。
旧SAY laneの`FREE` / `preflight`、chat増設、別agentは追加のnative実装や並列実行の許可にならない。
D2-C evaluator auditはread-only、Manual E2EはHuman-onlyであり、既存の相互排他を維持する。
新lane・worktree・parallel scheduling routeを追加しない。

## Rotation

Humanは理由を示さず、Work途中でもnormal / emergency rotationを選べる。
rotationそれ自体にcheckpoint、Task pause、release、追加のadmissionは不要。

### Normal rotation

旧chatが信頼できるなら、ChatGPTは**外部stateから復元できない重要情報だけ**を必要に応じて外部化する。
例は未記録のHuman E2E observation / result、product / UX decision、唯一のscreenshot / evidence参照、既存SAY generationの未保存checkpointである。
GitHub / dev-contextから再取得できる情報を長いhandoff summaryとして複製しない。

```text
このチャット重い。checkpointして切り替える
```

### Emergency rotation

旧chatを信頼できないときはcheckpointなしで破棄してよい。
保存されていないchat-only observation / decisionは失われ得るため、必要ならHumanに再確認する。

```text
GitHub Issue #123を外部状態から復元して続ける。前チャットは信用しない
```

## Fresh recovery in a new chat

過去chatのsummaryで現在の状態を決めず、必要な範囲で次をfreshに確認する。

1. [README.md](./README.md)と該当するcurrent dev-context policy / role owner。
2. Current GitHub Issue body、material comments、related Issues / decisions / checkpoints。
3. Latest authoritative product repository、branch、PR / checks / merge evidence。
4. **実行・再開が関係する場合だけ**、[CHECKOUTS.md](./CHECKOUTS.md)と実際のphysical checkout / occupancy、必要な既存SAY checkpoint。

未完了のD2-C audit start / stop / independent final checkout proof、active / ambiguous implementation・Human E2E・legacy claim / ownership、dirty / unknown checkoutをchat切替や失われたterminal outputで無視しない。
証拠不足・不一致は当該実行の開始 / 継続をfail closedし、canonical ownerで診断する。
新しいチャットでHumanのsingle `nuinui-checkout-check`やAgentの変更直前のbounded recheckを重複実行させず、必要な新規admissionは[EXECUTION-HANDOFF.md](./EXECUTION-HANDOFF.md)と[CHECKOUTS.md](./CHECKOUTS.md)へ委譲する。

再開の指示は`GitHub Issue #123を続ける`程度でよい。

## Rotation is not a Task pause

Chat rotationだけではIssue / Linear status、execution ownership / claim、implementation / Human E2E checkout占有・release、Base / SHA、branch、active slice、tested commit、E2E generation / stateを変更しない。
実際にWorkをpause / releaseする場合は、適用される既存ownerの独立した手順に従う。
既存SAYのpause / releaseのみ[LINEAR-ISSUES.md](./LINEAR-ISSUES.md)と[CHECKOUTS.md](./CHECKOUTS.md)の互換契約を使う。

## Role handoff and legacy compatibility

通常のroutingはHumanの相談 → Issue AuthoringによるGitHub contract整理 → CoordinatorのWork選択 → [CHAT-IMPLEMENTATION.md](./CHAT-IMPLEMENTATION.md)のnative D1 route、必要ならHuman-only [Manual E2E](./MANUAL-E2E.md)である。
各destination roleの既存startup gateを省略しない。
role変更のために新chatは不要であり、routingだけでは実行をadmitしない。

**既にadmitされた未完了SAY generationだけ**は別の互換経路に留める。
元のSAY Issue / generation identity、claim、lane、Base、checkpoint、minimum Linear status / release checkpointsを維持し、native Issueへ移行したり新しいSAY Workを開始したりしない。
既存SAYのimplementation完了後は、正確なreleaseと`IMPLEMENTATION RELEASED` / Lane release checkpointの確認を**legacy E2E startより前**に行う。
Human-test checkoutがBUSYでも完了したimplementation claimを保持せず、必要なlegacy `In Review` checkpointで待つ。
曖昧なownerや未完了releaseはfail closedする。

既存SAYの詳細なhandoff / release / recoveryは[EXECUTION-HANDOFF.md](./EXECUTION-HANDOFF.md)、[CHAT-IMPLEMENTATION.md](./CHAT-IMPLEMENTATION.md)、[CHECKOUTS.md](./CHECKOUTS.md)、[LOCAL-TOOLS.md](./LOCAL-TOOLS.md)、[LINEAR-ISSUES.md](./LINEAR-ISSUES.md)がownerする。
旧multi-lane / release→E2Eの全文が必要な場合だけ[変更前のimmutable CHAT-WORKFLOW.md](https://github.com/sayosomi/dev-context/blob/0671ef4150cc75d882e25d0a4867dde6100af14f/projects/nuinuiCAD/CHAT-WORKFLOW.md)を歴史資料として参照する。
これは新規native admissionを許可しない。

旧SAYのmutationでterminal outputが失われた場合、最初にread-only `nuinui last-result` と実checkout・GitHub・最低限のLinear checkpointを照合する。
記録や結果が欠落・不一致・不完全ならmutationをblind retryせず、対応するlegacy ownerのexact recoveryへrouteする。
この復旧手順をGitHub-native D1へ流用しない。

## Loading and maintenance

Chat role選択、rotation、handoff、external-state recoveryでは`README.md → CHAT-WORKFLOW.md → applicable role owner`の経路を使い、さらにtask / phaseに必要なownerだけを読む。
Coordinatorは[CHAT-COORDINATOR.md](./CHAT-COORDINATOR.md)、Authoringは[CHAT-AUTHORING.md](./CHAT-AUTHORING.md)、Implementationは[CHAT-IMPLEMENTATION.md](./CHAT-IMPLEMENTATION.md)、Human E2Eは[MANUAL-E2E.md](./MANUAL-E2E.md)と必要なhost / checkout ownersへrouteする。

この文書はchat共通lifecycleのみをownerする。
Issue契約、role固有の実装、physical admission / occupancy、audit、Manual E2E、legacyコマンドの詳細を複製しない。
