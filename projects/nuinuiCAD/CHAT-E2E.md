# nuinuiCAD E2E chat

## Purpose

E2E chatはrequired Manual E2Eを実行・再開し、tested commit / evidence / PASS-FAIL-BLOCKEDをcurrent external stateへ同期するためのchat。

実行capacityは [`LANES.conf`](./LANES.conf) に宣言された`role=human-test` laneの数から導出する。各Human-test laneは同時に1つのgenerationだけを保持する。Judgment / Executor / PASS-FAIL-BLOCKEDは [`MANUAL-E2E.md`](./MANUAL-E2E.md) をauthorityとする。

E2E chatを新しく作っただけではHuman-test laneをclaimしない。tested commit / marker / Issue checkpointと選択laneを固定した時点でexecutionが開始する。

## Execution boundary

- Manual E2Eはmanifestで`role=human-test`と宣言されたlaneだけで行う。
- implementation failureが確認された場合、Human-test checkoutでproduct codeを修正しない。fixはFREEなdeclared implementation laneへ戻す。
- tested commit、stable ref、marker、Issue checkpointの扱いは`CHECKOUTS.md` / `MANUAL-E2E.md` / relevant host-specific ownerをauthorityとする。
- VS Code hostなら[`VS-CODE-E2E.md`](./VS-CODE-E2E.md)、ExecutorがLunaなら[`LUNA-E2E-PLAYBOOK.md`](./LUNA-E2E-PLAYBOOK.md)も読む。
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
-> e2e-start / E2E handoff
```

implementation laneのrelease anomalyが残る間はnormal E2Eをstartしない。`BUSY`、`BLOCKED`、`RELEASE-PENDING`はcapacity unavailableであり、physical `FREE`を推測しない。selected Human-test laneが`BUSY`ならIssueは`In Review`で待ち、implementation capacityを保持しない。

## Canonical same-terminal startup handoff (#168)

normal startupでは、ChatGPTがsemantic intentをfixした後、Humanは次のnamed generator commandだけを同じterminalで実行する。

```bash
nuinui e2e-start-command \
  --issue SAY-123 \
  --tested-ref <full-tested-sha> \
  --executor <human|luna> \
  --fixture <absolute-fixture-path> \
  [--lane <human-test-lane>] [--locale <default|ja>] [--port <port>]
```

`e2e-start-command`はread-onlyでruntime manifestと既存Human-test classifierをfreshに検証し、唯一のHuman-test laneだけを機械的に省略解決する。複数laneでlaneを省略した場合、blocked state、dirty checkout、malformed marker/session、別Issue/refのBUSY stateは推測せず`BLOCKED`にする。成功時は既存`e2e-start`と`nuinui-e2e-prepare prepare`のshell-safeな`&&` continuationを出力するので、Humanはその行をChatGPTへ戻さずverbatimに実行する。

generator outputがterminal formatting authorityであり、ChatGPTはlane/ref/prepare orderingを再構成しない。`--executor`はChatGPT/Sol Highが決めるcaller-controlled intentで、helperはHuman/Lunaを分類せず、Luna promptやtest oracleも生成しない。Human pathはsetup後にHuman E2Eへ、Luna pathは既存prepare outputのshort `handoff=` identity/pathをLuna playbookへ渡す。generationが`BLOCKED`または利用不能なときだけ、explicit preflight / diagnosis / recoveryへ戻る。

## Confirmed Manual E2E implementation failure

confirmed Manual E2E implementation failureは次のtransitionで処理する。

```text
E2E FAIL confirmed
-> preserve Manual E2E: Failed evidence
-> remove `manual_e2e_only`
-> Linear status = Todo
-> remain Todo during fix contract / re-audit / dependency organization / rerun-plan synchronization
-> synchronize focused contract / fix / rerun requirements
-> later select a currently FREE declared implementation lane
-> start a new durable implementation generation
-> only after canonical begin/start success change status to In Progress
```

pre-E2E implementation claimをreuseまたはrestoreしない。E2E failure後は、fix contract、re-audit、dependency organization、rerun-plan synchronizationを行っている間も`Todo`に保つ。laterにFREEなdeclared implementation laneを選択し、新しいgenerationをcanonical begin/startで開始する。successful canonical begin/startが返るまで`In Progress`へ変更しない。Manual E2E PASS/FAIL judgment semanticsと#74 closure orderingは変更しない。

## Human E2E closure handoff

Sol High / ChatGPTがsuccessful closureを承認した後、Canonicalなclosure handoffはHumanが同じterminalから次のnamed commandを1回実行する。

```bash
nuinui-e2e-prepare closure-command --issue <Issue> [--lane <human-test-lane>]
```

The helper fresh-reads the local marker, session, cleanup receipt, release receipt, checkout, and manifest authority, then serializes the existing public stages in `cleanup -> e2e-release -> closure-check` order. Humanはtested ref、E2E root、laneを手でsubstituteしない。Omitted lane is accepted only when exactly one matching generation for the requested Issue is proved; otherwise the helper blocks. An explicit lane is a caller constraint and must match the requested generation.

cleanup成功後はtested same-Issue markerが残るnormalなrelease-ready stateであり、markerを削除するのはidentity-bearing `e2e-release <Issue> <tested-ref>`である。releaseはstrict marker、caller identity、session不在、clean detached checkout、authoritative `origin/main`を照合し、durable receiptを先に保存する。markerがないexact duplicate releaseはmatching receiptとidle authoritative checkoutをread-onlyで証明できる場合だけno-opとして受理する。`closure-check`はrelease後のfinal read-only closure proofとしてだけ実行し、cleanupとe2e-releaseの間には置かない。同一Issue markerがある間はclosure-checkが`BLOCKED`になるsemanticsを変更しない。same commandのexact duplicate成功では、追加のpreflight/status/confirmationやHuman handbackを要求しない。Manual E2EのPASS/FAIL semanticsは[`MANUAL-E2E.md`](./MANUAL-E2E.md)のまま維持する。

Exact duplicate cleanup / releaseの既存success envelopeはそのまま次stageへ継続する。既にrelease済みの場合、cleanup receiptがcleanup成功を証明し、cleanup ownerのpost-release duplicateが要求されないときだけrelease duplicate -> closure-checkへ進む。各stageは自身の実行時authorityをfreshに再検証し、`BLOCKED` / `ERROR`では後続stageを短絡する。Humanはその診断をChatGPTへ返し、PASS / FAIL judgmentおよびHumanのstop / pause semanticsは従来どおり維持する。

## Chat rotation / recovery

E2E chatのrotation自体はTask pauseではない。tested commit、marker、lane ownership、Manual E2E stateをrotationだけで変更しない。

新chatで再開する場合は[`CHAT-WORKFLOW.md`](./CHAT-WORKFLOW.md)のexternal-state recovery順に従い、current Issue / tested ref / actual e2e lane stateから再構築する。過去chatのsummaryだけでcurrent tested stateを決めない。

markerとactive sessionが別世代に分かれた場合だけ、owner documentのexact proofを満たしたうえで、選択したHuman-test laneを明示して次を使う。marker/sessionが一致する、caller identityと実状態が違う、rootやhandoffが不正、process ownershipが証明できない、またはsnapshotが変化した場合は`BLOCKED`であり、marker・session・rootを手で削除しない。

```text
nuinui-e2e-prepare recover-split <human-test-lane> <marker-issue> <marker-ref> <session-issue> <session-ref> <e2e-root>
```

この例外経路は、stale session rootに属すると証明できるprocess・handoff・rootだけを停止／削除し、marker Bとcheckout Bを保持したままsessionを除去して、canonical statusをread-backする。成功後はgeneration Bの通常prepareを新しいexact identityで開始する。

prepare ownerが終了して`kind=preparing` reservationだけが残った場合は、markerとcheckoutが同じexact generationであることを確認してから、選択したHuman-test laneを明示し、次を使う。

```text
nuinui-e2e-prepare recover-preparing <human-test-lane> <Issue> <tested-ref> <e2e-root>
```

この経路はrecorded prepare PIDがdeadであること、handoff（存在する場合）とroot内の全processのownership、marker/session snapshotの不変性を証明できた場合だけ、stale preparationのprocess・handoff・root・preparing sessionを除去する。live owner、wrong/active/malformed identity、foreignまたはambiguous artifact、concurrent changeは`BLOCKED`であり、markerとcheckoutを変更しない。

## Loading rule

E2E chatでは [`CHAT-WORKFLOW.md`](./CHAT-WORKFLOW.md) とこのdocumentを読み、READMEのManual E2E loading ruleに従う。

## Maintenance rule

このdocumentはE2E chat固有のlifecycle boundaryだけをownerする。Manual E2E semantics、host setup、Luna execution playbook、checkout detailはそれぞれのowner documentへ置く。
