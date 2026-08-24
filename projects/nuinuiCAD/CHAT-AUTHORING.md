# nuinuiCAD Issue Authoring chat

## Purpose

Issue Authoring chatはIssueを**作る / 育てる / 編集する**ためのchat。

主な用途:

- Humanが報告したBugを調査してIssue化する
- 要望 / アイデアを正式Workへ育てる
- existing Issueの仕様をHumanと相談して決める
- product / UX / compatibility / scope decisionを確定する
- latest repositoryを調査してimplementation contractを策定する
- same Issue / new Issueのboundaryを決める
- dependency / parent-child / relationを整理する
- acceptance criteria / Manual E2E planを策定する
- `Contract: Pending | Blocked`を`Ready`へ進める
- current fact driftに合わせてReady contractをrefreshする

## Execution boundary

Issue Authoringはrepository implementationではない。

- `main` / `sub` / `e2e` laneをclaimしない。
- implementation branch / worktreeを作らない。
- product code implementation / blocking fixを開始しない。
- Readyになっただけでは`In Progress`へ進めない。
- implementation待ちのReady Workは原則`Todo`に置く。

Issue contractの判断詳細は [`CONTRACT-DECISIONS.md`](./CONTRACT-DECISIONS.md)、Linear lifecycleは [`LINEAR-ISSUES.md`](./LINEAR-ISSUES.md) をauthorityとする。

## Parallel Authoring

**Issue Authoring chatの同時実行数に上限を設けない。**

複数IssueのAuthoringを別chatで並行してよい。これはfixed implementation capacityとは無関係であり、3つ目以降のimplementation trackを許可する意味ではない。

同じIssueを複数Authoring chatが扱うことも禁止しない。ただしLinear write前にcurrent Issue / relevant commentsを再取得し、別chatの新しい変更を失わないこと。競合するproduct decisionをlast-write-winsで上書きしない。一意に統合できない場合はHumanへ判断を戻す。

## Linear write safety

1. write直前にtarget Issue / relevant current commentsを取得する。
2. 自分のchat開始時点より新しい変更があれば意味を確認する。
3. independentな追加は統合する。
4. descriptionを更新する場合、別chatのcurrent decision / acceptanceを消さない。
5. incompatibleなproduct decision、scope、acceptance変更が競合した場合は勝手に上書きしない。
6. write後は`LINEAR-ISSUES.md`のpost-write verificationに従う。

細かなchat transcriptや議論履歴をLinearへ複製しない。current Work state / decision / checkpointだけを残す。

## Handoff to implementation

Issue / contractがReadyになっても、そのchatだけを理由にimplementationを開始しない。

Ready Workはlifecycle ruleに従って`Todo`へ同期し、implementationを開始する場合は [`CHAT-IMPLEMENTATION.md`](./CHAT-IMPLEMENTATION.md) のstartup boundaryへ渡す。

## Loading rule

Issue Authoringでは [`CHAT-WORKFLOW.md`](./CHAT-WORKFLOW.md) とこのdocumentを読み、READMEのroutingに従って少なくとも`LINEAR.md`、`LINEAR-ISSUES.md`、`CONTRACT-DECISIONS.md`とrelevant authorityを確認する。

actual implementation factを判断するときはlatest remote repositoryをauthoritativeとする。

## Maintenance rule

このdocumentはIssue Authoring固有のchat behaviorだけをownerする。Issue lifecycle semantics、contract semanticsそのもの、implementation executor、checkout、Manual E2E詳細はそれぞれのowner documentへ置く。