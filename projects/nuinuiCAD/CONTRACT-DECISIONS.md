# nuinuiCAD implementation contract decision rule

## Purpose

implementation contractの策定時に、platform標準挙動やnuinuiCADの既存設計原則から一意に決まる細部まで機械的にユーザー判断へ戻さない。

ChatGPTは既存authorityから決められる事項を自分でcontractへ落とし、ユーザー確認は実際にproduct / UX / future semanticsが分岐する判断へ絞る。

この文書は、追加Work / scopeをsame Issueに残すかindependent Issueへ分けるかもownerする。chat session / Issue Authoring運用は [`CHAT-WORKFLOW.md`](./CHAT-WORKFLOW.md)、PR / execution sliceの分け方は [`IMPLEMENTATION-SLICING.md`](./IMPLEMENTATION-SLICING.md) がauthority。

## Issue Authoring boundary

Issue作成、Bug調査、仕様相談、contract策定、acceptance整理、dependency / decompositionは`CHAT-WORKFLOW.md`のIssue Authoring chatで並行して行ってよい。

Issue Authoringはrepository implementationではない。

- Authoring chat数にimplementation capacity上限を適用しない。
- `main` / `sub` / `e2e` laneをclaimしない。
- contractをReadyにしただけでは`In Progress`へ進めない。
- repository implementation / blocking fixはReady後にfixed implementation laneへ割り当て、Luna xhighで実行する。

複数Authoring chatが同じIssueを扱う場合、Linear write前にcurrent Issue / relevant commentsを再取得し、別chatのcurrent decisionを失わない。競合するproduct decisionをlast-write-winsで上書きしない。

## Rule

Issueのimplementation contractを策定するとき、次のいずれかから結論が一意に決まる事項は、原則としてユーザーへA/B確認を求めず、その結論をIssue contractへ明記する。

- 対象platformの標準挙動や標準APIの自然なsemantics
- latest repositoryのactual architecture / existing implementation boundary
- `AGENTS.md`、`docs/nui4/spec.md`、その他current durable source of truthにあるnuinuiCADの既存設計原則
- 同じsurfaceで既に確立している一貫したUX / ownership rule

例:

- VS Code標準providerを使う機能で、標準provider lifecycleから一意に決まる細部
- positional argumentのactive parameterを現在のargument indexから求めるなど、既存call semanticsから一意に決まる挙動
- host-neutral language query + thin VS Code adapterという既存architecture ruleに従うowner境界
- Completionが既にcandidate selectionをownerしている場合に、別機能へ同じpickerを重複実装しないこと

## Ask the user only for real product branches

ユーザー判断を求めるのは、既存authorityを確認しても複数の合理的な選択肢が残り、選択によって次のいずれかが実際に変わる場合に限る。

- user-facing UX
- language / product semantics
- scopeまたはfeature boundary
- compatibility / migration policy
- future extensibilityを拘束するdurable choice
- user workflowや操作モデル
- acceptance criteriaそのもの

このような分岐では、選択肢ごとの差を具体例で説明してからユーザー判断を取る。

## Ready contract refresh vs Pending

`Contract: Ready`は「current repositoryのfile名やimplementation pathが永久に固定された」という意味ではない。

latest repositoryに合わせてcontractを更新するときは、次で判定する。

> 既に確定したuser-facing semantics / scope / acceptanceを変えずに、latest authorityからcontractを一意にrefreshできるか？

- **YES:** `Contract: Ready`を維持したままcurrent fact / implementation pathをrefreshする。
- **NO:** 複数の合理的なproduct / UX / scope / compatibility / acceptance選択肢が生じるなら`Contract: Pending`へ戻す。
- **実行不能なprerequisite:** viableな選択肢以前に必要なfoundation / capabilityが存在せずcontractを完成できないなら`Contract: Blocked`。

`Ready`のままrefreshしてよい代表例:

- file / symbol / owner名が変わったが責務とacceptanceは同じ
- current API shapeやfixture pathが変わったが採るべきimplementation pathがauthorityから一意に決まる
- 別Taskのmergeで内部data flowが変わったが、既決定のproduct semanticsを保つ追従方法が一意
- broad Issueをcurrent repository ownershipに沿うimplementation sliceへ再配置したが、product scope / acceptance自体は変えていない

`Pending`へ戻す代表例:

- latest repositoryを踏まえると2つ以上の合理的なuser-facing behaviorが成立する
- compatibility / migration / scope / acceptanceを選び直す必要がある
- 既存のproduct decisionを変えなければcurrent architectureへ適合できない

単なるfact driftやexecution-route変更をproduct decisionとしてユーザーへ再質問しない一方、product decisionを「freshness更新」と呼んで勝手に変更しない。

## Same Issue vs new Issue

Issue boundaryは「original feature全体の完成に必要か」だけでは決めない。

大きなfeature / refactorは、完成まで全leafが必要でも、real independent Work boundaryを持つなら複数leaf Issueへ分解してよい。逆に、小さなfixでも独立したWork boundaryを持たなければsame Issueに残す。

### Keep in the same Issue

次はsame Issueを優先する。

- current acceptanceそのもののnarrow fix / adjustment;
- 1つのfailure classを直すための実装で、独立したuser / engineering outcomeを持たない;
- separate Issueにするとtemporary API、duplicate owner、人工的なdependency shellを作る;
- semantic completion / verification oracleがcurrent Issueと不可分;
- current Issueのimplementation sliceを分けるだけで十分で、Work scopeを移す理由がない。

same Issueでも複数sequential PR / execution routeへ分けてよい。詳細は`IMPLEMENTATION-SLICING.md`。

### Extract a new / existing leaf Issue

次を満たすclusterは、original feature completionに必要でもindependent leaf Issueへ移してよい。

1. **Scope boundary:** 何を提供 / 変更するWorkかを単独で説明できる。
2. **Semantic owner:** primary owner / API / data-flow boundaryが明確である。
3. **Independent acceptance:** leaf単独のobservable acceptance / verification oracleを持つ。
4. **Safe completion:** leafを先にmerge / Doneしてもrepositoryが一貫し、残りWorkが明示的dependencyとして継続できる。
5. **Durable tracking value:** failure / review / rollback / ownershipを別Issueで追う意味がある。

この条件を満たす場合、large featureからfoundation / planner / adapter等の独立leafを抽出することは正当なdecompositionである。

ただし、parallel execution数を増やしたい、PRを小さく見せたい、という理由だけではnew Issueにしない。

### Independent follow-up Work

original Issueを完了させた後でも延期可能な追加feature / cleanup / acceptanceは通常new Issue。

新しいproduct decisionを避けるためだけにIssueを分割しない。original acceptanceに必要なdecisionならcurrent contractを`Pending`へ戻して解決する。

### Short decision tree

```text
real independent scope + semantic owner + independent acceptance + safe completion?
  YES -> new / existing leaf Issueを検討
  NO  -> same Issue

same Issueだがimplementation boundaryは分けられる?
  YES -> Same Issue + sequential slice / PR

additional Workはoriginal completion後でも独立延期可能?
  YES -> new Issue
```

Issue boundary、chat、execution laneは別判断。

```text
new leaf Issue
  -> Authoring / contract Ready
  -> Todo
  -> FREEなmain/sub laneへstartupした時だけIn Progress

same Issue next slice
  -> current laneで継続、またはsafe checkpointでrelease / later restart
  -> implementationはLuna xhigh
```

execution capacity / laneは`CHECKOUTS.md`、implementation executorは`CODING-AGENT.md`、slice / checkpointは`IMPLEMENTATION-SLICING.md`をauthorityとする。

## Parent after decomposition

original Issueのscopeを複数leafへ移した場合、pure tracking parentを自動的に残さない。

- parent自身にaggregate acceptance / integrated Manual E2E / final cutover等が残る → retained parentとして維持。
- original scope / acceptanceをすべてleafへ移し、親に独自Workがない → tracking shellとしてactiveに残さない。status handlingは`LINEAR-ISSUES.md`に従う。
- decomposition / research自体がoriginal Workだった → そのacceptanceが完了すればDoneにしてよい。

retained parentはexecution ownership labelを持たない。

## Current behavior vs normative contract

repository authorityの役割を混同しない。

- source code / executable repository state: **現在実装が実際にどう振る舞うか**のauthority
- normative specification / durable product contract: **本来どう振る舞うべきか**のauthority

normative specとactual codeが食い違っただけでは、specをcodeに合わせて書き換えてよい理由にならない。

- spec = A、code = B、Aをsupersedeする新しいauthoritative decisionなし → code側のbugとして扱う。
- old spec = A、より新しいauthoritative product decision = B、code = B → staleなspecをBへ更新する。
- spec = A、code = B、どちらがintendedかcurrent authorityから一意に確定できない → `Contract: Pending`としてproduct decisionを確認する。

actual implementationを調べる質問と、normative behaviorを決める質問を分ける。

## Guardrails

このruleは、ChatGPTが新しいproduct policyを独断で作ることを許可するものではない。

- platform標準とnuinuiCAD既存ruleが衝突する場合はユーザー判断へ戻す。
- 既存rule同士が衝突する、authorityが不明、またはrepository stateから一意に導けない場合はユーザー判断へ戻す。
- 「一般的にはこうする」「たぶん自然」というだけでは一意決定扱いにしない。current authorityで根拠を確認する。
- 標準挙動から意図的に外れる必要がある場合は、その理由とUX差分をユーザーへ提示する。
- 将来仕様を不必要に先取りしない。current scopeだけで決まる最小のcontractにする。
- decompositionの都合でproduct acceptanceを書き換えない。

## Contract workflow

1. latest Project Contextとloading ruleに従って必要なauthorityを読む。
2. current implementationに関係する判断はlatest remote repositoryで確認する。
3. actual behaviorとnormative contractのauthorityを分けて確認する。
4. acceptance cluster / semantic ownerを見てreal Work boundaryがあるか確認する。
5. platform標準または既存nuinuiCAD ruleから一意に決まる事項をcontractへ直接記録する。
6. 一意に決まらないproduct decisionだけをユーザーへ確認する。
7. boundary map / implementation slicing / later execution routingは`IMPLEMENTATION-SLICING.md`、`CHECKOUTS.md`、`CODING-AGENT.md`で決定する。
8. Linear write直前にcurrent Issue / relevant commentsを再取得し、並行Authoringの変更を失わないことを確認する。
9. 決定後、Issue本文・Contract label・Manual E2E plan・dependencyを同じcheckpointで整合させる。

ユーザーへ確認する項目数を減らすこと自体を目的にしない。目的は、既に決まっていることを再質問せず、本当に判断が必要な分岐だけに会話を使うこと。
