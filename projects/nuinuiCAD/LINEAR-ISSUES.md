# nuinuiCAD Linear Issue workflow

## Purpose

Linear Issueのstatus、readiness、execution-lane checkpoint、labels、Done freshnessを定義する。

- chat roles / Issue Authoring / rotation: [`CHAT-WORKFLOW.md`](./CHAT-WORKFLOW.md)
- lane capacity / durable ownership: [`CHECKOUTS.md`](./CHECKOUTS.md)
- Manual E2E: [`MANUAL-E2E.md`](./MANUAL-E2E.md)
- contract judgment: [`CONTRACT-DECISIONS.md`](./CONTRACT-DECISIONS.md)
- implementation slicing: [`IMPLEMENTATION-SLICING.md`](./IMPLEMENTATION-SLICING.md)
- Free plan capacity: [`LINEAR-CAPACITY.md`](./LINEAR-CAPACITY.md)

## Issue lifecycle

通常の実装Issue:

```text
Backlog -> Todo -> In Progress -> Done
                         \-> In Review -> Done
```

- `Backlog`: contract / plan / prerequisiteが未ready。
- `Todo`: Ready Queue。実装可能だがimplementation lane未割当、またはsafe checkpointで再開待ち。
- `In Progress`: manifest-declared implementation laneでimplementation / fixを現在実行中。
- `In Review`: implementation merge済みでrequired Manual E2Eだけが残る。
- `Done`: implementation / required E2E / Done freshness完了。

Research / Review等、PRを伴わないIssueはWork自体が完了した時点でDoneへ進めてよい。

## Status synchronization precedence

1. completion gateを満たす → `Done`。
2. implementation merge済みでrequired Manual E2Eのみ残る → `In Review`。
3. declared implementation laneでcurrent implementation / fixを実行中 → `In Progress`。
4. それ以外のunstarted / checkpoint-pause / next-slice待ち → readinessにより`Todo`または`Backlog`。

Readyだけを理由にIn Progressへしない。actual durable lane assignmentとexecution開始が必要。

[`CHECKOUTS.md`](./CHECKOUTS.md)の`RELEASE-PENDING`はphysical cleanup stateでありcurrent implementation executionではない。cleanupだけを理由にIssueをIn Progressへ保持しない。

## #129 release-before-E2E barrier

implementation mergeとauthoritative read-backでrequired Manual E2Eだけが残ることを確認したIssueでは、normal pathとしてstatus bookkeepingより先にexact current implementation generationをreleaseする。

```text
merged + E2E-only evidence
-> exact nuinui release
-> IMPLEMENTATION RELEASED / lane FREE
-> Lane release checkpoint record / read-back
-> In Review synchronization
-> normal E2E startup
```

successful complete release envelopeの後、physical FREEを再発見するための別preflightを要求しない。physical implementation cleanup stateとWork statusは別authorityだが、normal final-merge operation orderではscarce implementation capacityのreleaseを先に完了する。

post-merge E2E-only release anomalyでは、最初のrelease attemptがfail / interruptedした後にauthoritative merged + E2E-only evidenceへ従ってIssueを`In Review`へ同期し、すでに`In Review`ならそのまま保つ。physical declared implementation laneが`BUSY`、`BLOCKED`、または`RELEASE-PENDING`でも、old durable slotが残っていることだけを理由にowner Issueを`In Progress`へreconcileしない。interrupted cleanupを含むcleanup anomaly中のlaneはactual `FREE`が証明されるまでoccupied / unavailable capacityとして扱う。

この間に unrelated new implementation admissionを判定する場合も、そのlaneはunavailableとして数える。ただし、そのlaneのowner Issueをcurrent implementation `In Progress`集合へ戻してはならない。release / recoveryが成功した後、未記録ならLane release checkpointをrecordしてread-backし、laneを通常の`FREE` capacityへ戻す。release anomalyが解消するまでnormal E2E startupは行わない。

このexceptionはmerged + E2E-only evidenceがあるpost-merge cleanupに限る。通常のactive implementationで、同じevidenceなしにBUSY laneとstatusが一致しない場合は、既存のoccupancy reconciliationを変更せずfail-closedにする。

## Declared implementation capacity

```text
each manifest-declared implementation lane: max 1 implementation track
```

all implementation lanesがBUSYまたは新規割当不能ならReady implementation IssueはTodoに置く。追加のbranch / worktree / direct-GitHub source implementationを作らない。RELEASE-PENDING laneもcleanup完了まで新Issueへ割り当てない。

Research等が同じstatusを使っても3つ目のrepository implementation trackとして扱わない。

## Issue Authoring is not implementation occupancy

Issue AuthoringはIssue作成 / Bug調査 / product相談 / contract策定 / acceptance整理 / dependency整理等のwork-management activityでありrepository implementation lane occupancyではない。

- Authoring chat数にexecution-lane上限を適用しない。
- AuthoringだけでIn Progressへ進めない。
- Authoring chatはexecution laneをclaimしない。
- Contract Readyでimplementation待ちなら原則Todo。
- implementation開始はactual lane transitionと同時に行う。

複数chatが同じIssueを編集し得るためLinear write前にはcurrent Issue / relevant commentsを再取得し、別chatのcurrent changeを消さない。

## Backlog

主に次の間はBacklog:

- `Contract: Pending`または`Contract: Blocked`;
- required Manual E2E plan未確定;
- unfinished `blockedBy`あり;
- explicit contract re-audit未完了。

## Todo

implementation開始可能なReady Queue。

原則:

- `Contract: Ready`;
- Manual E2E plan確定または`Not Required`;
- unfinished blockerなし;
- current implementation laneでexecution中ではない。

remote branch / PRが存在してもsafe checkpointでlane release済みならTodoにしてよい。その場合はIssue checkpointからremote stateとdurable generationを一意に復元できること。

intermediate merge後にremaining acceptanceがありnext slice未開始ならReadyでTodo。RELEASE-PENDINGだけを理由にBacklogへ落とさない。

## Implementation occupancy reconciliation

new implementation IssueをIn Progressへ進める前に、fresh manifest-derived lane evidenceとLinear current implementation `In Progress`集合をIssue identity単位で照合する。

正常状態では:

- physical BUSYなdeclared implementation laneのdurable slotから一意に読めるIssue集合;
- Linear current implementation In Progress集合;

が一致する。

件数<=2だけでは不十分。orphaned / stale In ProgressやBUSY laneに対応するstatus欠落があればnew start/resume前にcurrent remote / checkpoint / lane evidenceから同期する。既存authorityだけで安全に解消できない不一致はBLOCKED / UNKNOWNとしnew implementationを開始しない。

RELEASE-PENDING、FREE、Issue AuthoringだけのWorkはcurrent implementation In Progress集合へ含めない。

## In Progress startup gate

implementation IssueをIn Progressへ進めるとき:

1. latest remote repository / current Issue確認;
2. current slice確定;
3. fresh Linear current implementation occupancyとparallel-admission decisionからtarget FREE declared lane、Base checkpoint、branch、complete inventory expectationを選択;
4. Humanへ1つの`nuinui begin <implementation-lane> <SAY-123> <expected-base-sha> <branch> <complete-implementation-inventory>` commandを渡す;
5. `begin`のfull local audit / target FREE proof / exact inventory proofと`IMPLEMENTATION STARTED` envelopeを確認;
6. success確認後にIssueをIn Progressへ変更;
7. `Implementation checkpoint`をCommentへ記録;
8. status / checkpointをread-back。

known-Issueの通常pathでは、別Human `preflight`をstartup前に要求しない。Human terminal handoffではcommand提示、`CHECKING`、read-only verificationだけでIn Progressへ進めない。successful local transition resultが返り、lane / Issue / branch / Base / checkpoint / claimがintended handoffと一致した後で6以降を行う。`begin`がoccupancy mismatch / `BLOCKED`を返した場合はstartせず、current local stateとLinearをreconcileする。

標準record:

```text
Implementation checkpoint
- Lane: <manifest-declared implementation lane>
- Base checkpoint: <sha>
- Branch: <branch>
- Claim: <generation token>
- PR / pushed head: <pr or none>
- Current slice: <semantic boundary>
- Completed acceptance: <none or summary>
- Remaining acceptance: <summary>
- Next safe checkpoint: <implementation | integration | merge>
```

physical mutex / ownership authorityはGit-local durable metadata。Linear Claimはrestart / handoff identityを保存するexternal evidenceである。

new `nuinui begin`が返したclaimを同じlane assignmentのImplementation checkpointへ必ず保存する。そのgenerationのresume / release / handoffでClaimを維持し、same Issue / branch / Baseの別generationと混同しない。低レベル`start`を明示的に使う場合も、返されたlocal envelopeからclaim / checkpointを保存する。

resume restart identityは少なくとも`Lane + Issue + Base checkpoint + exact pushed checkpoint + Branch + Claim`。Baseをancestryだけから再推定した値やlocal slotからその場で読んだclaimをcaller expectationの代わりに使わない。

古いcheckpointにClaimがなく、current durable generationをindependent evidenceから一意に復元できない場合、そのrecordだけではresume / release authorizationに不十分。checkout appearanceからclaimを生成・補記せずBLOCKEDとしてexplicit reviewする。

細かなcommit log、generic policy、past chatはcheckpointへ複製しない。

## Base checkpoint immutability

Issueがactive sliceとしてIn Progressの間、remote mainが進んでもBase checkpointをroutine refreshしない。

- unrelated main advance → current Base維持;
- material contract invalidation → workをremote保存しsafe checkpointで停止;
- integration checkpoint → latest main確認後Luna integration;
- integration完了後に必要ならintegrated base / headを追記。

途中同期を前提にLinear recordを書き換えない。

## Pause / release

Taskをpauseするときcurrent workがremote保存済みでsafe release可能なら:

- Ready / unblocked → Todo;
- contract未ready / blocked → Backlog;
- Implementation checkpointへpushed head / remaining acceptance / next action / current Claimを記録;
- local laneを[`CHECKOUTS.md`](./CHECKOUTS.md)に従ってrelease。

Issue未完了でもlaneを保持し続ける必要はない。RELEASE-PENDINGになってもIssue statusはWork stateへ先に同期してよい。

**chat session rotation alone is not a Task pause.** rotationだけでstatus、lane ownership、Base、branch、Claim、sliceを変更しない。

## Lane release checkpoint

declared implementation lane release成功後はcurrent Issue Commentへrelease resultをcheckpointする。Issueが既にDoneでもrecordを追加し、release recordのためにreopenしない。

```text
Lane release checkpoint
- Lane: <manifest-declared implementation lane>
- Saved checkpoint: <exact pushed / integration checkpoint sha>
- Released claim: <generation token>
- Release result: RELEASED
- Idle branch/state: <default-branch> | DETACHED
- Idle HEAD: <sha>
- Lane state: FREE
```

Humanからfresh successful `nuinui release` outputが返された場合actual local evidenceとして使える。ChatGPTがLinear更新可能なら同じcontinuationでrecordしread-backする。successful complete release envelopeの後、release checkpointのためだけに別preflightを要求しない。

release envelopeの`issue`、`saved_checkpoint`、`released_claim`、`released_branch`、`idle_branch`、`idle_head`、`origin_main`、`clean=yes`、`state=FREE`をそのままLane release checkpointの入力として使う。Issue Done（Work completion）とphysical lane FREE（capacity cleanup）は引き続き別の条件である。

normal final closureは`merge / Work completion evidence -> exact nuinui release -> complete IMPLEMENTATION RELEASED envelope -> Lane release checkpointのrecord / read-back -> Work status synchronization -> closure`の順で行う。successful release envelope後にphysical FREEを再発見するためのHuman preflightは要求しない。

checkpointはphysical release成立条件そのものではない。actual local FREEはCHECKOUTS authority。ただしImplementation chat final closureにはrecord + Work status synchronization + Post-write verificationを含む。

## In Review

implementation merge済みでrequired Manual E2Eだけが残るWork。

典型:

```text
In Review + manual_e2e_only + Manual E2E: Ready to Run
In Review + manual_e2e_only + Manual E2E: Running
In Review + manual_e2e_only + Manual E2E: Deferred
```

normal final-merge pathでは、completed implementation generationのsuccessful releaseとLane release checkpoint record / read-backの後に`In Review`へ同期する。最初のrelease attemptがfail / interruptedした場合だけ、physical laneをunavailable capacityとして保持したままauthoritative merged + E2E-only evidenceに従って`In Review`へ同期してよい。

`manual_e2e_only`はimplementation / review / merge / management workがなくrequired Manual E2Eだけが残るleaf Issueにだけ付ける。PR open / CI / blocking review中をIn Reviewとは呼ばない。

Manual E2Eはe2e laneだけを使い、tested commit / stable refとmarker / Issue Commentを同期する。implementation laneのcleanup stateだけではWork statusを変更しないが、post-merge E2E-only release anomalyが解消するまでnormal E2E startupは行わない。

## Manual E2E failure

confirmed Manual E2E implementation failure:

1. `manual_e2e_only`を外す;
2. `Manual E2E: Failed` evidence維持;
3. [`MANUAL-E2E.md`](./MANUAL-E2E.md)に従いfocused contract re-audit、dependency、fix slice、affected rerun plan同期;
4. new implementation laneが未割当の間はstatusを`Todo`に保ち、fix contract / re-audit / dependency organization / rerun-plan synchronization中も`Todo`とする;
5. laterにcurrently `FREE`なdeclared implementation laneを選択し、新しいdurable generationを作るcanonical `begin` / `start`がsuccessした後だけ`In Progress`へ変更;
6. fix merge後にrequired E2Eだけが残れば、completed fix generationへ同じrelease-before-status barrierを適用してから`manual_e2e_only` + `In Review`へ戻す;
7. new exact tested commitでaffected E2E rerun。

これはconfirmed Manual E2E implementation failureからnew generation startまでのnarrow #129 exceptionであり、unrelated Pending / Blocked Issueの既存Backlog readiness precedenceを変更しない。

E2E failure / re-auditだけでIn Progressへ進めない。e2e checkoutをimplementationへ変えない。

## Done

実装Issueの原則:

- implementation intended baseへmerge済み;
- required Manual E2E `Passed`または`Not Required`;
- unfinished blockerなし;
- Done-before Ready contract freshness check完了。

final implementation mergeから直接Doneへ進むnormal pathでは、completed implementation generationを先にreleaseし、Lane release checkpointをrecord / read-backしてからDone synchronizationを行う。最初のrelease attemptがfail / interruptedした場合だけ、laneをunavailable capacityとして保持したままauthoritative completion evidenceに従ってDoneへ同期してよい。

Deferred / Running / FailedのままDoneにしない。implementation lane RELEASE-PENDING自体はDone blockerではない。DoneはWork completion、lane cleanupはcapacity stateとして別に完了させる。

## Done-before Ready contract freshness check

Done直前に、今回のWorkで前提が変わり得るunfinished `Contract: Ready` Issueを確認する。優先はdirect dependent、same subsystem/surface、same semantic owner/API/command/DSL surface。

latest remote mainとactual implementationを基準にfact driftを確認する。既決定semantics / acceptanceを一意に維持できるならReadyのままrefresh可。product / UX / scope / compatibility再選択が必要ならPendingへ戻す。

別chat active Issueをfreshnessだけで勝手にlane/status変更しない。

## Labels

正式Work Issueにはtype labelに加え:

- `Contract`: `Pending | Blocked | Ready | N/A`から1つ;
- `Manual E2E`: `Plan Pending | Ready to Run | Running | Deferred | Failed | Passed | Not Required`から1つ。

### `manual_e2e_only`

required Manual E2Eだけが残るleaf Issue用。In Reviewと組み合わせる。

### `only_chatgpt`

廃止済み。新規付与しない。unfinished Issueに残る場合はcurrent contract/statusを壊さずlabelだけ除去する。execution ownerはdeclared implementation lane + Luna policyで決まる。

## Parallel footprint / reservation

旧unbounded reservation modelは使わない。current parallel stateはmain lane ownership/release state、sub lane ownership/release state、e2e tested Issue、active IssueのBase / branch / Claim / pushed headだけで表現する。

Issue Authoring chatはexecution parallel stateへ数えない。semantic interference発見時はdependent laneをsafe checkpointで止め、prerequisite merge後のintegration / restartで解決する。

## Decomposition and parent handling

Issueをleafへ完全分解し元Issueにremaining acceptanceがなければresearch/decomposition完了でDone可、delivery scopeを完全移管した場合はchild identifiersを記録してCanceled可。aggregate E2E / final integration等を親がactualにownerする場合だけparentを残す。tracking parentをimplementation laneへ割り当てない。

## Required metadata on create

正式Issue作成時は最低限:

1. state;
2. Contract label;
3. Manual E2E label;
4. type label;
5. known dependency relation。

新規Issueはexecution laneを予約しない。actual implementation開始時だけlane assignmentを行う。

## Ready Queue synchronization

次のcheckpointでunstarted / resume待ちIssueのReady判定を同期する。

1. Contract Ready;
2. Manual E2E plan確定;
3. blocker relation変更;
4. blocker Done;
5. In Progress execution終了 / lane release checkpoint;
6. Issue Done transition。

Ready implementation待ちはTodo。lane不足やRELEASE-PENDINGだけを理由にBacklogへ落とさない。

## Idea Inbox

軽い思いつきは常設`SAY-55 — Idea Inbox — future work / 思いつきメモ`へ追記する。

- 未着手案は独立Issue化しない;
- formal research/spec/implementation/Bug/Verificationへ進む時点で重複検索してIssue化;
- 切り出し元は`-> SAY-xx`等で履歴を残す;
- Inbox自体は`Contract: N/A + Manual E2E: Not Required`。

## Post-write verification

status / labels / comments / relationsを更新したcheckpointでは、必要な対象をread-backして意図したcurrent stateになったことを確認する。
