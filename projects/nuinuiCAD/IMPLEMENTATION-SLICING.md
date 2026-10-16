# nuinuiCAD implementation slicing policy

## Purpose

1つのWorkを、implementation slice、Pull Request、safe checkpointとしてどこで区切るかを定義する。GitHub-native Workとcompatible pre-existing SAY WorkはIssue identityとcheckpoint storeを分ける。

Work decompositionとimplementation slicingを混同しない。

- Work decomposition: native Workのoriginal scope / acceptanceをsame GitHub Issueに残すか、independent leaf Issueへ移すか。compatible pre-existing SAY Workは既存Linear identityを歴史的に保持する。
- Implementation slicing: same Issueのimplementationを1つまたは複数のsequential slice / PRへどう分けるか。
- Execution lane: current implementation sliceをどのmanifest-declared implementation laneで実行するか。

Issue boundaryは [`CONTRACT-DECISIONS.md`](./CONTRACT-DECISIONS.md)、lane capacity / checkout isolationは [`CHECKOUTS.md`](./CHECKOUTS.md)、implementation executorは [`CODING-AGENT.md`](./CODING-AGENT.md) がauthority。

以下のlane assignmentとLinear checkpoint recordはcompatible pre-existing SAY executionにだけ適用する。GitHub-native slicingは末尾のsectionがownerし、一般D1 activation checkpoint後に通常適用する。それまではnative implementation startupを行わない。

same Issueであることはsame branch、same PR、same Coding Agent session、same uninterrupted execution trackを意味しない。

## Core rule

Implementationはcurrent repository ownershipの自然なboundaryでsliceし、**1 sliceを1 implementation lane上で、1つの固定Base checkpointから次のsafe checkpointまで完結させる。**

最初から全PR構成を確定する必要はない。current slice開始時には少なくとも次を固定する。

- current acceptance cluster;
- primary semantic owner / boundary;
- selected lane: `<manifest-declared implementation lane>`;
- Base checkpoint SHA;
- branch;
- next safe checkpoint;
- required verification。

Ordinary implementation and compatible pre-existing SAY execution keep Luna
xhigh as their default/current executor. A GitHub-native implementation Issue
may use the Human-selected agent only when its current Issue body explicitly
opts into the autonomous conformance mode defined in [`CODING-AGENT.md`](./CODING-AGENT.md).
That choice applies to the Issue's authorized matrix, not separately to each
defect family or slice. No other Work may select an alternative executor by
implication.

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

別implementation laneが既に`BUSY`なら、Coordinatorの[`Parallel admission gate`](./CHAT-COORDINATOR.md)を通った候補であることを確認する。Implementation chatから直接start候補を決める場合も同等のinterference auditを行い、`LOW`と判断できない候補を「laneが空いている」という理由だけで開始しない。

candidate選定後からactual startまでに相手laneのscopeがshared ownerへ拡大したsignalがあれば、Baseを固定する前にparallel admissionを再評価する。

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

PRを小さくすること、Issue数を増やすこと、宣言されたcapacityを常時埋めること自体を目的にしない。

## Safe checkpoints

### Implementation checkpoint

current laneの作業をremote branchへ安全に保存し、別conversation / Coding Agent sessionから再開できる地点。

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
-> ChatGPT audits Base/current-main drift and current contract
-> deterministic conflict-free merge-only integration with settled verification?
   -> Human `nuinui integrate-clean`
   -> required verification
   -> record Integration Watermark
   -> blocking review
   or
-> integration reasoning / conflict resolution / integration fix required
   -> the assigned implementation Coding Agent integrates and verifies
      (Luna xhigh for ordinary work; the Human-selected agent for an opted-in Issue)
   -> record Integration Watermark
   -> blocking review
-> merge
```

active slice途中のroutine merge-main / rebase-mainは禁止。

remote advanceがcurrent contractをmaterially invalidateした場合は、途中同期せずcurrent workを保存してcheckpointで停止し、contract / sliceを再評価する。

#### Integration Watermark and post-integration drift

Routine Integrationは**1 sliceにつき1回**を原則とする。latest intended `main`を取り込みrequired verificationを完了した時点で、その取り込んだ`main` SHAを`Integration Watermark`として記録し、routine Integration checkpointは到達済みとする。

Integration Watermark到達後にblocking reviewでfixが必要になっても、それだけではIntegration checkpointを未到達へ戻さない。

```text
Integration Watermark reached
-> blocking review
-> blocking fix on the same topic branch
-> focused / required verification
-> pushed fix review
```

blocking fix中やreview中にremote `main`がadvanceした場合、その差分を`Post-integration Drift`として扱う。**mainがadvanceした事実だけではIntegration Watermark、blocking review、Review Headをinvalidateしない。**

`Integration Watermark..current main`を確認し、次で分類する。

- `NON-INTERFERING`: current sliceのsemantic owner / shared API / prerequisite / contract / mergeabilityへmaterialな影響がない。再integrationしない。そのままreview / PR / merge gateへ進む。
- `RELEVANT`: current sliceのsemantic owner / shared primitive / prerequisite / contractをmaterially変更している、またはcurrent review premiseを一意に維持できない。exception integrationまたはcontract / slice re-evaluationが必要。
- `MERGE-GATE`: actual conflict / unmergeable state、またはrepositoryのcurrent merge requirementがbranch updateを明示的に要求する。必要なintegrationを行う。

`NON-INTERFERING` driftについて、topic branchがcurrent `main`を含んでいないことだけを理由にroutine integrationを繰り返さない。PR作成後にさらに`main`がadvanceした場合も同じruleを使う。

`RELEVANT`または`MERGE-GATE`でexception integrationを行った場合は、integration / required verification後のmain SHAで`Integration Watermark`を更新し、変更されたpremiseに応じたblocking reviewを行う。単なる最新化目的ではexception integrationを行わない。

同じsliceでexception integrationが繰り返し必要になる場合、最新mainを追い続ける問題として扱わない。同じsemantic owner / shared primitiveをparallel laneが継続的に変更しているcontention signalとして、Coordinatorのparallel admission / lane schedulingを再評価し、必要なら片方を先にmergeするsequential executionへ戻す。

blocking review PASS時にはexact topic SHAを`Review Head`として扱う。PR / auto-merge / merge直前はcurrent `main`と`Post-integration Drift`をfreshに確認するが、`NON-INTERFERING` driftならReview Headを作り直すためのintegrationを要求しない。

#### Deterministic merge-only Human integration

ChatGPTがBase checkpointとcurrent `main`のdriftおよびcurrent contractをauditし、integrationがconflict-free merge-only operationとsettled verificationだけで完了するとfreshに判定した場合は、source implementationとは別のdeterministic integration operationとしてHuman `nuinui integrate-clean`を使ってよい。これはfirst / routine Integration checkpointにも適用でき、prior Integration Watermarkまたはblocking Review Headを要求しない。

first / routine checkpointではexact implementation checkpoint、same durable generation、fresh current main、known exact verification plan、no Manual E2E追加要求、conflict / source edit / integration fix / ambiguous diagnosis不要であることがpreconditionとなる。successful `INTEGRATION PUSHED`ではmerged current-main SHAを`Integration Watermark`として記録し、pushed-state blocking reviewとnormal PR / merge workflowへ進む。

既存のpost-review merge-gate refreshでは、already-reviewed exact Review Headと既存のIntegration Watermarkがあり、post-integration semantic driftをChatGPTがfreshに`NON-INTERFERING`と判定し、merge gateの唯一の要求がcurrent-base CI / branch freshnessであることが追加のpreconditionとなる。この場合もhelperはcurrent `main`をconflict-free merge-onlyで取り込み、verification後にnormal pushする。successful pushed merge headでIntegration Watermarkを更新し、parents / effective diff / verification evidence / remote stateを対象とするfocused blocking reviewとfresh required PR CIを行う。

`integrate-clean`のstale / mechanical precondition failureが、source reasoningなしに一意にfreshへ更新できる場合は、ChatGPTのfresh re-evaluation後も同じdeterministic Human routeに残してよい。conflict、verifier failureのdiagnosisまたはcode change、source edit、integration fix、relevant / ambiguous semantic drift、ambiguous repository stateが必要なintegrationは、current Workのimplementation Coding Agentが担当する（ordinary work and compatible SAY workではLuna xhigh、明示的にopt-inしたnative IssueではHuman-selected agent）。Human `integrate-clean`はdeterministic terminal assistanceであり、別のsource implementation executorではない。

### Verification boundary

内部helper単体だけでなく、変更したboundaryを最後まで通したobservable resultを少なくとも1つ検証する。

例:

- candidate生成だけでなくadapter適用後のlabel / replace range / resulting source;
- semantic valueだけでなくruntime consumerへ渡るresolved value;
- serializer payloadだけでなくround-trip canonical source;
- host-neutral queryだけでなくproduction host adapterが公開するresult。

shared boundaryへ初めて接続したcheckpointでは、影響範囲に応じたbroad integration testをTask末尾まで延期しない。

## Compatible legacy SAY lane assignment

implementation slice開始時は、ChatGPTがfresh remote state、Linear current implementation occupancy、parallel-admission decisionからdeclared lane、Base、branch、complete inventory expectationを決め、known-Issueの通常startupではHumanへ [`nuinui begin`](./LOCAL-TOOLS.md) を1つ渡す。`begin`が [`CHECKOUTS.md`](./CHECKOUTS.md) のfull declared-lane auditを内部実行し、target FREEとcomplete inventoryを再検証するため、別Human preflightを先行させない。

- declared implementation laneのいずれかがFREE → Coordinatorのparallel admissionに従い開始候補にできる;
- BUSY laneがあり別のFREE laneがある場合も、`LOW`と判定できる独立Taskだけを開始してよい;
- admissibleなTaskがない → FREE laneをそのまま残す;
- 全implementation laneがBUSY →新しいimplementationは開始しない;
- `role=human-test` laneはimplementationへ使わない。

same active durable generationのresume、blocking-fix、integration、new Luna session、ChatGPT chat rotation、またはunrelated remote `main` advanceだけではdeclared-lane preflightへ戻らない。実装Agentはassigned checkoutで`nuinui handoff <SAY-N> <expected-main-sha>`を実行し、façadeがmanifestとdurable slotからBranch / Base / Claim / Checkpointとremote topic modeを解決して、[`EXECUTION-HANDOFF.md`](./EXECUTION-HANDOFF.md) のstandalone proofへ渡す。handoffが`HANDOFF VERIFIED`を返さなければ、実装Agentは変更せず停止してorchestratorへ戻る。resume、retry、repair、別のHuman handoff verificationは行わない。

declared lane capacityを超えるparallelismをIssue / branch / worktree追加で表現しない。全laneを常時使用することも目標にしない。

## Cross-lane dependency rule

各declared implementation laneはそれぞれのBase checkpointから独立して進める。

禁止:

- one declared laneが別のdeclared laneのunfinished branchを取り込む;
- one declared laneが別laneのmid-slice commitをbaseにする;
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
9. Manual E2E FAILでnew failure class / ownerが露出した;
10. Integration Watermark以降のPost-integration Driftが`RELEVANT`または`MERGE-GATE`になった;
11. parallel active laneのscope expansionにより、開始時の`LOW` interference premiseがmaterially崩れた。

`NON-INTERFERING`なmain advance、file数、diff行数、commit数、経過時間はそれ自体ではre-evaluation triggerにしない。

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

## Compatible legacy SAY checkpoint record

implementation lane開始 / pause / next PRでは少なくとも:

```text
Implementation checkpoint
- Lane: <manifest-declared implementation lane>
- Base checkpoint: <sha>
- Branch: <branch>
- PR / pushed head: <pr or sha>
- Completed acceptance: <what is done>
- Remaining acceptance: <what remains>
- Current / next slice: <semantic boundary>
- Next safe checkpoint: <implementation | integration | merge>
```

Integration Watermark到達後は、rotation / handoffで誤ってroutine integrationを再開しないよう、必要に応じて同Issueのcheckpointへ次も記録する。

```text
- Integration Watermark: <integrated main sha>
- Review Head: <blocking-review-passed topic sha | pending>
- Post-integration Drift: <none | NON-INTERFERING through sha | RELEVANT | MERGE-GATE>
```

細かなcommit logは複製しない。

## Manual E2E failure

Manual E2Eでconfirmed implementation failureが出たらHuman-test laneでfixしない。

1. failureをimplementation / environment / capability / oracleへ分類;
2. implementation failureならfailure classとsemantic ownerを特定;
3. Same Issue vs new leafを判断;
4. smallest natural fix sliceを決める;
5. FREEなdeclared implementation laneへ載せる。ただし他laneが`BUSY`ならparallel admission gateを満たすこと;
6. Luna fix / verification / integration / merge;
7. new exact tested commitでaffected E2E unitをrerun。

previously passed unaffected unitsはshared owner / premiseが変わらない限り機械的にrepeatしない。

## Coding Agent execution

Luna xhigh remains the default executor for ordinary implementation and the
current executor for compatible pre-existing SAY work. The only alternate
route is a GitHub-native Issue that explicitly opts into autonomous
conformance discovery and repair under [`CODING-AGENT.md`](./CODING-AGENT.md).

ChatGPT sets the current slice's contract, lane, Base checkpoint, and safe
checkpoint, then gives the assigned Coding Agent only that scoped work. The
opted-in agent may continue across multiple in-scope defect families without
a family-count stop; choose slice and PR boundaries by owner and repository
coherence, never by the number of discovered defects.

## GitHub-native slicing and checkpoints — after general activation

Use this policy for ordinary GitHub-native Work after the general D1 activation
checkpoint is recorded in [dev-context #268](https://github.com/sayosomi/dev-context/issues/268).
That checkpoint follows independent review, merge, and authoritative dev-context
`main` read-back of the coordinated policy PR. Until then, native implementation
startup remains blocked. The completed #1374 pilot was one-off operational proof
under an expressly waived policy-amendment prerequisite, not strict compliance
with the unchanged pre-activation policy or general activation. Once the
checkpoint is recorded, no separate per-Task approval or activation mechanism
applies.

Do not import the compatible SAY lane claims or Linear checkpoints below into a
native Issue.

An opted-in conformance Issue remains ordinary D1 implementation Work and
uses the same single-checkout admission and GitHub-native checkpoints. Read
[`CODING-AGENT.md`](./CODING-AGENT.md) for its required Issue-body contract;
do not infer the mode from a D2-C audit Issue or wording in a prompt.

Keep Work decomposition separate from implementation slicing. Keep one
product implementation active at a time. Choose slice boundaries by independent
acceptance, semantic-owner boundaries, dependencies, verifiable outcomes, and
whether each intermediate merge leaves the repository coherent. Do not split
only to reduce PR size, and do not merge an intermediate slice that leaves a
broken or owner-ambiguous state.

For each GitHub-native slice, record its repository-qualified Issue identity,
slice boundary, intended base SHA, topic branch, exact pushed checkpoint,
completed and remaining acceptance, verification results, and next safe
checkpoint in GitHub Issue comments. Re-read the latest Issue contract and
latest main before starting the next slice. A next slice after an intermediate
merge starts from a fresh topic branch at the newly verified main; do not
continue from stale main or silently reuse the previous branch.

For an opted-in conformance Issue, also record distinct defect families,
reproduction seeds, expected/actual results, exact candidate revisions,
completed and contaminated matrix cells, residuals, source changes, and
verification in the same Issue/PR surfaces. Finding another in-scope family
does not by itself end a slice, require a new Issue, or trigger a PR; retain
the ordinary safe checkpoint, independent review, and protected CI gates.

For interrupted work, resume only after rechecking the Issue, exact remote
topic SHA, local branch/HEAD/status, and the recorded pushed checkpoint.
Never infer a completed push from lost terminal output or replay a mutation
without first reading back its authoritative state.

Intermediate PRs use Refs #N and do not close the Issue. Use Closes #N only
when the merge satisfies all remaining acceptance, including required Human
Manual E2E, under [LINEAR-GITHUB.md](./LINEAR-GITHUB.md) and
[MANUAL-E2E.md](./MANUAL-E2E.md). Keep unfinished
acceptance and required Human E2E explicit in the Issue. Do not create Linear
checkpoint/status changes, SAY identifiers, or lane claims for native Work.
