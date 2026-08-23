# nuinuiCAD implementation slicing policy

## Purpose

1つのWork / Linear Issueを、implementation、Pull Request、execution trackとしてどこで区切るかを定義する。

Work decompositionとimplementation slicingを混同しない。

- Work decomposition: original scope / acceptanceをsame Linear Issueに残すか、independent leaf Issueへ移すか。
- Implementation slicing: same Issueのimplementationを1つまたは複数のsequential PR / execution checkpointへどう分けるか。
- Execution routing: 各leaf / sliceを`only_chatgpt` direct GitHub + CIで実行するか、standard Implementation Coding Agentで実行するか。

same Issueであることは、same branch、same PR、same execution owner、same ChatGPT conversation、same uninterrupted execution trackを意味しない。

Issue boundaryは [`CONTRACT-DECISIONS.md`](./CONTRACT-DECISIONS.md)、execution label / reservationは [`ONLY-CHATGPT.md`](./ONLY-CHATGPT.md) をauthorityとする。この文書はimplementation boundary、safe checkpoint、再分解の判断をownerする。

## Core rule

Implementation decomposition is a continuing execution decision, not a one-time Ready-contract decision.

開始時に「split不要」「whole Issueを1 execution routeで進める」と判断してもTask完了まで固定しない。current repository state、実装済みslice、verification結果、Manual E2E result、残りacceptanceをcheckpointごとに再評価する。

大きなWorkを理由に`only_chatgpt`を諦めない。逆に、`only_chatgpt` coverageを増やすためだけに不自然なboundaryを作らない。

目標は、**current repository ownershipが自然に分かれている箇所から、独立検証可能なdirect GitHub + CI向きleaf / sliceをできるだけ抽出し、切り出せないintegration-heavy部分だけ別execution routeへ残すこと**。

最初から全PR構成を確定する必要はない。implementation開始時には少なくとも最初のsafe checkpointと、そのcheckpointまでのexecution routeを決める。

## Boundary map before implementation

Contract: ReadyのIssueでも、acceptance全体をそのまま1 PR / 1 execution routeへ写像しない。

最初のrepository write前に、current repositoryを基準として少なくとも次を整理する。

- acceptance cluster
- primary semantic owner / boundary
- upstream / downstream dependency
- independently verifiableか
- そのclusterだけをmergeした場合にrepositoryが一貫するか
- remaining acceptanceから独立延期 / independent leaf化できるか
- direct GitHub + CIがそのclusterの実装/debug loopとして適しているか
- Coding Agentが必要になるintegration / lifecycle / exploratory workがどこに残るか

特に複数owner / API / adapter / data-flow boundaryを横断するWorkでは、次のような段階を意識する。

```text
semantic / type foundation
-> host-neutral planner / transformation / query
-> adapter / protocol / runtime integration
-> editor / host wiring / lifecycle integration
-> interactive UX / production-host acceptance
```

この形は例であり、actual repository ownershipを優先する。

## `only_chatgpt` leaf extraction

Large Workのboundary mapで、次を満たすclusterがあれば`only_chatgpt`候補として積極的に抽出する。

- 1つまたは少数の明確なsemantic ownerで説明できる;
- current acceptanceを独立して検証できる;
- safe merge / handoff checkpointが成立する;
- GitHub-visible source + tests + CIで実装とfailure diagnosisを十分に回せる;
- open-ended architecture / UX判断をimplementation中に必要としない;
- downstream integrationが未完成でもrepositoryを壊れた状態にしない。

典型例:

- parser / compiler / evaluatorのfocused semantics;
- host-neutral model / planner / pure transformation;
- protocol / adapterのisolated contract;
- diagnostics / language query;
- focused regression fix;
- deterministic fixture / test / CI / tooling change;
- narrow refactor with independent verification.

抽出後の形は、Work boundaryに応じてどちらでもよい。

### Independent Work boundary

```text
feature / aggregate scope
├─ leaf A: only_chatgpt
├─ leaf B: only_chatgpt
└─ leaf C: Coding Agent / integration
```

独立Issue化は`CONTRACT-DECISIONS.md`に従う。

### Same Work, sequential implementation slices

```text
SAY-X
  slice / PR 1: only_chatgpt
  slice / PR 2: only_chatgpt
  slice / PR 3: Coding Agent
```

同じIssueでもexecution ownerはsliceごとに変えてよい。

## Do not force decomposition

次の場合は`only_chatgpt`化のためにsplitしない。

- intermediate mergeがtemporary broken stateを作る;
- duplicate source-of-truth / duplicate ownerが必要になる;
- acceptanceが1つのcross-boundary transactionとしてしか意味を持たない;
- child / slice単独では実質的なverification oracleがない;
- artificial compatibility layerやtemporary APIを作らないと分離できない;
- execution overheadだけ増え、semantic diagnosis / rollback境界が改善しない。

PRを小さくすること、Issue数を増やすこと、parallel worker数を増やすこと自体を目的にしない。

## Safe checkpoints

### Merge checkpoint

current sliceをintended baseへmergeしてもrepositoryが一貫した状態を保ち、remaining acceptanceを後続sliceとして安全に実装できる地点。

少なくとも:

- current sliceがreview可能なsemantic changeとして説明できる;
- required automated verification / blocking reviewが完了している;
- mergeで半端なsource-of-truth、壊れたproduction path、意図せず有効な未完成user-facing behaviorを残さない;
- remaining acceptanceがcurrent unmerged implementationへ暗黙依存しない。

同じLinear Issueにremaining acceptanceがある場合、intermediate PR mergeはIssue completionではない。

### Handoff checkpoint

current stateをまだmergeすべきでないが、別execution track / Coding Agent / ChatGPT conversationがlatest remote stateと記録から安全に再開できる地点。

少なくとも:

- current branch / PR / head;
- completed implementation;
- remaining acceptance;
- current verification result / failure classes;
- next safe action;
- current base / relevant ownership drift;
- next intended execution route.

pause / resumeは自然なhandoff triggerだが、pauseのたびにPRをsplitしない。

### Verification boundary

independently verifiable sliceとは、内部helper単体が正しいだけでは不十分。

adapter / projection / lowering / serialization / editor integration等のboundaryを変更する場合、少なくとも1つはそのboundaryを最後まで通したobservable resultを検証する。

例:

- completion candidate生成だけでなくadapter適用後のlabel / replace range / resulting source;
- semantic value生成だけでなくruntime consumerへ渡るresolved value;
- serializer payloadだけでなくround-trip後のcanonical source;
- host-neutral queryだけでなくproduction host adapterが公開するresult。

shared boundaryへ初めて接続したcheckpointでは、影響範囲に応じたbroad integration test / full suiteをTask末尾まで延期しない。

## Re-evaluation triggers

次でboundary map、safe checkpoint、execution routeを再評価する。

1. shared owner / adapter boundaryへ初めて接続し、broad integration test / full suite resultが得られた;
2. Taskをpause / resumeする;
3. implementationが当初のsemantic owner / API / contract / data-flow boundaryを越えようとする;
4. 複数の独立failure classが残った;
5. 1 sliceは完成・検証可能だが別ownerのacceptanceが大きく残る;
6. current PRが複数の独立semantic changeを抱え、review / diagnosis / rollback境界が不明瞭になった;
7. remote `main` advanceでimplementation shape / remaining ownerが変わった;
8. blocking fix loopが新しいownerへ継続的に広がる;
9. Manual E2E FAILで新しいfailure class / ownerが露出した;
10. direct GitHub + CI executionが、local Coding Agent executionより明らかに不利なshapeへ変わった。

file数、diff行数、commit数、経過時間はwarning signalのみ。semantic ownership、independent verification、safe mergeability、execution-loop suitabilityを優先する。

## Decision outcomes

再評価結果は次のいずれか。

### A. Same Issue + same PR + same execution route

remaining acceptanceがcurrent sliceと強く結合し、途中merge / handoffで不整合やduplicate ownerを作る場合。

current PRを継続し、次safe checkpointを更新する。

### B. Same Issue + next PR

current sliceを安全にmergeでき、remaining acceptanceは同じIssue completionに必要だが後続implementation sliceとして進められる場合。

- current PRをverify / review後にmerge;
- Issueはremaining acceptanceがあるため完了しない;
- implementation checkpointを記録;
- latest remote `main`を次baseとして再確認;
- next sliceのexecution routeを**改めて**判定する。

次sliceは`only_chatgpt`でもCoding Agentでもよい。

### C. New / extracted leaf Issue

clusterが独立したscope / acceptance / verification boundaryを持ち、Workとして別leafへ移すのが自然な場合。

これはlarge featureから`only_chatgpt`向きleafを抽出する正式なoutcomeでもある。ただし`only_chatgpt`にしたいという理由だけではnew Issueを作らない。

Issue boundary / parent handlingは`CONTRACT-DECISIONS.md`と`LINEAR-ISSUES.md`に従う。

### D. Execution route change

Work / Issue boundaryは変わらないが、次sliceの実装methodを変更する場合。

例:

```text
only_chatgpt slice complete
-> next integration slice: Coding Agent
```

または

```text
Coding Agent integration complete
-> remaining narrow regression slice: only_chatgpt
```

route変更は正常なcheckpoint判断であり、失敗扱いしない。

### E. Blocker / contract reset

必要なenvironment / capability / prerequisiteがない、または新しいproduct / UX / scope decisionが必要な場合。

Contract / dependency / statusを各authorityに従って更新する。slicingで実行不能や未決定semanticsを隠さない。

## Sequential PR rule

1つのLinear Issueは複数のsequential implementation PRを持ってよい。

- intermediate PRはoriginal Issueの一部acceptanceだけを完了してよい;
- remaining acceptanceがあればIssueはactive / resumable;
- each next sliceはmerge済みlatest baseを確認してから開始;
- previous unmerged implementationへの依存があるなら、先にmerge checkpointを完了する。意図しないstacked PRをdefaultにしない;
- each next slice reclassifies execution route independently.

PR / Linear linking semanticsは [`LINEAR-GITHUB.md`](./LINEAR-GITHUB.md) に従う。

## Linear checkpoint record

Same Issue + next PRまたはexecution route changeでは、Linearへ少なくとも:

```text
Implementation checkpoint
- Merged / current PR: <PR>
- Completed acceptance: <what this slice finished>
- Remaining acceptance: <what still belongs to this Issue>
- Next intended slice: <next semantic boundary>
- Next execution route: <only_chatgpt | Coding Agent | undecided pending refresh>
- Next base: <latest main / intended base>
```

細かなcommit logは複製しない。次executionが安全にscopeを再構成できるcurrent stateだけを記録する。

## Manual E2E failure decomposition

Manual E2Eでconfirmed product failureが出たら、元Issue全体を自動的に1つのfix trackへ戻さない。

1. failureをproduct implementation / environment / executor capability / oracle問題へ分類する;
2. implementation failureならfailure classとsemantic ownerを特定;
3. original acceptanceに必要なfixか、independent follow-up Workかを`CONTRACT-DECISIONS.md`で判断;
4. smallest natural fix leaf / sliceを決める;
5. そのfix sliceを`ONLY-CHATGPT.md`に従いdirect GitHub + CIかCoding Agentか再分類する。

複数failure classがある場合、自然に独立するものを別leaf / sequential sliceへ分けてよい。Human feedback 1件ごとに機械的なnew Issueを作ることはしない。

## Coding Agent work

Coding Agentを使うTaskでも同じboundary map / slicing ruleを使う。

ChatGPTがcurrent sliceのcontractとsafe checkpointを決め、Coding Agentにはそのnarrow implementationだけを渡す。後続sliceのopen-ended architecture判断を現在promptへ混ぜない。

Implementation Coding Agent role / handoffは [`../../shared/CODING-AGENT-WORKFLOW.md`](../../shared/CODING-AGENT-WORKFLOW.md) をauthorityとする。

## Guardrails

- PRを小さくすること自体を目的にしない;
- test fileだけ、docsだけ等semantic completionを持たない人工sliceを機械的に作らない;
- temporary broken stateをmainへmergeして次PRで直す設計にしない;
- Issue数を減らすため独立Workをsame Issueへ押し込まない;
- `only_chatgpt`数を増やすため強くcoupled Workを人工分割しない;
- same Issueだから1 PR / 1 execution ownerと決めつけない;
- current PRがcompletion直前まで収束している場合、理想的な過去sliceへ機械的に解体しない。

## Loading rule

この文書を読むのは:

1. implementation Taskを開始するとき;
2. broad Workからleaf / sliceを抽出するとき;
3. same Issueを複数PRへ分けるか判断するとき;
4. execution routeを`only_chatgpt` / Coding Agent間で判定するとき;
5. implementationをpause / resumeするとき;
6. broad/full test後に複数failure classまたは大きなremaining acceptanceが残るとき;
7. implementationが新しいsemantic owner / API / contract / data-flow boundaryへ拡張するとき;
8. Manual E2E FAIL後のfix boundaryを決めるとき。

## Maintenance rule

Issue boundary / product scope判断をこの文書へ重複させない。それらは`CONTRACT-DECISIONS.md`をauthorityとする。

Git mechanics、PR linking、Linear status、execution label / reservationの詳細も各ownerへ置き、この文書はimplementation decomposition / checkpoint / execution-route re-evaluationに集中する。
