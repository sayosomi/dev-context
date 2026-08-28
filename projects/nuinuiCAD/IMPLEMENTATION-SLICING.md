# nuinuiCAD implementation slicing policy

## Purpose

1つのWork / Linear Issueを、implementation slice、Pull Request、safe checkpointとしてどこで区切るかを定義する。

Work decompositionとimplementation slicingを混同しない。

- Work decomposition: original scope / acceptanceをsame Linear Issueに残すか、independent leaf Issueへ移すか。
- Implementation slicing: same Issueのimplementationを1つまたは複数のsequential slice / PRへどう分けるか。
- Execution lane: current implementation sliceを`main`または`sub`のどちらで実行するか。

Issue boundaryは [`CONTRACT-DECISIONS.md`](./CONTRACT-DECISIONS.md)、lane capacity / checkout isolationは [`CHECKOUTS.md`](./CHECKOUTS.md)、implementation executorは [`CODING-AGENT.md`](./CODING-AGENT.md) がauthority。

same Issueであることはsame branch、same PR、same Luna session、same uninterrupted execution trackを意味しない。

## Core rule

Implementationはcurrent repository ownershipの自然なboundaryでsliceし、**1 sliceを1 implementation lane上で、1つの固定Base checkpointから次のsafe checkpointまで完結させる。**

最初から全PR構成を確定する必要はない。current slice開始時には少なくとも次を固定する。

- current acceptance cluster;
- primary semantic owner / boundary;
- selected lane: `main | sub`;
- Base checkpoint SHA;
- branch;
- next safe checkpoint;
- required verification。

実装executorはLuna xhigh。sliceごとに別execution routeを選ぶ仕組みは持たない。

## Pre-execution slicing audit

Contract: ReadyのIssueでもacceptance全体をそのまま1 PRへ写像しない。

implementation開始前にwhole current scopeを監査し、次を整理する。

- acceptance cluster;
- primary semantic owner / boundary;
- upstream / downstream dependency;
- independently verifiableか;
- intermediate merge後もrepositoryが一貫するか;
- later acceptanceがcurrent unmerged implementationへ暗黙依存しないか;
- broad integration / lifecycle boundaryがどこか;
- parallel laneで別Taskが同じowner / prerequisiteを持っていないか。

自然なboundary例:

```text
semantic / type foundation
-> host-neutral planner / transformation
-> adapter / protocol / runtime integration
-> host wiring / lifecycle integration
-> interactive UX / production-host acceptance
```

actual repository ownershipを優先する。

## Do not force decomposition

次の場合はsplitしない。

- intermediate mergeがtemporary broken stateを作る;
- duplicate source-of-truth / duplicate ownerが必要;
- acceptanceが1つのcross-boundary transactionとしてしか意味を持たない;
- slice単独のverification oracleがない;
- artificial compatibility layerやtemporary APIが必要;
- overheadだけ増え、review / diagnosis / rollback境界が改善しない。

PRを小さくすること、Issue数を増やすこと、2 laneを常時埋めること自体を目的にしない。

## Safe checkpoints

### Implementation checkpoint

current laneの作業をremote branchへ安全に保存し、別conversation / Luna sessionから再開できる地点。

最低限:

- current branch / pushed head;
- Base checkpoint;
- completed implementation;
- remaining acceptance;
- verification result / failure classes;
- next safe action。

pause / handoff時はここまで到達させる。checkpointしただけではlatest `main`を取り込まない。

### Merge checkpoint

current sliceをintended baseへmergeしてもrepositoryが一貫し、remaining acceptanceを後続sliceとして安全に実装できる地点。

最低限:

- current sliceがreview可能なsemantic changeとして説明できる;
- focused verificationが完了;
- remote branchへ保存済み;
- remaining acceptanceがcurrent unmerged implementationへ暗黙依存しない。

### Integration checkpoint

**他line / latest remote `main`を取り込める唯一の通常checkpoint。**

current slice implementationとfocused verificationを完了しremoteへ保存した後、blocking review / merge前に行う。

```text
pushed implementation checkpoint
-> inspect Base checkpoint..latest main
-> determine relevant drift
-> Luna integrates latest intended base in same lane
-> resolve conflicts / integration regressions
-> required broad verification
-> blocking review
-> merge
```

active slice途中のroutine merge-main / rebase-mainは禁止。

remote advanceがcurrent contractをmaterially invalidateした場合は、途中同期せずcurrent workを保存してcheckpointで停止し、contract / sliceを再評価する。

### Verification boundary

内部helper単体だけでなく、変更したboundaryを最後まで通したobservable resultを少なくとも1つ検証する。

例:

- candidate生成だけでなくadapter適用後のlabel / replace range / resulting source;
- semantic valueだけでなくruntime consumerへ渡るresolved value;
- serializer payloadだけでなくround-trip canonical source;
- host-neutral queryだけでなくproduction host adapterが公開するresult。

shared boundaryへ初めて接続したcheckpointでは、影響範囲に応じたbroad integration testをTask末尾まで延期しない。

## Lane assignment

implementation slice開始時に [`CHECKOUTS.md`](./CHECKOUTS.md) のmandatory preflightを行う。

- `main` FREE →通常第一候補;
- `main` BUSYかつ`sub` FREE →独立Taskなら`sub`;
- 両方BUSY →新しいimplementationは開始しない;
- `e2e`はimplementationへ使わない。

2 laneを超えるparallelismをIssue / branch / worktree追加で表現しない。

## Cross-lane dependency rule

`main`と`sub`はそれぞれ固定Base checkpointから独立して進める。

禁止:

- lane Aがlane Bのunfinished branchを取り込む;
- lane Bがlane Aのmid-slice commitをbaseにする;
- 相手laneが進んだからという理由だけのroutine sync。

real prerequisiteが判明した場合:

1. dependent laneをremote保存済みcheckpointで止める;
2. prerequisite laneをintended baseへmergeする;
3. dependent laneは次のintegration / restart checkpointでlatest mainから再構成する。

stacked PRをdefaultにしない。

## Re-evaluation triggers

次でboundary map / safe checkpointを再評価する。

1. any implementation slice開始前;
2. shared owner / adapter boundaryへ初めて接続した;
3. Task pause / resume;
4. implementationが当初owner / API / contract / data-flow boundaryを越えようとする;
5. 複数の独立failure classが残った;
6. current PRが複数の独立semantic changeを抱えた;
7. Base checkpoint以降のremote main advanceがcontract / ownershipをmaterially変えた;
8. blocking fix loopが新ownerへ広がる;
9. Manual E2E FAILでnew failure class / ownerが露出した。

file数、diff行数、commit数、経過時間はwarning signalのみ。

## Decision outcomes

### A. Same Issue + same slice

remaining acceptanceがcurrent sliceと強く結合し、途中mergeで不整合を作る場合。

same lane / branchで継続し、Base checkpointはintegration checkpointまで固定する。

### B. Same Issue + next PR

current sliceを安全にmergeでき、remaining acceptanceはsame Issue completionに必要な場合。

- current sliceをintegration / verify / review / merge;
- Issueはactive / resumableのまま;
- implementation checkpointをLinearへ記録;
- current laneをreleaseしてよい;
- next slice開始時にlaneを改めて選び、latest remote mainから新しいBase checkpointを固定する。

### C. New / extracted leaf Issue

clusterが独立scope / acceptance / verification boundaryを持つ場合。

Issue boundaryは [`CONTRACT-DECISIONS.md`](./CONTRACT-DECISIONS.md) に従う。

### D. Blocker / contract reset

必要なenvironment / prerequisiteがない、またはnew product / UX / scope decisionが必要な場合。

current workをremoteへ保存しsafe checkpointで停止する。slicingで未決定semanticsを隠さない。

## Sequential PR rule

1つのLinear Issueは複数のsequential PRを持ってよい。

- intermediate PRはoriginal Issueの一部acceptanceだけを完了してよい;
- remaining acceptanceがあればIssueは完了しない;
- previous slice merge後、次sliceはnew lane startとしてlatest remote mainからBase checkpointを固定する;
- previous slice merge後のnext sliceではprevious branch名を機械的に再利用せず、current sliceを識別できるfresh branchを選ぶ;
- previous unmerged implementationへの依存があるなら先にmerge checkpointを完了する;
- accidental stacked PRを作らない。

## Linear checkpoint record

implementation lane開始 / pause / next PRでは少なくとも:

```text
Implementation checkpoint
- Lane: main | sub
- Base checkpoint: <sha>
- Branch: <branch>
- PR / pushed head: <pr or sha>
- Completed acceptance: <what is done>
- Remaining acceptance: <what remains>
- Current / next slice: <semantic boundary>
- Next safe checkpoint: <implementation | integration | merge>
```

細かなcommit logは複製しない。

## Manual E2E failure

Manual E2Eでconfirmed implementation failureが出たら`e2e` laneでfixしない。

1. failureをimplementation / environment / capability / oracleへ分類;
2. implementation failureならfailure classとsemantic ownerを特定;
3. Same Issue vs new leafを判断;
4. smallest natural fix sliceを決める;
5. FREEな`main` / `sub` implementation laneへ載せる;
6. Luna fix / verification / integration / merge;
7. new exact tested commitでaffected E2E unitをrerun。

previously passed unaffected unitsはshared owner / premiseが変わらない限り機械的にrepeatしない。

## Coding Agent execution

各implementation sliceのexecutorはLuna xhigh。

ChatGPTがcurrent sliceのcontract / lane / Base checkpoint / safe checkpointを決め、Lunaにはそのnarrow implementationだけを渡す。詳細は [`CODING-AGENT.md`](./CODING-AGENT.md)。
