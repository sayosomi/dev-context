# nuinuiCAD E2E chat

## Purpose

E2E chatはrequired Manual E2Eを実行・再開し、tested commit / evidence / PASS-FAIL-BLOCKEDをcurrent external stateへ同期するためのchat。

実行capacityは [`CHECKOUTS.md`](./CHECKOUTS.md) の`e2e` lane最大1 track。Judgment / Executor / PASS-FAIL-BLOCKEDは [`MANUAL-E2E.md`](./MANUAL-E2E.md) をauthorityとする。

E2E chatを新しく作っただけでは`e2e` laneをclaimしない。tested commit / marker / Issue checkpointを固定した時点でexecutionが開始する。

## Execution boundary

- Manual E2Eは`e2e` laneだけで行う。
- implementation failureが確認された場合、e2e checkoutでproduct codeを修正しない。fixはFREEな`main` / `sub` implementation laneへ戻す。
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
-> exact old main/sub generation released
-> successful IMPLEMENTATION RELEASED
-> Lane release checkpoint recorded and read back
-> physical implementation lane proven FREE
-> e2e-start / E2E handoff
```

implementation laneのrelease anomalyが残る間はnormal E2Eをstartしない。`BUSY`、`BLOCKED`、`RELEASE-PENDING`はcapacity unavailableであり、physical `FREE`を推測しない。e2e laneが`BUSY`ならIssueは`In Review`で待ち、main/sub capacityを保持しない。

## Confirmed Manual E2E implementation failure

confirmed Manual E2E implementation failureは次のtransitionで処理する。

```text
E2E FAIL confirmed
-> preserve Manual E2E: Failed evidence
-> remove `manual_e2e_only`
-> Linear status = Todo
-> remain Todo during fix contract / re-audit / dependency organization / rerun-plan synchronization
-> synchronize focused contract / fix / rerun requirements
-> later select a currently FREE main/sub lane
-> start a new durable implementation generation
-> only after canonical begin/start success change status to In Progress
```

pre-E2E implementation claimをreuseまたはrestoreしない。E2E failure後は、fix contract、re-audit、dependency organization、rerun-plan synchronizationを行っている間も`Todo`に保つ。laterにFREEなmain/sub implementation laneを選択し、新しいgenerationをcanonical begin/startで開始する。successful canonical begin/startが返るまで`In Progress`へ変更しない。Manual E2E PASS/FAIL judgment semanticsと#74 closure orderingは変更しない。

## Human E2E closure handoff

Canonicalなsuccessful closure handoffは、必ず次の順序で行う。

```text
nuinui-e2e-prepare cleanup <Issue> <tested-ref> <e2e-root>
nuinui e2e-release <Issue> <tested-ref>
nuinui-e2e-prepare closure-check <Issue>
```

cleanup成功後はtested same-Issue markerが残るnormalなrelease-ready stateであり、markerを削除するのはidentity-bearing `e2e-release <Issue> <tested-ref>`である。releaseはstrict marker、caller identity、session不在、clean detached checkout、authoritative `origin/main`を照合し、durable receiptを先に保存する。markerがないexact duplicate releaseはmatching receiptとidle authoritative checkoutをread-onlyで証明できる場合だけno-opとして受理する。`closure-check`はrelease後のfinal read-only closure proofとしてだけ実行し、cleanupとe2e-releaseの間には置かない。同一Issue markerがある間はclosure-checkが`BLOCKED`になるsemanticsを変更しない。same commandのexact duplicate成功では、追加のpreflight/status/confirmationやHuman handbackを要求しない。Manual E2EのPASS/FAIL semanticsは[`MANUAL-E2E.md`](./MANUAL-E2E.md)のまま維持する。

## Chat rotation / recovery

E2E chatのrotation自体はTask pauseではない。tested commit、marker、lane ownership、Manual E2E stateをrotationだけで変更しない。

新chatで再開する場合は[`CHAT-WORKFLOW.md`](./CHAT-WORKFLOW.md)のexternal-state recovery順に従い、current Issue / tested ref / actual e2e lane stateから再構築する。過去chatのsummaryだけでcurrent tested stateを決めない。

## Loading rule

E2E chatでは [`CHAT-WORKFLOW.md`](./CHAT-WORKFLOW.md) とこのdocumentを読み、READMEのManual E2E loading ruleに従う。

## Maintenance rule

このdocumentはE2E chat固有のlifecycle boundaryだけをownerする。Manual E2E semantics、host setup、Luna execution playbook、checkout detailはそれぞれのowner documentへ置く。
