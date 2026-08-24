# nuinuiCAD Linear Issue workflow

## Purpose

Linear Issueのstatus、readiness、execution-lane checkpoint、labels、Done freshnessを定義する。

- chat roles / Issue Authoring / rotation: [`CHAT-WORKFLOW.md`](./CHAT-WORKFLOW.md)
- lane capacity / occupancy: [`CHECKOUTS.md`](./CHECKOUTS.md)
- Manual E2E semantics: [`MANUAL-E2E.md`](./MANUAL-E2E.md)
- contract judgment: [`CONTRACT-DECISIONS.md`](./CONTRACT-DECISIONS.md)
- implementation slicing / integration checkpoint: [`IMPLEMENTATION-SLICING.md`](./IMPLEMENTATION-SLICING.md)
- Free plan capacity: [`LINEAR-CAPACITY.md`](./LINEAR-CAPACITY.md)

## Issue lifecycle

通常の実装Issue:

```text
Backlog -> Todo -> In Progress -> Done
                         \-> In Review -> Done
```

- `Backlog`: contract / plan / prerequisiteが未ready。
- `Todo`: Ready Queue。実装可能だがimplementation lane未割当、またはsafe checkpointで再開待ち。
- `In Progress`: `main`または`sub` laneでimplementation / fixを現在実行中。
- `In Review`: implementationはintended baseへmerge済みでrequired Manual E2Eだけが残る。
- `Done`: implementation / required E2E / Done freshnessがすべて完了。

Research / Review等、PRを伴わないIssueはWork自体が完了した時点でDoneへ進めてよい。

## Status synchronization precedence

statusは次の順で決める。

1. completion gateを満たす → `Done`。
2. implementation merge済みでrequired Manual E2Eのみ残る → `In Review`。
3. `main` / `sub` laneでcurrent implementation / fixを実行中 → `In Progress`。
4. 上記でないunstarted / checkpoint-pause / next-slice待ちWork → readinessにより`Todo`または`Backlog`。

Readyであることだけを理由にIn Progressへしない。実lane assignmentとexecution開始が必要。

[`CHECKOUTS.md`](./CHECKOUTS.md) の`RELEASE-PENDING`はphysical lane cleanup stateであり、current implementation executionではない。local checkoutがTask branchに残っている、latest `origin/main`へのfast-forwardがまだ、等のdeterministic cleanupだけを理由にIssueを`In Progress`へ保持しない。

## Fixed implementation capacity

implementation concurrencyは [`CHECKOUTS.md`](./CHECKOUTS.md) の物理laneでhard capする。

```text
main lane: max 1 In Progress implementation track
sub lane:  max 1 In Progress implementation track
```

通常、implementationとして`In Progress`になれるIssueは最大2件。

例外はimplementationではないResearch等が同じstatusを使う場合だが、そのWorkを3つ目のrepository implementation trackとして扱ってはならない。

両implementation laneがBUSYまたは新規割当不能なら、新しいReady implementation Issueは`Todo`に置く。3つ目のbranch / worktree / direct-GitHub executionを作らない。`RELEASE-PENDING` laneもcleanup完了まで新Issueへ割り当てない。

## Issue Authoring is not implementation occupancy

[`CHAT-WORKFLOW.md`](./CHAT-WORKFLOW.md) のIssue Authoringは、Issue作成 / Bug調査 / product相談 / contract策定 / acceptance整理 / dependency整理等のWork-management activityであり、repository implementation laneのoccupancyではない。

- Issue Authoring chatの同時実行数に上限を設けない。
- Authoringだけを理由に`In Progress`へ進めない。
- Authoring chatは`main` / `sub` / `e2e` laneをclaimしない。
- `Contract: Ready`かつrequired Manual E2E plan / blocker条件も満たしたimplementation待ちWorkは原則`Todo`。
- implementation開始は必ず後述のIn Progress startup gateで実lane assignmentと同時に行う。

複数Authoring chatが同じIssueを編集し得るため、Linear write前にはcurrent Issue / relevant commentsを再取得し、別chatのcurrent変更を消さない。競合するproduct decision / scope / acceptanceはlast-write-winsで上書きしない。詳細は`CHAT-WORKFLOW.md`。

## Backlog

主に次の間はBacklog。

- `Contract: Pending`または`Contract: Blocked`;
- required Manual E2E planが未確定;
- unfinished `blockedBy` relationあり;
- explicit contract re-auditでcurrent implementation contractをまだ再確定していない。

## Todo

implementation開始可能なReady Queue。

原則:

- `Contract: Ready`;
- Manual E2E plan確定済みまたは`Not Required`;
- unfinished blockerなし;
- 現在implementation laneでexecutionを行っていない。

previous remote branch / PRが存在しても、safe checkpointでlaneをreleaseして再開待ちならTodoにしてよい。その場合はIssue checkpointからremote stateを一意に復元できること。

intermediate merge後にremaining acceptanceがあり、次sliceをまだ実際に開始していない場合も、ReadyならTodoへ同期する。local laneが`RELEASE-PENDING`であることはTodoへのtransitionを妨げない。

## In Progress startup gate

implementation IssueをIn Progressへ進めるとき、同じstartup checkpointで:

1. latest remote repository / current Issueを確認;
2. current sliceを確定;
3. 3-lane local preflight;
4. FREEな`main`または`sub`を選択;
5. Base checkpoint SHAを固定;
6. Task branchをcheckout;
7. IssueをIn Progressへ変更;
8. `Implementation checkpoint`をCommentへ記録。

標準記録:

```text
Implementation checkpoint
- Lane: main | sub
- Base checkpoint: <sha>
- Branch: <branch>
- PR / pushed head: <pr or none>
- Current slice: <semantic boundary>
- Completed acceptance: <none or summary>
- Remaining acceptance: <summary>
- Next safe checkpoint: <implementation | integration | merge>
```

細かなcommit log、generic policy、過去chatは複製しない。

## Base checkpoint immutability

Issueがactive sliceとしてIn Progressの間、remote mainが進んでもCommentのBase checkpointをroutine refreshしない。

- unrelated main advance → current Base checkpoint維持;
- material contract invalidation → current workをremote保存しsafe checkpointで停止;
- integration checkpoint到達 → latest mainを確認し、Lunaがintegrationを行う;
- integration完了後に必要ならcheckpointへintegrated base / headを追記。

途中同期を前提にLinear recordを書き換えない。

## Pause / release

Taskをpauseするとき、current workがremoteへ保存済みでsafeにlane releaseできるなら:

- Readyで未blocked → `Todo`;
- contract未ready / blocked → `Backlog`;
- Implementation checkpointへpushed head / remaining acceptance / next actionを記録;
- local laneを [`CHECKOUTS.md`](./CHECKOUTS.md) に従ってrelease。

Issueが未完了でもlaneを保持し続ける必要はない。

local checkout cleanupが即時完了せずlaneが`RELEASE-PENDING`になっても、Issue statusは上記Work stateへ先に同期してよい。`RELEASE-PENDING`は新Taskのlane assignmentを止めるが、前Issueのimplementation executionを継続扱いにはしない。

**chat session rotation alone is not a Task pause.** 同じWorkを継続するためにchatだけを交換する場合、rotationだけを理由にstatus、lane ownership、Base checkpoint、branch、current sliceを変更しない。chat-onlyで外部stateから復元できない重要情報だけ必要に応じてcheckpointする。詳細は`CHAT-WORKFLOW.md`。

## In Review

implementationはmerge済みだがrequired Manual E2Eが未完了のWork。

典型:

```text
In Review + manual_e2e_only + Manual E2E: Ready to Run
In Review + manual_e2e_only + Manual E2E: Running
In Review + manual_e2e_only + Manual E2E: Deferred
```

`manual_e2e_only`は**implementation / review / merge / management workがなく、required Manual E2Eだけが残るleaf Issue**にだけ付ける。

PR open / CI / blocking review中をIn Reviewとは呼ばない。

Manual E2Eは`e2e` laneだけを使う。実行開始時はtested commit / stable refを固定し、E2E markerとIssue Commentを同期する。

merge済みでrequired Manual E2Eだけが残るなら、implementation laneが`RELEASE-PENDING`でもIn Reviewへ進める。physical cleanup完了をIn Review transitionのgateにしない。

## Manual E2E failure

confirmed implementation failureが出たら`manual_e2e_only`条件を失う。

1. `manual_e2e_only`を外す;
2. `Manual E2E: Failed`を維持;
3. fix contract / sliceを確定;
4. FREEな`main` / `sub`へ割り当てた時点で`In Progress`;
5. Luna fix / merge後、only E2E remainsなら`manual_e2e_only + In Review`へ戻す;
6. new exact tested commitでaffected E2E unitをrerun。

E2E failureだからという理由で`e2e` checkoutをimplementation laneへ変えない。

## Done

実装Issueの原則:

- implementationがintended baseへmerge済み;
- required Manual E2Eが`Passed`または`Not Required`;
- unfinished blockerなし;
- Done-before Ready contract freshness check完了。

`Deferred` / `Running` / `Failed`のままDoneにしない。

local implementation laneが`RELEASE-PENDING`であること自体はDone blockerではない。DoneはWork completionを表し、lane cleanupは`CHECKOUTS.md`のcapacity stateとして別に完了させる。

## Done-before Ready contract freshness check

IssueをDoneへ進める直前に、今回完了するWorkによって前提が変わり得る未完了`Contract: Ready` Issueを確認する。

優先対象:

- direct dependent;
- same subsystem / surface;
- same semantic owner / API / command / DSL surface。

latest remote `main`とactual implementationを基準に、owner / API / syntax / behavior / fixture / E2E step等のfact driftを確認する。

fact driftだけで既決定semantics / scope / acceptanceが一意に維持できるならReadyのままrefreshしてよい。product / UX / scope / compatibilityの再選択が必要ならPendingへ戻す。

別chatが担当中のactive Issueをfreshnessだけの理由で勝手にlane移動 / status変更しない。必要ならdriftをそのTaskへ記録する。

## Labels

正式Work Issueにはtype labelとは別に:

- `Contract` groupから1つ: `Pending | Blocked | Ready | N/A`;
- `Manual E2E` groupから1つ: `Plan Pending | Ready to Run | Running | Deferred | Failed | Passed | Not Required`。

### `manual_e2e_only`

leaf Issueでrequired Manual E2Eだけが残るexecution-state label。In Reviewと組み合わせる。

### `only_chatgpt`

**廃止済み。新規付与しない。**

既存unfinished Issueに残っている場合は、current contract / statusを壊さずlabelだけ除去する。execution ownerはlabelではなくfixed implementation lane + Luna policyで決まる。

Done / archived historical Issueからの一括除去は必要ない。履歴上残っていてもcurrent execution authorityには使わない。

## Parallel footprint / reservation

旧`only_chatgpt`運用のParallel footprint、reservation、race winner、unbounded semantic parallelismは廃止。

current parallel stateは次だけで表現する。

- `main` lane current Issueまたは`RELEASE-PENDING` cleanup state;
- `sub` lane current Issueまたは`RELEASE-PENDING` cleanup state;
- `e2e` lane current tested Issue;
- each active IssueのBase checkpoint / branch / pushed head。

Issue Authoring chatはこのexecution parallel stateへ数えない。

semantic interferenceを発見した場合はdependent laneをsafe checkpointで止め、prerequisite merge後のintegration / restart checkpointで解決する。

## Decomposition and parent handling

Issueを複数leafへ完全分解し、元Issueがremaining acceptanceを持たない場合:

- research / decomposition Work自体が完了 → Done可;
- feature delivery scopeをleafへ完全移管 → child identifiersを記録してCanceled可;
- aggregate Manual E2E / final integration等を親が実際にownerする場合だけparentを残す。

tracking parentをimplementation laneへ割り当てない。

## Required metadata on create

正式Issue作成時は最低限:

1. state;
2. Contract label;
3. Manual E2E label;
4. type label;
5. known dependency relation。

新規Issueはexecution laneを予約しない。実装開始時だけlane assignmentを行う。

## Ready Queue synchronization

次のcheckpointでunstarted / implementation再開待ちIssueのReady判定を同期する。

1. ContractがReadyになった;
2. Manual E2E planが確定した;
3. blocker relationが変わった;
4. blockerがDoneになった;
5. In Progress executionが終了した / laneをrelease checkpointへ進めた;
6. IssueをDoneへ進める。

Ready条件を満たすimplementation待ちWorkはTodo。lane不足や`RELEASE-PENDING` cleanupだけを理由にBacklogへ落とさない。

## Idea Inbox

軽い思いつきは常設 `SAY-55 — Idea Inbox — future work / 思いつきメモ`へ追記する。

- まだ独立Workとして着手しない案は新規Issue化しない;
- formal research / spec / implementation / Bug / Verificationへ進む時点で重複検索してIssue化;
- 切り出し元は`-> SAY-xx`等で履歴を残す;
- Inbox自体は`Contract: N/A + Manual E2E: Not Required`。

## Post-write verification

status / labels / comments / relationsを更新したcheckpointでは、必要な対象をread-backして意図したcurrent stateになったことを確認する。
