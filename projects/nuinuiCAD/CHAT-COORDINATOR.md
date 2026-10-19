# nuinuiCAD Coordinator chat

## Purpose

Coordinator chatはProject全体のcurrent stateを整理し、次に進めるWorkと適切なchat roleをroutingする。chat自体はWork / repository / execution stateのsource of truthではない。current stateは[CHAT-WORKFLOW.md](./CHAT-WORKFLOW.md)のauthority hierarchyから再構築する。

Coordinatorはimplementation / Human Manual E2E checkoutを占有せず、Task admissionやcheckout capacityを認定しない。chat数やlaneの空き表示は実行許可にならない。

## Work selection

- Current GitHub Issues、bodyのscope / acceptance、material comments、dependencies、latest product repository / specから候補と優先順位を決める。過去chat、古いsummary、Linear Ready Queueだけで選定しない。
- Issueのreadiness / blocker、project運用rule、必要なIssue Authoring / Implementation / Human E2Eへのrole routingを扱う。[ISSUES.md](./ISSUES.md)がWork contract / readinessをownerする。
- `contract:blocked`は解除条件にmaterialな変化がなければ通常候補として繰り返し提示しない。依存Issueのclose、prerequisite成立、materialな外部capability変更が確認できたらfreshに再評価する。Humanの明示的な再確認依頼にも対応する。時間経過や候補不足だけではblock解除としない。

## Execution boundary

### GitHub-native D1: sequential only

Active GitHub-native D1は、登録済みの単一implementation checkoutで行うsequential Git-only実行である。別chatや旧SAY laneの`FREE`、legacy preflightは新しいnative Taskや並列実行の許可にならない。

Coordinatorは最新のGitHub Issue / contract / dependenciesとremote authorityを確認して実行roleへroutingするが、物理checkoutのinventory、admission、変更直前の再照合、停止・回復手順は重複実装しない。[CHECKOUTS.md](./CHECKOUTS.md)と[EXECUTION-HANDOFF.md](./EXECUTION-HANDOFF.md)が既存のHuman単一checkout-checkとAgentのbounded mutation recheckをownerする。Ready contractだけでは実行できない。

### Compatible pre-existing SAY only

実際に以前からadmitされた未完了SAY generationだけを、その元のIssue identity、claim、physical ownership、checkpoint、minimum applicable Linear lifecycleとともに継続する。新しいGitHub-native IssueへSAY / Linear statusを割り当てず、既存ownerを黙って移動、解放、nativeへ変換しない。

Legacy owner / checkpointとphysical executionのIssue identityに不一致、`RELEASE-PENDING`、または不明な状態がある場合、当該実行の新しいstart / continuationを`BLOCKED / UNKNOWN`として停止し、既存のownerで照合・回復する。[CHECKOUTS.md](./CHECKOUTS.md)、[EXECUTION-HANDOFF.md](./EXECUTION-HANDOFF.md)、[LINEAR-ISSUES.md](./LINEAR-ISSUES.md)の互換経路だけを使う。

旧multi-lane interference / parallel schedulingの詳細は[変更前のhistorical Coordinator](https://github.com/sayosomi/dev-context/blob/42183f525a7cd082b6ea1560ff8f3e393383a5a3/projects/nuinuiCAD/CHAT-COORDINATOR.md)にのみ残す。これは履歴参照であり、新たなparallel Task admissionの権限ではない。

### D2-C audit and occupancy exclusion

Implementation、別のevaluator audit、checkout transitionへroutingする前に、current Research/Improvement GitHub Issuesとmaterial commentsにあるaudit start / stop / independent final checkout proofを確認し、checkout ownerによるphysical occupancy proofと整合させる。未対応のaudit start、final proof不足、競合するactive / ambiguous implementation・Human E2E・legacy ownership、checkout authority不明は新規または競合する実行routingをblockする。D2-C audit開始には全unfinished implementationの終了も必要である。

既存SAY auditのreservation / minimum Linear checkpointはそのlegacy ownerに従う。Issue commentsはatomic lockではなく、記録の欠落やlegacy `FREE` preflightだけでidleを証明しない。正確な排他、admission、stop、recoveryは[CHECKOUTS.md](./CHECKOUTS.md)、[EXECUTION-HANDOFF.md](./EXECUTION-HANDOFF.md)、[ISSUES.md](./ISSUES.md)に委譲する。Coordinatorによる別のcheckout inventoryや追加gateは設けない。

## Role routing and handoff

- GitHub Issue authoring、contract / dependency調査 → [CHAT-AUTHORING.md](./CHAT-AUTHORING.md)
- GitHub-native D1 implementation → [CHAT-IMPLEMENTATION.md](./CHAT-IMPLEMENTATION.md)のGit-only route
- Compatible pre-existing SAY implementation / fix / integration → [CHAT-IMPLEMENTATION.md](./CHAT-IMPLEMENTATION.md)のlegacy route
- Required Human Manual E2E → [MANUAL-E2E.md](./MANUAL-E2E.md)、[CHECKOUTS.md](./CHECKOUTS.md)、[LOCAL-TOOLS.md](./LOCAL-TOOLS.md)。専用E2E chat roleは不要

Humanへroutingを提案する場合、current stateに合うroleと、対象Issue、確認すべきcurrent fact、次のcheckpointを含む短い、そのまま送れるhandoffを示す。既存chat継続が適切なら新chatを要求しない。未検証のlane、SHA、PR、tested commitを事実として書かない。候補選定やhandoffはIssue status、実行ownership、Task admissionを変更しない。

## Loading and maintenance

Coordinatorとして状態確認、Work選択、role routing、handoffを行うときは[CHAT-WORKFLOW.md](./CHAT-WORKFLOW.md)と本書を読み、必要なcurrent Issues / repository / checkout-owner evidenceを[README.md](./README.md)のloading ruleに従って確認する。Linear参照は既存SAY互換checkpointだけに限定する。

本書はCoordinator固有のselection / routing behaviorだけをownerする。Issue lifecycle、implementation execution、checkout、audit、Manual E2Eの手順を複製しない。
