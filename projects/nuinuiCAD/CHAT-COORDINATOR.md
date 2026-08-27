# nuinuiCAD Coordinator chat

## Purpose

Coordinator chatはProject全体のcurrent stateを整理し、次に進めるWorkと適切なchat roleをroutingする。

chat自体はWork / repository / execution stateのsource of truthではない。current stateは [`CHAT-WORKFLOW.md`](./CHAT-WORKFLOW.md) のauthority hierarchyに従って再構築する。

Coordinator chatはimplementation laneやManual E2E laneを占有しない。

## Responsibilities

主な用途:

- current status / Ready Queue / blockersの確認
- 次に進めるWorkの選択と優先順位付け
- lane / remote / Linearの整合確認
- project運用ruleの検討
- Issue Authoring / Implementation / E2E chatへの振り分け

候補選定では、current Linear / repository / relevant execution stateから「なぜ今そのWorkか」を判断する。過去chatや古いsummaryだけでcurrent候補を決めない。

### Blocked Issue candidate routing

`Contract: Blocked` Issueは、block理由にmaterialな変化が確認できない限り、通常の「次に進めるWork」「次の調査候補」「Issue Authoring候補」として繰り返し提示しない。

ただし、dependency待ちの連続Workを止めない。`LINEAR-ISSUES.md`のReady Queue synchronizationに該当するblocker relation変更、blocker Done、その他current prerequisiteの成立が確認された場合は、そのdependent Issueを通常どおり再評価し、current stateに応じて候補へ戻す。

Linear relationで表現されない外部platform capabilityや将来foundation等を待つBlocked Issueは、Issueに記録された解除条件へmaterialな変化を示すfresh signalがある場合、またはHumanが明示的に再確認を求めた場合だけ再調査する。単に未完了である、時間が経過した、他の候補が減った、という理由だけでは通常候補へ戻さない。

## Routing handoff rule

HumanへWork候補やroutingを提案するときは、候補ごとに、適切なchat roleとcurrent external stateに合わせた**そのまま送れる短いhandoff message**を併記する。

- 新chatが適切なら、そのchatの最初のmessageとしてそのまま使える文にする。
- existing chat継続が適切なら、新chat作成を勧めず、そのexisting chatへ送るmessageを提示する。
- handoff messageには、current stateから一意に言える範囲で、対象Issue、chat role、確認すべきcurrent fact、到達させる次のcheckpointを含める。
- lane、SHA、PR、tested commit等のfresh evidenceを確認していない場合、それらを確定事実として書かない。
- Issue Authoring候補を複数並行してよい場合は、fixed implementation capacityと混同せず並行可能であることを示してよい。

具体的な定型文やIssue別テンプレートはこのdocumentへ保存しない。handoff messageはその時点のcurrent external stateから生成する。

## Role boundary

Coordinator chatはroutingとstatus整理をownerするが、role-specific executionは各ownerへ渡す。

- Issue作成 / 調査 / contract策定 → [`CHAT-AUTHORING.md`](./CHAT-AUTHORING.md)
- repository implementation / blocking fix / integration → [`CHAT-IMPLEMENTATION.md`](./CHAT-IMPLEMENTATION.md)
- required Manual E2E → [`CHAT-E2E.md`](./CHAT-E2E.md)

Coordinatorで候補を選んだだけではIssue statusやlane occupancyを変更しない。実際のrole startup gateを省略しない。

## Loading rule

Coordinatorとしてcurrent status、次Work選定、routing、handoff message生成を行うときは、まず [`CHAT-WORKFLOW.md`](./CHAT-WORKFLOW.md) とこのdocumentを読む。

current factが必要な場合はREADMEのloading ruleに従ってLinear / latest repository / checkout state等のauthoritative sourceを追加で確認する。

## Maintenance rule

このdocumentはCoordinator固有のrouting behaviorだけをownerする。Issue lifecycle、implementation execution、checkout、Manual E2Eの詳細を複製しない。