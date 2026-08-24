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

## Chat rotation / recovery

E2E chatのrotation自体はTask pauseではない。tested commit、marker、lane ownership、Manual E2E stateをrotationだけで変更しない。

新chatで再開する場合は[`CHAT-WORKFLOW.md`](./CHAT-WORKFLOW.md)のexternal-state recovery順に従い、current Issue / tested ref / actual e2e lane stateから再構築する。過去chatのsummaryだけでcurrent tested stateを決めない。

## Loading rule

E2E chatでは [`CHAT-WORKFLOW.md`](./CHAT-WORKFLOW.md) とこのdocumentを読み、READMEのManual E2E loading ruleに従う。

## Maintenance rule

このdocumentはE2E chat固有のlifecycle boundaryだけをownerする。Manual E2E semantics、host setup、Luna execution playbook、checkout detailはそれぞれのowner documentへ置く。