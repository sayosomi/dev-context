# nuinuiCAD implementation contract decision rule

## Purpose

implementation contractの策定時に、platform標準挙動やnuinuiCADの既存設計原則から一意に決まる細部まで機械的にユーザー判断へ戻さない。

ChatGPTは既存authorityから決められる事項を自分でcontractへ落とし、ユーザー確認は実際にproduct / UX / future semanticsが分岐する判断へ絞る。

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

latest repositoryに合わせてcontractを更新するときは、次の質問で判定する。

> 既に確定したuser-facing semantics / scope / acceptanceを変えずに、latest authorityからcontractを一意にrefreshできるか？

- **YES:** `Contract: Ready`を維持したままcurrent fact / implementation pathをrefreshする。
- **NO:** 複数の合理的なproduct / UX / scope / compatibility / acceptance選択肢が生じるなら`Contract: Pending`へ戻す。
- **実行不能なprerequisite:** viableな選択肢以前に必要なfoundation / capabilityが存在せずcontractを完成できないなら`Contract: Blocked`。

`Ready`のままrefreshしてよい代表例:

- file / symbol / owner名が変わったが責務とacceptanceは同じ
- current API shapeやfixture pathが変わったが採るべきimplementation pathがauthorityから一意に決まる
- 別Taskのmergeで内部data flowが変わったが、既決定のproduct semanticsを保つ追従方法が一意

`Pending`へ戻す代表例:

- latest repositoryを踏まえると2つ以上の合理的なuser-facing behaviorが成立する
- compatibility / migration / scope / acceptanceを選び直す必要がある
- 既存のproduct decisionを変えなければcurrent architectureへ適合できない

単なるfact driftをproduct decisionとしてユーザーへ再質問しない一方、product decisionを「freshness更新」と呼んで勝手に変更しない。

## Same Issue vs new Issue

実装・調査中に追加作業が見つかったときは、Issueを分けること自体を目的にしない。

1. original acceptanceに明示されている修正・挙動なら同じIssueで扱う。
2. 明示されていなくてもcurrent authorityからoriginal acceptanceを満たすために一意に必要と分かる作業なら同じIssueで扱う。
3. 必要性はoriginal completionに直結するが新しいproduct decisionが必要なら、current Issueを`Contract: Pending`へ戻してdecisionを解決する。decision後もoriginal completionに必要なら同じIssueで扱う。
4. original Issueを完了させても独立して延期できる追加feature / cleanup / acceptanceなら別Issueにする。

短い判定:

```text
直さないとoriginal IssueをDoneにできない
=> same Issue

original IssueをDoneにした後でも独立して進められる
=> new Issue
```

新しいproduct decisionを避けるためだけにIssueを分割しない。

**same Issue / new Issue と、implementationを何PR・何execution trackへ分けるかは別判断。** same Issueと判定されたWorkでも、safe merge checkpointがあるなら複数のsequential PR / execution trackへ分けてよい。same Issueだからsame branch / same PR / same conversationで完走するとは扱わない。implementation slice / checkpoint /途中再判定は [`IMPLEMENTATION-SLICING.md`](./IMPLEMENTATION-SLICING.md) をauthorityとする。

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

## Contract workflow

1. latest Project Contextとloading ruleに従って必要なauthorityを読む。
2. current implementationに関係する判断はlatest remote repositoryで確認する。
3. actual behaviorとnormative contractのauthorityを分けて確認する。
4. platform標準または既存nuinuiCAD ruleから一意に決まる事項をcontractへ直接記録する。
5. 一意に決まらないproduct decisionだけをユーザーへ確認する。
6. 決定後、Issue本文・Contract label・Manual E2E plan・dependencyを同じcheckpointで整合させる。

ユーザーへ確認する項目数を減らすこと自体を目的にしない。目的は、既に決まっていることを再質問せず、本当に判断が必要な分岐だけに会話を使うこと。
