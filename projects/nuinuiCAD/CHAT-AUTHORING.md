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

- execution laneをclaimしない。
- implementation branch / worktreeを作らない。
- product code implementation / blocking fixを開始しない。
- Readyになっただけでは`In Progress`へ進めない。
- implementation待ちのReady Workは原則`Todo`に置く。

Issue contractの判断詳細は [`CONTRACT-DECISIONS.md`](./CONTRACT-DECISIONS.md)、Linear lifecycleは [`LINEAR-ISSUES.md`](./LINEAR-ISSUES.md) をauthorityとする。

## Parallel Authoring

**Issue Authoring chatの同時実行数に上限を設けない。**

複数IssueのAuthoringを別chatで並行してよい。これはdeclared implementation capacityとは無関係であり、lane capacityを増やす意味ではない。

同じIssueを複数Authoring chatが扱うことも禁止しない。ただしLinear write前にcurrent Issue / relevant commentsを再取得し、別chatの新しい変更を失わないこと。競合するproduct decisionをlast-write-winsで上書きしない。一意に統合できない場合はHumanへ判断を戻す。

## Linear write safety

1. write直前にtarget Issue / relevant current commentsを取得する。
2. 自分のchat開始時点より新しい変更があれば意味を確認する。
3. independentな追加は統合する。
4. descriptionを更新する場合、別chatのcurrent decision / acceptanceを消さない。
5. incompatibleなproduct decision、scope、acceptance変更が競合した場合は勝手に上書きしない。
6. write後は`LINEAR-ISSUES.md`のpost-write verificationに従う。

細かなchat transcriptや議論履歴をLinearへ複製しない。current Work state / decision / checkpointだけを残す。

## Interactive Decision Mock

Human判断が必要なreal UX branchについて、文章だけのA/B質問より**触って比較した方が判断品質が高い**場合は、Issue AuthoringでInteractive Decision Mockを優先してよい。

Humanは例えば次のように指定できる。

```text
このIssue、Interactive Decision Mock方式で詰めて
```

典型的に向いている判断:

- placement / panel split / toolbar placement
- information density / row height / card-vs-table
- hierarchy / grouping / disclosure
- visual emphasis / cue placement / detail hierarchy
- hover / focus / selection / context menu interaction
- keyboard interaction / tab behavior
- resize / narrow-width behavior
- 複数の独立したUX branchを組み合わせて比較したい場合

次をすべて満たすときに使う。

1. latest authorityを確認しても複数の合理的なuser-facing UX選択肢が残る。
2. 選択差が見た目・空間・操作感として体験可能で、hands-on比較に意味がある。
3. fake / static fixture dataを使ってproduction semanticsから安全に分離できる。

### Authoring workflow

1. latest repository / spec / Linearから一意に決まる事項を先に除外する。
2. Human判断が必要なUX branchだけを独立した比較軸として整理する。
3. disposableなinteractive mockを作り、必要なbranchをtoggle / selectable variantとして触れる状態にする。
4. 判断に関係する場合はclick、keyboard、scroll、resize、themeなども近似する。
5. mockがbrowser approximation等でtarget hostそのものではない場合は、その差を明示する。
6. Humanが触って選択した結果だけをcurrent product decisionとしてLinear Issue / Commentへ記録する。
7. 選択結果をacceptance criteria / Manual E2E planへ落とし、他のcontract条件も満たせば`Contract: Ready`へ進める。

mockそのものはproduction implementationでもdurable specificationでもない。mock内の表示、fixture、仮interactionは、Humanが選択しcurrent contractへ記録されるまではproduct decisionのauthorityにしない。

### Boundary

Interactive Decision Mockで決めないもの:

- DSL / document / persistence semantics
- runtime evaluation / diagnosticsの意味
- canonical data ownership / source of truth
- architecture / host lifecycle / production transport
- compatibility / migration semantics
- current authorityから一意に決まる既存behavior

これらはrepository / normative spec / durable policy等のauthorityからcontractを決める。mock都合でproduction semanticsを発明しない。

Issue Authoringのmock作成はexecution laneをclaimするrepository implementationではない。production codeへprototypeを混ぜず、比較用artifactとして切り離す。

## Handoff to implementation

Issue / contractがReadyになっても、そのchatだけを理由にimplementationを開始しない。

Ready Workはlifecycle ruleに従って`Todo`へ同期し、implementationを開始する場合は [`CHAT-IMPLEMENTATION.md`](./CHAT-IMPLEMENTATION.md) のstartup boundaryへ渡す。

## Loading rule

Issue Authoringでは [`CHAT-WORKFLOW.md`](./CHAT-WORKFLOW.md) とこのdocumentを読み、READMEのroutingに従って少なくとも`LINEAR.md`、`LINEAR-ISSUES.md`、`CONTRACT-DECISIONS.md`とrelevant authorityを確認する。

actual implementation factを判断するときはlatest remote repositoryをauthoritativeとする。

## Maintenance rule

このdocumentはIssue Authoring固有のchat behaviorだけをownerする。Issue lifecycle semantics、contract semanticsそのもの、implementation executor、checkout、Manual E2E詳細はそれぞれのowner documentへ置く。
