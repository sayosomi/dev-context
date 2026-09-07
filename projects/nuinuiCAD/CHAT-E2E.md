# nuinuiCAD E2E chat

## Purpose

E2E chatはrequired Manual E2Eを実行・再開し、tested commit / evidence / PASS-FAIL-BLOCKEDをcurrent external stateへ同期するためのchat。

実行capacityは [`LANES.conf`](./LANES.conf) に宣言された`role=human-test` laneの数から導出する。各Human-test laneは同時に1つのgenerationだけを保持する。Judgment / PASS-FAIL-BLOCKED / repeated-failure stabilization semanticsは [`MANUAL-E2E.md`](./MANUAL-E2E.md) をauthorityとする。Manual E2E executorはcurrent policyでHuman固定であり、E2E chatはexecutor selectionを行わない。

E2E chatを新しく作っただけではHuman-test laneをclaimしない。tested commit / marker / Issue checkpointと選択laneを固定した時点でexecutionが開始する。

## Execution boundary

- Manual E2Eはmanifestで`role=human-test`と宣言されたlaneだけで行う。
- Manual E2E production-host unitはHumanが実行する。`Judgment: Objective | Human`はoracleの性質でありexecutor selectionではない。
- implementation failureが確認された場合、Human-test checkoutでproduct codeを修正しない。fixはFREEなdeclared implementation laneへ戻す。
- `E2E Stabilization Key`、qualifying failure、failure streak、stabilization cycle / re-entryはIssue / Manual E2E plan / result evidenceをauthorityとし、checkout markerやhelper metadataから推測しない。
- tested commit、stable ref、marker、Issue checkpointの扱いは`CHECKOUTS.md` / `MANUAL-E2E.md` / relevant host-specific ownerをauthorityとする。
- VS Code hostなら[`VS-CODE-E2E.md`](./VS-CODE-E2E.md)を読む。`LUNA-E2E-PLAYBOOK.md`はinactive historical reactivation referenceであり、normal E2E chatではload / useしない。
- Human向けVS Code host preparationでは[`LOCAL-TOOLS.md`](./LOCAL-TOOLS.md)に登録されたversioned Human E2E preparation helperがcurrent local cloneで利用可能なら、そのhelperをhandoffに使う。ChatGPTが同じlaunch / session lifecycleをinline shellとして再実装しない。
- versioned preparation helperの実行がunexpected error / hang / state mismatchになった場合、まずhelperの`status`とowner documentのrepair / fallback ruleで状態を分類する。session rootやtemporary artifactをad-hoc shellで探索・推測して別launcherへ迂回しない。
- `nuinui-e2e-prepare prepare`の`E2E SETUP ALREADY READY` / `mutation=no-op` / `READY FOR HUMAN E2E`、および`cleanup`の`E2E CLEANUP ALREADY COMPLETE` / `mutation=no-op`は、read-onlyでexact duplicateを証明したterminal no-opである。これらが返った場合は通常workflowを直接継続し、Humanへstatus、session / marker / process state、初回invocationの成功確認、またはduplicateだけを理由にしたprepare / cleanup再実行を求めない。near-match、stale、ambiguous stateは`BLOCKED`として扱う。

## Normal E2E startup after implementation release barrier (#129)

normal E2E startupは、preceding implementation generationが#129 handoff barrierをsuccessfully crossedした後だけ行う。必要な順序は次の通り。

```text
implementation merge / authoritative read-back complete
-> Issue synchronized to In Review / E2E-only state
-> exact old declared implementation generation released
-> successful IMPLEMENTATION RELEASED
-> Lane release checkpoint recorded and read back
-> physical implementation lane proven FREE
-> Manual E2E plan / stabilization eligibility revalidated
-> e2e-start / E2E handoff
```

implementation laneのrelease anomalyが残る間はnormal E2Eをstartしない。`BUSY`、`BLOCKED`、`RELEASE-PENDING`はcapacity unavailableであり、physical `FREE`を推測しない。selected Human-test laneが`BUSY`ならIssueは`In Review`で待ち、implementation capacityを保持しない。

Human-test laneが`FREE`でも、対象`E2E Stabilization Key`がgatedでre-entry requirements未完了ならstartしない。新しいtested SHAやmerged fixだけではre-entryを証明しない。gated keyは[`MANUAL-E2E.md`](./MANUAL-E2E.md)のre-entry recordが揃った後にだけnormal startupへ戻る。

## Canonical same-terminal startup handoff (#168)

normal startupでは、ChatGPTがsemantic intentをfixした後、Humanは次のnamed generator commandだけを同じterminalで実行する。

```bash
nuinui e2e-start-command \
  --issue SAY-123 \
  --tested-ref <full-tested-sha> \
  --executor human \
  --fixture <absolute-fixture-path> \
  [--lane <human-test-lane>] [--locale <default|ja>] [--port <port>]
```

`e2e-start-command`はread-onlyでruntime manifestと既存Human-test classifierをfreshに検証し、唯一のHuman-test laneだけを機械的に省略解決する。複数laneでlaneを省略した場合、blocked state、dirty checkout、malformed marker/session、別Issue/refのBUSY stateは推測せず`BLOCKED`にする。成功時は既存`e2e-start`と`nuinui-e2e-prepare prepare`のshell-safeな`&&` continuationを出力するので、Humanはその行をChatGPTへ戻さずverbatimに実行する。

`--port`はcaller-controlledのCDP portである。Human-test laneが2つ以上宣言されている場合は、明示的な`--lane`と`--port`が必要で、lane名・宣言順・空き状況からportを推測または自動選択しない。Human-test laneが1つだけのsingleton topologyでは、`--port`省略時の既定port互換を維持する。

generator outputがterminal formatting authorityであり、ChatGPTはlane/ref/prepare orderingを再構成しない。Current active policyでは`--executor human`だけを渡す。helperがlegacy compatibilityとして別executor metadataを受理できても、E2E chatはそれをadvertise / selectしない。helperはtested ref、test oracle、stabilization eligibility、lane schedulingを決めず、GUI actionも実行しない。generationが`BLOCKED`または利用不能なときだけ、explicit preflight / diagnosis / recoveryへ戻る。

## Confirmed Manual E2E implementation failure

confirmed Manual E2E implementation failureは、actual-host triage後に[`MANUAL-E2E.md`](./MANUAL-E2E.md)のsame-key historyを分類してからroutingする。

1st pre-stabilization qualifying failureでgateが発火していない場合だけ、従来のnormal focused-fix transitionを使う。

```text
1st qualifying E2E FAIL confirmed
-> preserve Manual E2E: Failed evidence + stabilization key / streak=1
-> remove `manual_e2e_only`
-> Linear status = Todo
-> remain Todo during focused fix contract / re-audit / dependency organization / rerun-plan synchronization
-> synchronize focused contract / fix / one-rerun requirements
-> later select a currently FREE declared implementation lane
-> start a new durable implementation generation
-> only after canonical begin/start success change status to In Progress
```

pre-E2E implementation claimをreuseまたはrestoreしない。normal first-failure routeでも、fix contract、re-audit、dependency organization、rerun-plan synchronizationを行っている間は`Todo`に保つ。laterにFREEなdeclared implementation laneを選択し、新しいgenerationをcanonical begin/startで開始する。successful canonical begin/startが返るまで`In Progress`へ変更しない。Manual E2E PASS/FAIL judgment semanticsと#74 closure orderingは変更しない。

2nd pre-stabilization qualifying failure、completed stabilization cycle後のsame-key qualifying recurrence、またはHuman explicit stabilization overrideでは、このnormal symptom-fix transitionを開始せず、次のstabilization lifecycleへ進む。

## Repeated-failure stabilization lifecycle (#190)

stabilization gateが発火したら、current resultの意味を変更せずManual E2E Failed evidenceを保持する。Human overrideだけでgateが発火した場合も、実際に確認されていない追加product FAILを作らない。

```text
stabilization gate fires for <E2E Stabilization Key>
-> stop requesting further operations for that key
-> preserve completed PASS / FAIL / Human evidence
-> dependent remaining units = unexecuted where applicable
-> collect any required transient failure evidence before teardown
-> canonical current-generation closure
-> remove `manual_e2e_only`
-> Linear status = Todo while stabilization re-audit is active
-> cross-owner contract / state-model / ownership / testability re-audit
-> no symptom-only implementation start
-> no next same-key Human E2E generation
-> re-entry requirements complete
-> normal implementation / review / merge
-> fresh reverse-map + exact candidate qualification
-> normal E2E startup may resume
```

Current generationを閉じる前に、[`MANUAL-E2E.md`](./MANUAL-E2E.md)のtransient evidence-before-teardown ruleを満たす。必要なfailure stateを保存した後は、下記canonical closure handoffで`cleanup -> e2e-release -> closure-check`を完了する。marker/session/rootを手で削除してgateを表現しない。

Gate中はobserved symptomだけから実装を自動開始しない。mandatory stabilization re-auditがroot causeまたはexact unresolved failure boundary、adjacent owners inspected、各ownerのimplicated/ruled-out reasoning、consolidated repair scope、whole-chain regression coverageを記録するまでimplementation laneをclaimしない。material failure boundaryが未解決ならinvestigationを継続する。

Objective failureをHumanが発見した場合、re-entry前にautomated regressionまたはequivalent deterministic host qualificationへ移せるかを必ず評価する。実用上automateできない場合は理由とHuman host checkを残す必要を明示的に記録する。Human visual / UX / experiential judgmentはautomation gapとして消さない。

Gateはstabilization key単位であり、unrelated key / Issueは独立に実行可能。ただしHumanがqueue全体またはより広い範囲へstop / pauseを指示した場合はその指示を優先し、次のqueued E2E Issueへ機械的に進まない。

一度stabilization cycleを完了してre-entryしたkeyで後日qualifying failureが再発した場合は、1st/2ndのallowanceを再開せず即座にこのgateを再発火する。

## Human E2E closure handoff

Sol High / ChatGPTがcurrent generationのclosureを承認した後、product PASS、confirmed failure、stabilization gateのいずれであっても、Canonicalなclosure handoffはHumanが同じterminalから次のnamed commandを1回実行する。

```bash
nuinui-e2e-prepare closure-command --issue <Issue> [--lane <human-test-lane>]
```

The helper fresh-reads the local marker, session, cleanup receipt, release receipt, checkout, and manifest authority, then serializes the existing public stages in `cleanup -> e2e-release -> closure-check` order. Humanはtested ref、E2E root、laneを手でsubstituteしない。Omitted lane is accepted only when exactly one matching generation for the requested Issue is proved; otherwise the helper blocks. An explicit lane is a caller constraint and must match the requested generation.

cleanup成功後はtested same-Issue markerが残るnormalなrelease-ready stateであり、markerを削除するのはidentity-bearing `e2e-release <Issue> <tested-ref>`である。releaseはstrict marker、caller identity、session不在、clean detached checkout、authoritative `origin/main`を照合し、durable receiptを先に保存する。markerがないexact duplicate releaseはmatching receiptとidle authoritative checkoutをread-onlyで証明できる場合だけno-opとして受理する。`closure-check`はrelease後のfinal read-only closure proofとしてだけ実行し、cleanupとe2e-releaseの間には置かない。同一Issue markerがある間はclosure-checkが`BLOCKED`になるsemanticsを変更しない。same commandのexact duplicate成功では、追加のpreflight/status/confirmationやHuman handbackを要求しない。Manual E2EのPASS/FAIL semanticsは[`MANUAL-E2E.md`](./MANUAL-E2E.md)のまま維持する。

Exact duplicate cleanup / releaseの既存success envelopeはそのまま次stageへ継続する。既にrelease済みの場合、cleanup receiptがcleanup成功を証明し、cleanup ownerのpost-release duplicateが要求されないときだけrelease duplicate -> closure-checkへ進む。各stageは自身の実行時authorityをfreshに再検証し、`BLOCKED` / `ERROR`では後続stageを短絡する。Humanはその診断をChatGPTへ返し、PASS / FAIL judgmentおよびHumanのstop / pause semanticsは従来どおり維持する。

## Chat rotation / recovery

E2E chatのrotation自体はTask pauseではない。tested commit、marker、lane ownership、Manual E2E state、stabilization key / streak / completed-cycle / gate / re-entry evidenceをrotationだけで変更しない。

新chatで再開する場合は[`CHAT-WORKFLOW.md`](./CHAT-WORKFLOW.md)のexternal-state recovery順に従い、current Issue / tested ref / actual e2e lane state / preserved Manual E2E stabilization evidenceから再構築する。過去chatのsummaryだけでcurrent tested stateやsame-key rerun eligibilityを決めない。

markerとactive sessionが別世代に分かれた場合だけ、owner documentのexact proofを満たしたうえで、選択したHuman-test laneを明示して次を使う。marker/sessionが一致する、caller identityと実状態が違う、rootやhandoffが不正、process ownershipが証明できない、またはsnapshotが変化した場合は`BLOCKED`であり、marker・session・rootを手で削除しない。

```text
nuinui-e2e-prepare recover-split <human-test-lane> <marker-issue> <marker-ref> <session-issue> <session-ref> <e2e-root>
```

この例外経路は、stale session rootに属すると証明できるprocess・handoff・rootだけを停止／削除し、marker Bとcheckout Bを保持したままsessionを除去して、canonical statusをread-backする。成功後はgeneration Bの通常prepareを新しいexact identityで開始する。ただし対象keyがstabilization gateで停止中なら、recovery成功だけを根拠に新generationを開始しない。

prepare ownerが終了して`kind=preparing` reservationだけが残った場合は、markerとcheckoutが同じexact generationであることを確認してから、選択したHuman-test laneを明示し、次を使う。

```text
nuinui-e2e-prepare recover-preparing <human-test-lane> <Issue> <tested-ref> <e2e-root>
```

この経路はrecorded prepare PIDがdeadであること、handoff（存在する場合）とroot内の全processのownership、marker/session snapshotの不変性を証明できた場合だけ、stale preparationのprocess・handoff・root・preparing sessionを除去する。live owner、wrong/active/malformed identity、foreignまたはambiguous artifact、concurrent changeは`BLOCKED`であり、markerとcheckoutを変更しない。

## Loading rule

E2E chatでは [`CHAT-WORKFLOW.md`](./CHAT-WORKFLOW.md) とこのdocumentを読み、READMEのManual E2E loading ruleに従う。`LUNA-E2E-PLAYBOOK.md`はnormal E2E chatではloadしない。

## Maintenance rule

このdocumentはE2E chat固有のlifecycle boundaryだけをownerする。Manual E2E semantics、Human production-host setup、checkout detailはそれぞれのowner documentへ置く。Inactive Luna E2E materialは`LUNA-E2E-PLAYBOOK.md`だけに隔離する。