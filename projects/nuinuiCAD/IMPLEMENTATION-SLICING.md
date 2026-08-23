# nuinuiCAD implementation slicing policy

## Purpose

1つのWork / Linear Issueを、implementation、Pull Request、execution trackとしてどこで区切るかを定義する。

Work decompositionとimplementation slicingを混同しない。

- Work decomposition: original acceptanceをsame Linear Issueに残すか、independent Issueへ移すか。
- Implementation slicing: same Issueのimplementationを1つまたは複数のsequential PR / execution checkpointへどう分けるか。

same Issueであることは、same branch、same PR、same ChatGPT conversation、same uninterrupted execution trackを意味しない。

Issue boundaryの判断は [`CONTRACT-DECISIONS.md`](./CONTRACT-DECISIONS.md) をauthorityとする。この文書はIssue boundaryを決めた後も継続するimplementation execution shapeをownerする。

## Core rule

Implementation decomposition is a continuing execution decision, not a one-time Ready-contract decision.

開始時に「split不要」と判断しても、その判断をTask完了まで固定しない。current repository state、実装済みslice、verification結果、残りacceptanceをcheckpointごとに再評価する。

最初から全PR構成を確定する必要はない。implementation開始時には少なくとも**最初のsafe checkpoint**を1つ定める。

## Safe checkpoints

### Merge checkpoint

current sliceをintended baseへmergeしてもrepositoryが一貫した状態を保ち、remaining acceptanceを後続sliceとして安全に実装できる地点。

merge checkpointでは少なくとも次を満たす。

- current sliceが1つのreview可能なsemantic changeとして説明できる。
- current sliceに必要なautomated verification / blocking reviewが完了している。
- mergeによって半端なsource-of-truth、壊れたproduction path、または意図せず有効な未完成user-facing behaviorを残さない。
- remaining acceptanceがcurrent sliceの未merge implementationに暗黙依存しない。依存する場合は同じsliceを継続するか、明示的なsequential dependencyとして次sliceを設計する。

同じLinear Issueにremaining acceptanceがある場合、intermediate PRのmergeはIssue completionを意味しない。

### Handoff checkpoint

current stateをまだmergeすべきでないが、別execution track / 別conversationがlatest remote stateと記録から安全に再開できる地点。

handoff checkpointでは少なくとも次を記録する。

- current branch / PR / head
- completed implementation
- remaining acceptance
- current verification resultと既知のfailure class
- next safe action
- current base / relevant ownership drift

pause / resumeはhandoff checkpointを作る自然なtriggerだが、pauseのたびにPRをsplitする必要はない。

## Re-evaluation triggers

次のcheckpointではimplementation slicingを再評価する。

1. 最初のbroad integration test / full suiteの結果が得られた。
2. Taskをpause / resumeする。
3. implementationが当初のsemantic owner / API / contract / data-flow boundaryを越えて拡張しようとしている。
4. 複数の独立したfailure classが残った。
5. 1つのsemantic sliceは完成・検証可能だが、別ownerのacceptanceがまだ大きく残る。
6. current PRが複数の独立したsemantic changeを抱え、review / diagnosis / rollback境界が不明瞭になった。
7. remote `main`のadvanceによってcurrent implementation shapeまたはremaining acceptanceのownerが変わった。
8. blocking fix loopが新しいownerへ広がる、または当初想定しなかった追加implementation surfaceが継続的に増える。

file数、diff行数、commit数、経過時間はwarning signalとして使ってよいが、それだけをhard split thresholdにしない。判断はsemantic ownership、independent verification、safe mergeabilityを優先する。

## Decision outcomes

再評価結果は次のいずれかにする。

### A. Same Issue + same PR

remaining acceptanceがcurrent sliceと強く結合しており、途中mergeすると不整合・duplicate owner・一時的な壊れたcontractを作る場合。

current PRを継続する。ただし次のsafe checkpointを更新する。

### B. Same Issue + next PR

current sliceを安全にmergeでき、remaining acceptanceもoriginal Issueのcompletionに必要だが、後続の独立したimplementation sliceとして進められる場合。

- current PRをrequired verification / review後にmergeする。
- Linear Issueはremaining acceptanceがあるため完了扱いにしない。
- merge checkpointをLinear Commentへ記録する。
- latest remote `main`を次sliceのbaseとして再確認する。
- next PR / next execution trackでremaining acceptanceを継続する。

これはIssue splitではない。

### C. New Linear Issue

remaining workがoriginal IssueをDoneにした後でも独立して延期できるfeature / cleanup / acceptanceである場合、またはoriginal scopeを本当にindependent leafへ移す場合。

Issue split / parent handlingは [`CONTRACT-DECISIONS.md`](./CONTRACT-DECISIONS.md) と [`LINEAR-ISSUES.md`](./LINEAR-ISSUES.md) に従う。

### D. Execution ownership change / blocker

current execution methodでは安全に完了できない、必要なenvironment / capabilityがない、または新しいproduct decisionが必要な場合。

execution ownership、Contract status、dependencyを各authorityに従って更新する。implementation slicingだけで実行不能を隠さない。

## Sequential PR rule

1つのLinear Issueは複数のsequential implementation PRを持ってよい。

- intermediate PRはoriginal Issueの一部acceptanceだけを完了してよい。
- intermediate merge後もremaining acceptanceがあるならIssueはactive / resumable Workとして継続する。
- final completion PRとintermediate PRのLinear linking semanticsは [`LINEAR-GITHUB.md`](./LINEAR-GITHUB.md) に従う。
- each next sliceはmerge済みlatest baseを確認してからimplementationを開始する。
- previous unmerged PRのimplementationへ次sliceが依存する場合、先にmerge checkpointを完了する。意図しないstacked PRをdefaultにしない。

## Linear checkpoint record

Same Issue + next PRを選んだintermediate merge checkpointでは、Linearへ少なくとも次を記録する。

```text
Implementation checkpoint
- Merged PR: <PR>
- Completed acceptance: <what this slice finished>
- Remaining acceptance: <what still belongs to this Issue>
- Next intended slice: <next semantic boundary>
- Next base: <latest main / intended base>
```

細かなcommit logを複製しない。次のexecutionが安全にscopeを再構成できるcurrent stateだけを記録する。

## `only_chatgpt`

`only_chatgpt` eligibilityは開始時だけの判定ではない。

active `only_chatgpt` Issueはこの文書のre-evaluation triggerでslicingを再評価する。independently verifiable boundaryが現れた場合、Issue splitだけを選択肢にせず、Same Issue + next PRが安全ならそれを使う。

Parallel footprint / interference gate / ownership transitionは [`ONLY-CHATGPT.md`](./ONLY-CHATGPT.md) をauthorityとする。

## Coding Agent work

Coding Agentを使うTaskでも同じimplementation slicing ruleを適用する。

ChatGPTがsafe checkpointとcurrent sliceのcontractを決め、Coding Agentにはcurrent sliceのnarrow implementationだけを渡す。後続sliceのopen-ended architecture判断を現在のCoding Agent promptへ混ぜない。

Implementation Coding Agentのrole / handoffは [`../../shared/CODING-AGENT-WORKFLOW.md`](../../shared/CODING-AGENT-WORKFLOW.md) をauthorityとする。

## Guardrails

- PRを小さくすること自体を目的にしない。
- test fileだけ、docsだけ等、semantic completionを持たない人工的なsliceを機械的に作らない。
- temporary broken stateをmainへmergeして次PRで直す設計にしない。
- Issue数を減らすために独立Workをsame Issueへ押し込まない。
- Issueをsplitしないという判断から、1 PR完走を自動的に導かない。
- current PRが既にcompletion直前まで収束している場合、過去の理想的sliceへ機械的に解体して余計なriskを作らない。remaining workとcurrent mergeabilityから判断する。

## Loading rule

この文書を読むのは次の場合。

1. implementation Taskを開始するとき。
2. same Issueを複数PRへ分けるか判断するとき。
3. implementationをpause / resumeするとき。
4. broad/full test後に複数failure classまたは大きなremaining acceptanceが残るとき。
5. current implementationが新しいsemantic owner / API / contract / data-flow boundaryへ拡張するとき。
6. PR / execution trackが長大化し、次のsafe checkpointを再評価するとき。

## Maintenance rule

Issue boundary / product scope判断をこの文書へ重複させない。それらは`CONTRACT-DECISIONS.md`をauthorityとする。

Git mechanics、PR linking、Linear status、execution ownershipの詳細もそれぞれのownerへ置き、この文書はimplementation slice / checkpoint / re-evaluationの判断に集中する。
