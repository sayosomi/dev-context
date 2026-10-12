# nuinuiCAD Coordinator chat

## Purpose

Coordinator chatはProject全体のcurrent stateを整理し、次に進めるWorkと適切なchat roleをroutingする。

chat自体はWork / repository / execution stateのsource of truthではない。current stateは [`CHAT-WORKFLOW.md`](./CHAT-WORKFLOW.md) のauthority hierarchyに従って再構築する。

Coordinator chatはimplementation laneやManual E2E laneを占有しない。

## Responsibilities

主な用途:

- current GitHub Issue state / contract readiness / blockersの確認
- 次に進めるWorkの選択と優先順位付け
- legacy executionに適用されるphysical lane / Linear checkpoint / GitHub stateの整合確認
- project運用ruleの検討
- Issue Authoring / Implementation / E2E chatへの振り分け

新しいWorkの候補はcurrent GitHub Issuesとlatest repositoriesから選び、Issue bodyのscope / acceptanceとcurrent code / specを読む。Linear Ready Queueを使わない。過去chatや古いsummaryだけでcurrent候補を決めない。

GitHub-native IssueはC1後にauthoringできる。一般D1 activation checkpoint後はGit-only routeへroutingする。checkpoint前はstartupを止める。Ready contractや空きlaneだけでstartupせず、current Issueとcheckout safetyをfreshに確認する。

### Implementation occupancy reconciliation before routing

既存SAY executionのimplementationを継続・routingする前にfreshなmanifest-derived lane stateを利用できる場合、Coordinatorは全`role=implementation` laneのphysical occupancyと、該当するpre-existing SAY Issueのcurrent legacy Linear execution/status checkpointを照合する。GitHub-native IssueにLinear status checkpointを割り当てない。

照合は件数だけではなく**Issue identity単位**で行う。

- physical `BUSY` laneから一意に読めるpre-existing SAY Issueは、Linearに必要なcurrent execution checkpointを持つこと;
- 互換legacy lifecycle上のLinear implementation checkpointは、対応する`BUSY` implementation laneを一意に持つこと;
- `RELEASE-PENDING`、idle / `FREE` lane、authoring-only Workをactive implementationとして数えない。

不一致があれば、legacy implementationを継続・routingする前にcurrent remote / legacy Linear checkpoint / fresh lane evidenceからstale stateを解消する。既存authorityだけでは安全に解消できない不一致は`BLOCKED / UNKNOWN`として扱い、新しいstart handoffを出さない。

件数だけでは整合確認を満たさない。legacy physical declared laneから読めるIssue集合と、互換Linear lifecycle上のcurrent implementation checkpoint集合がidentity単位で一致していなければならない。

### Evaluator-audit execution exclusion

Before routing an implementation, another evaluator audit, or a checkout
transition, inspect current Research/Improvement GitHub Issues, their material
comments, and the physical checkout state. An unmatched evaluator-audit start,
missing final checkout proof, or ambiguous execution occupancy blocks routing
until explicit investigation and complete proof resolve it. Audit admission
also waits for all unfinished implementation execution to conclude. For a
compatible pre-existing SAY audit, continue to verify its existing legacy
reservation and minimum Linear checkpoint under the legacy owners. Issue
comments are operational checkpoints, not an atomic lock; absence of a known
comment or a `FREE` legacy preflight alone does not prove that execution is idle.
The physical admission and recovery details belong to
[`CHECKOUTS.md`](./CHECKOUTS.md) and [`EXECUTION-HANDOFF.md`](./EXECUTION-HANDOFF.md).

### Parallel admission gate

Humanが特定Issueのlane移動・再配置を明示せず、fresh lane stateとともにimplementation laneが`FREE`になったことを報告した場合、その報告を既存`BUSY` Issueのlane migration要求として解釈しない。既存`BUSY` laneのownershipを維持したまま、このsectionのparallel admission gateに従って`FREE` laneへ開始可能な別Issueを評価する。

あるimplementation laneが`BUSY`で、別のlaneが`FREE`なとき、CoordinatorはGitHub Issue readinessやLinear Ready Queueの順番だけでWorkを開始しない。compatible pre-existing SAY executionで並行開始が許可される場合だけ、先に**parallel interference risk**を評価し、相手laneと独立して進められる候補を扱う。C1はWork authorityを切り替えただけでdeclared capacityを追加していない。一般D1 activation checkpoint後のGitHub-native implementationは、[`CHECKOUTS.md`](./CHECKOUTS.md)の単一product checkout / sequential Git-only routeを使い、空きlaneを根拠にparallel startしない。

`FREE` laneはcapacityでありutilization targetではない。安全なparallel candidateがなければ、laneを`FREE`のまま残すことを正常な選択肢とする。

#### Active lane interference envelope

freshなrepository state、current Issue / 該当するlegacy checkpoint、current slice contractから、現在`BUSY`なlaneについて少なくとも次を整理する。

- primary semantic owner / boundary;
- current sliceが直接変更する、またはblocking fixで接続し得るshared owner / API / registry / composition root;
- unfinished prerequisite / downstream dependency;
- likely changed filesは補助signalとして利用する;
- merge後に別Taskのcontract refreshを起こし得るintegration surface。

file pathだけをreservationとして扱わない。異なるfileでも同じsemantic owner / shared primitiveを変更するWorkは干渉し得る一方、同じ大きなfileに触れる可能性だけで自動的に干渉確定とはしない。

#### Candidate change envelope

各Ready candidateについて、Issue本文に残った古いimplementation pathをそのまま信用せず、latest remote repositoryとcurrent contractから同じ観点のchange envelopeを作る。

候補は次で分類する。

- `LOW`: primary ownerが別で、shared semantic primitive / unfinished prerequisite / integration surfaceのmaterial overlapが見つからず、相手laneのmergeでcurrent contractが変わる蓋然性も低い。parallel startへadmitしてよい。
- `MEDIUM`: direct owner overlapは確定していないが、同じshared API / resolver / compiler boundary / central registry / composition rootへ接続する可能性、または相手laneのmergeでcontract refreshが必要になる具体的signalがある。独立性をcurrent authorityから一意に証明できない限りparallel startへadmitしない。
- `HIGH`: same semantic owner / shared primitiveを直接変更する、unfinished laneが実質prerequisiteである、または片方の未merge変更を前提にしなければ成立しない。parallel start禁止。

priority、blocker解消効果、Issue size等による通常のWork選定は**parallel admission後**に行う。高priorityであることは`MEDIUM` / `HIGH` interferenceを上書きしない。

互換legacy execution candidateのうち`LOW` interference candidateがなければ、Coordinatorは正式なrouting結果として`NO PARALLEL START`を選んでよい。この場合:

- `FREE` laneを無理に埋めない;
- 3つ目のbranch / worktreeを作らない;
- candidateをReadyから外す必要はない;
- 必要ならIssue Authoring、contract refresh、Research等のlaneを占有しないWorkを進めてよいが、空きcapacityを埋めるためだけにWorkを作らない。

利用可能なimplementation laneが`FREE`なら最初のTaskは通常のWork選定で開始してよい。追加のTaskを開始する時点では、既に開始したTaskをactive laneとしてこのgateを適用する。

candidateを選定してからactual startするまでにactive laneのscopeがshared ownerへ拡大したsignalがあれば、start handoff前にparallel admissionを再評価する。複数laneがactiveになった後のscope expansionは[`IMPLEMENTATION-SLICING.md`](./IMPLEMENTATION-SLICING.md)のre-evaluation triggerとして扱い、unfinished branch同士を同期して解消しない。

### Blocked Issue candidate routing

`contract:blocked` GitHub Issueは、block理由にmaterialな変化が確認できない限り、通常の「次に進めるWork」「次の調査候補」「Issue Authoring候補」として繰り返し提示しない。

ただし、dependency待ちの連続Workを止めない。GitHub Issue body / commentsでblocker relationの変化、blocker close、その他current prerequisiteの成立が確認された場合は、そのdependent Issueをfreshに再評価し、current stateに応じて候補へ戻す。

GitHub Issueで記録された外部platform capabilityやfuture foundation等を待つBlocked Workは、記録された解除条件へmaterialな変化を示すfresh signalがある場合、またはHumanが明示的に再確認を求めた場合だけ再調査する。単に未完了である、時間が経過した、他の候補が減った、という理由だけでは通常候補へ戻さない。

## Routing handoff rule

HumanへWork候補やroutingを提案するときは、候補ごとに、適切なchat roleとcurrent external stateに合わせた**そのまま送れる短いhandoff message**を併記する。

- 新chatが適切なら、そのchatの最初のmessageとしてそのまま使える文にする。
- existing chat継続が適切なら、新chat作成を勧めず、そのexisting chatへ送るmessageを提示する。
- handoff messageには、current stateから一意に言える範囲で、対象Issue、chat role、確認すべきcurrent fact、到達させる次のcheckpointを含める。
- lane、SHA、PR、tested commit等のfresh evidenceを確認していない場合、それらを確定事実として書かない。
- Issue Authoring候補を複数並行してよい場合は、declared implementation capacityと混同せず並行可能であることを示してよい。

具体的な定型文やIssue別テンプレートはこのdocumentへ保存しない。handoff messageはその時点のcurrent external stateから生成する。

## Role boundary

Coordinator chatはroutingとstatus整理をownerするが、role-specific executionは各ownerへ渡す。

- GitHub Issue作成 / 調査 / contract策定 → [`CHAT-AUTHORING.md`](./CHAT-AUTHORING.md)
- GitHub-native implementation after the general D1 activation checkpoint → [`CHAT-IMPLEMENTATION.md`](./CHAT-IMPLEMENTATION.md) Git-only route
- compatible pre-existing SAY implementation / blocking fix / integration → [`CHAT-IMPLEMENTATION.md`](./CHAT-IMPLEMENTATION.md) legacy route
- required Manual E2E → [`CHAT-E2E.md`](./CHAT-E2E.md)

Coordinatorで候補を選んだだけではIssue statusやlane occupancyを変更しない。実際のrole startup gateを省略しない。

## Loading rule

Coordinatorとしてcurrent status、次Work選定、routing、handoff message生成を行うときは、まず [`CHAT-WORKFLOW.md`](./CHAT-WORKFLOW.md) とこのdocumentを読む。

current factが必要な場合はREADMEのloading ruleに従い、current GitHub Issues / latest repository / relevant checkout stateを確認する。Linearはcompatible pre-existing SAY execution checkpointにだけ使う。

## Maintenance rule

このdocumentはCoordinator固有のrouting behaviorだけをownerする。Issue lifecycle、implementation execution、checkout、Manual E2Eの詳細を複製しない。
