# nuinuiCAD local tools

## Purpose

nuinuiCADで繰り返すmechanical / deterministicなHuman terminal operationを、version管理されたlocal helperとして安全に再利用する。

このdocumentはlocal helperの配置、利用、同期、verification、promotion / repair lifecycleをownerする。checkout / lane safety semanticsは[`CHECKOUTS.md`](./CHECKOUTS.md)をauthorityとする。

## Authority and local checkout

GitHub上の`sayosomi/dev-context`がauthoritative sourceであり、local cloneはcache / toolboxである。local cloneや過去chatをProject Contextのsource of truthにしない。

nuinuiCAD作業開始時はlocal cloneの有無にかかわらず、GitHub上のlatest [`README.md`](./README.md)を取得しloading ruleに従う。

標準local clone:

```text
/Users/yosomi/Code/dev-context
```

主要helper:

```text
/Users/yosomi/Code/dev-context/projects/nuinuiCAD/scripts/nuinui
/Users/yosomi/Code/dev-context/projects/nuinuiCAD/scripts/nuinui-e2e-prepare
```

このcloneはnuinuiCAD repositoryの4th checkoutではない。

candidate source / edit / test / promotionは次のpersistent single-track development worktreeで行う。

```text
/Users/yosomi/Code/dev-context-dev
```

標準production / cache / toolbox cloneはcandidate work中もpromoted artifactを保持し、merge / read-back後だけsyncする。

## Local sync rule

ChatGPTが承認済みdev-context create / update / deleteをGitHubへ反映した場合、GitHub authoritative read-backで確定したexpected valuesを使い、versioned helperでlocal cloneを同期する。

```bash
nuinui context-audit <expected-main> <expected-artifact-blob>
nuinui context-sync <expected-main> <expected-artifact-blob>
```

cloneがないことが分かっている場合だけ初回cloneを案内する。

```bash
git clone https://github.com/sayosomi/dev-context.git /Users/yosomi/Code/dev-context
```

Humanが実行する前にlocal sync済みとみなさない。versioned helperが未install、stale、broken、またはcurrent operationをsupportしていない場合だけ、同じGitHub read-backとmanual safety checkを満たしたfallbackとして次を提示する。

```bash
git -C /Users/yosomi/Code/dev-context pull --ff-only
```

local cloneがdirty、`main`以外、またはfast-forward不可能ならreset / stash / forceせず`BLOCKED:`で停止する。

## Versioned `nuinui` helper

current standalone helper version: `1.7.1`。

verify、direct public start、およびbeginは、既存のlifecycle ownerを呼ぶ前に新規requestのIssue / branch pairをstrictに検証する。branch全体からcase-insensitiveなSAY-Nを抽出して重複を除き、distinctなidentifierが1つだけでcaller Issueと一致する場合だけ通過する。複数のdistinct identifier、別Issueのみ、identifierなし、または不正なGit ref syntaxはactionableなERROR:で拒否する。このrequest境界は既存のdurable ownership parserとは分離され、保存済みslot / lock / release receiptの互換性を変更しない。

`preflight`、`begin`、`start`だけは、末尾のone-shot `--forensic-worktree <absolute-path>` pairを受け付ける。これはHuman-authorizedな、同じnuinuiCAD repositoryにregisteredされた正確に1つのextra worktreeをcurrent invocationのinventory exceptionとして認識するだけで、allowlistやmarkerなどのdurable stateを作らず、worktreeをexecution laneにはしない。pathはcanonical absolute directoryで、declared lane paths + supplied pathのregistered inventoryと完全一致しなければならない。継承環境変数やdirectory nameだけでexceptionを有効化しない。成功したactive invocationは`forensic_exception=active`とsupplied pathを表示し、invalid requestはmutation前にactionableな`forensic_exception=BLOCKED`としてfail closedする。

`nuinui preflight`のHuman copy boundaryは、`✈️ NUINUI PREFLIGHT RESULT`からコピーを開始し、`⭕ PREFLIGHT PASS`または`❌ PREFLIGHT BLOCKED`の直後で停止する。lane headingとstate decorationはmanifest role/stateから導出し、lane nameに依存しない。これは表示形式だけの変更であり、lane / preflight semantics、canonical internal evidence、durable stateは変更しない。

`nuinui release <implementation-lane> <merged-checkpoint> <claim>`は、post-mergeにlane checkoutだけがdriftした場合も、`CHECKOUTS.md`の狭いproof setをrelease中に満たすときだけ復旧する。claimed local refがcheckpointにある場合の differently named branch は、same-generation proof後にexisting claimed topicへ通常のexact `git switch`で戻す。claimed local refがmissingの場合は、current checkoutがcleanなnamed non-default branchで、current branch refとmerged checkpointがexact一致し、fresh authoritative default branch / Base ancestry / remote topic / worktree identityが再検証できるときだけ、release lock下でdurable slotのbranch名へexact non-force `git branch -m`を行う。Issue textやstring similarityによるfuzzy matching、durable metadata rewrite、reset / stash / merge / rebase / cherry-pick / force操作は行わず、ambiguous stateは`BLOCKED: release claimed branch mismatch`としてclaimed / actual / head / checkpoint / claim / stable reasonを返す。正確にrecoverableなケースは追加のHuman preflight、manual rename、second release invocationなしで`IMPLEMENTATION RELEASED`まで完了し、`resume` / `recover`のclaim-checkout mismatchは変更しない。

development sourceはresponsibility-separatedで、次のexplicit deterministic assemblyからstandalone artifactを作る。

```text
responsibility-separated development source
projects/nuinuiCAD/scripts/nuinui-src/**

-> explicit deterministic assembly
projects/nuinuiCAD/scripts/generate-nuinui

-> separate candidate standalone artifact

-> exact black-box verification
-> candidate SHA-256 + Git blob identity fixation

-> checked-in promoted standalone generated artifact
projects/nuinuiCAD/scripts/nuinui
```

source ownership map:

```text
projects/nuinuiCAD/scripts/nuinui-src/project-profile.sh
  nuinuiCAD profile: main/sub/e2e aliases, fixed paths, repository/default-branch identity,
  SAY-<digits> validation, and Manual E2E project policy hooks

shared/local-tools/fixed-2plus1/profile-contract.sh
  shared profile contract and fail-closed contract validation

shared/local-tools/fixed-2plus1/ownership-schema.sh
  canonical project-independent durable ownership schema semantics

shared/local-tools/fixed-2plus1/implementation-core.sh
  fixed 2+1 low-level lifecycle mechanics

shared/local-tools/fixed-2plus1/lifecycle-facade.sh
  shared begin/start/resume façade and envelopes

shared/local-tools/fixed-2plus1/release-facade.sh
  shared release drift proof, duplicate proof, and release envelopes

shared/local-tools/fixed-2plus1/human-test-core.sh
  shared exact-ref Human-test fixation, release, receipt, and duplicate mechanics

shared/local-tools/lane-execution/ownership.sh
  generic v1 durable ownership metadata primitives, validation, and parsers

shared/local-tools/lane-execution/manifest.sh
  project-declared lane topology manifest grammar, validation, and data-only lookup API

shared/local-tools/lane-execution/runtime.sh
  generic Git, checkout, default-branch, lock, slot, receipt, and idle-lane mechanics

shared/local-tools/lane-execution/preflight.sh
  generic manifest-driven lane classification, role dispatch, and registered-worktree inventory

shared/local-tools/lane-execution/inventory.sh
  explicit implementation occupancy parsing, canonical inventory ordering, and complete expectation comparison

shared/local-tools/lane-execution/lifecycle.sh
  generic N-lane begin/start admission and durable implementation mutation

shared/local-tools/lane-execution/human-test.sh
  generic explicit-lane Human-test fixation, exact duplicate/release proofs, and project-hook boundary

shared/local-tools/lane-execution/cli.sh
  staged role-aware lane router, explicit/short E2E lane selection, and #145 assembly boundary

shared/local-tools/lane-execution/render.sh
  topology-neutral human decoration derived from canonical lane role/state evidence

shared/local-tools/lane-execution/implementation-operations.sh
  topology-neutral verify, lane-init, resume, release, recover, and integration adapters

shared/local-tools/lane-execution/release-safety.sh
  generic read-only duplicate-release proof preserving the v1 safety envelope

projects/nuinuiCAD/scripts/nuinui-src/lane-execution-profile.sh
  nuinuiCAD's Work-ID / branch policy and explicit Human-test status hook for the generic preflight contract

projects/nuinuiCAD/scripts/nuinui-src/lane-execution-e2e-policy.sh
  nuinuiCAD's explicit Human-test session guards and local-main source-lane policy for the staged generic runtime

nuinui-body.sh
  narrow nuinuiCAD runtime remainder: forensic inventory, project variables, and adapter hooks

github-pr.sh
  GitHub PR transport boundary

required-checks.sh
  required-check evidence correlation/classification

pr-auto-merge.sh
  reservation state machine

integration-clean.sh
  conflict-free merge-only Human integration refresh

e2e.sh
  nuinuiCAD E2E adapter: presentation, session integration, and e2e-start-local-main interim semantics;
  ordinary exact-ref start/release delegates to the shared Human-test core

context-sync.sh
  context-audit / guarded context-sync / persistent dev-context audit and transition

diagnostics.sh
  doctor / transition-audit / context-check

command-result.sh
  durable Human mutation outcome storage and read-only last-result recovery

self-test.sh
  built-in self-test + external regression aggregation

cli-dispatch.sh
  public command membership / usage / validation / dispatch
```

これらはdevelopment source onlyであり、production helperがruntimeにdynamic `source`することはない。`generate-nuinui`はgeneric ownership / manifest / runtime / lifecycle sources、nuinuiCAD project policy、operation adapters、remaining project commandsをexplicit dependency orderでassembleしてstandalone helperを生成する。`begin`は既存の`preflight` / `start` ownerを薄く組み合わせ、ownership state machineを二重実装しない。

### Manifest-driven preflight foundation

`shared/local-tools/lane-execution/preflight.sh` is the topology-neutral read-only foundation for the later standalone runtime migration. Its `lane_execution_preflight <manifest>` API validates the #141 data-only manifest, audits every declared lane in declaration order, dispatches by the declared role, and compares registered worktrees with the manifest-derived physical path set. The optional `--forensic-worktree <absolute-path>` argument admits exactly one already-authorized extra registered worktree using the existing one-shot semantics.

The implementation-role path reuses the v1 ownership field reader and preserves the existing lock, active-slot, release-tombstone, initialization, idle, `FREE`, `BUSY`, `RELEASE-PENDING`, and `BLOCKED` proof ordering. The generic adapter's `lane_execution_validate_issue_branch` callback is the boundary for project-specific Work-ID / branch validation; topology data does not define that policy.

The Human-test boundary is the explicit callback `lane_execution_human_test_preflight <lane-name> <checkout-path> <manifest-path>`. Project code owns role-specific marker, session, process, and evidence rules inside that callback. The generic layer never discovers a singleton Human-test lane, and zero or multiple Human-test lanes are valid manifest shapes.

`inventory.sh` defines the canonical implementation expectation syntax as comma-separated `lane=FREE` or `lane=<project-valid Work-ID>` pairs in manifest implementation-lane order. It derives actual occupancy only from successful #142 preflight evidence: `FREE` requires no owner, `BUSY` requires a valid owner Work-ID, and release-pending/blocked/ambiguous states are not occupancies. `lifecycle.sh` compares every declared implementation lane before mutation and again at the mutation boundary; its duplicate path proves the requested target generation while comparing every other lane. The source reuses the v1 ownership metadata format and is directly executable as `lane-execution-lifecycle begin|start ...`, but remains outside the generated standalone helper until #145.

`render.sh` consumes the canonical `lane name=... role=... path=...` evidence and decorates by role/state only. These sources are directly executable/testable development sources and are assembled into the generated `nuinui` in deterministic order.

`human-test.sh` is the staged topology-neutral exact-ref Human-test lifecycle. Its start/release API is `lane_execution_human_test_{start,release} <manifest> <human-test-lane> <SAY-123> <tested-ref>`; it validates the selected manifest lane before reading or mutating checkout state, and preserves the existing marker/session/receipt and detached-checkout proofs. Project hooks receive lane, repository, Work-ID, tested ref, mode, and release stage explicitly. `cli.sh` exposes the staged command contract with an explicit manifest context: `e2e-start`, `e2e-start-local-main`, and `e2e-release` accept either `<human-test-lane> <SAY-123> <tested-ref>` or the compatibility short form `<SAY-123> <tested-ref>`. Short forms resolve exactly one declared Human-test lane and block on zero or multiple lanes; they never select by name or position.

The staged nuinuiCAD policy source owns E2E session metadata validation and resolves `e2e-start-local-main`'s source implementation lane by the unique current `idle=branch` policy. It validates that source checkout explicitly, including `codex/interim-sequential`, tested-ref equality, and authoritative-default ancestry. No generic Human-test source knows the meaning of local-main. The generic router validates every implementation lane argument by manifest role and forwards remaining operations through an explicit implementation adapter boundary.

### Source-size architecture budget

`projects/nuinuiCAD/scripts/test-nuinui-source-budget` is the dedicated architecture-budget owner. It deterministically classifies and measures every regular file recursively under:

```text
projects/nuinuiCAD/scripts/nuinui-src/
projects/nuinuiCAD/scripts/nuinui-handoff-check-src/
```

It also guards every regular file directly under `projects/nuinuiCAD/scripts/` as a standalone implementation source. This includes `nuinui-e2e-prepare`; future standalone helpers are included automatically. Top-level discovery is sorted with `LC_ALL=C` and excludes only the generated artifacts `nuinui` and `nuinui-handoff-check`, generators named `generate-*`, and focused regression scripts named `test-*`.

The shared fixed 2+1 implementation sources under `shared/local-tools/fixed-2plus1/` are guarded by the same per-file limit. The focused `test-fixed-2plus1-core` is excluded from that implementation cap, while the source-budget test fails closed if the shared source root cannot be discovered.

The shared lane topology manifest sources under `shared/local-tools/lane-execution/` are guarded by the same per-file limit. Focused `test-*` files are excluded from the implementation cap, while the source-budget test fails closed if either shared source root cannot be discovered.

The hard limit is exactly `32768` bytes per guarded source, measured with `wc -c`; a source is over budget only when its actual byte count is greater than the limit. There is no current exception. Future exceptions require an exact tracked path and non-empty rationale. Threshold and exception changes must remain review-visible tracked changes. `nuinui self-test` aggregates this source-budget regression.

current commands:

| Command | Purpose |
| --- | --- |
| `nuinui preflight [--forensic-worktree <absolute-path>]` | LANES.confで宣言された全laneとdurable ownershipをread-only auditし、必要な場合だけHuman-authorized forensic inventory exceptionをone-shotで認識 |
| `nuinui verify <implementation-lane> <SAY-123> <expected-base-sha> <branch>` | manifestで宣言されたinitialized FREE implementation laneのstart preconditionをread-only検証 |
| `nuinui lane-init <implementation-lane>` | manifestで宣言されたexact idle implementation laneへpermanent v1 ownership schema markerをbootstrap |
| `nuinui begin <implementation-lane> <SAY-123> <expected-base-sha> <branch> <complete-implementation-inventory> [--forensic-worktree <absolute-path>]` | 全declared implementation laneのcomplete inventory、target FREE、mutation-boundary再比較とnew generation startを1 Human handoffで実行。直後の同一requestだけはexact duplicateとしてread-only認識。末尾optionはone-shot inventory exception |
| `nuinui start <implementation-lane> <SAY-123> <expected-base-sha> <branch> [--forensic-worktree <absolute-path>]` | mutation lock + durable slotをbranch switch前に取得してnew claim generationを開始。末尾optionはone-shot inventory exception |
| `nuinui resume <implementation-lane> <SAY-123> <expected-base-sha> <expected-checkpoint-sha> <branch> <expected-claim>` | exact Base / checkpoint / branch / claimでsame generationへ復帰 |
| `nuinui release <implementation-lane> <merged-checkpoint-sha> <expected-claim>` | exact claimを照合しclaim-specific tombstone経由でmerged laneをrelease |
| `nuinui recover <implementation-lane> <expected-claim>` | known interrupted init/start/resume/release stateだけをexact claimでexplicit recovery |
| `nuinui pr-auto-merge <pr-number> <expected-head-sha> <expected-main-sha>` | reviewed exact headへrequired CI pending時だけGitHub Auto-mergeを予約 |
| `nuinui integrate-clean <implementation-lane> <SAY-123> <expected-claim> <expected-topic-head> <expected-main> <verification-script> <expected-files-manifest\|->` | ChatGPT-authorized NON-INTERFERING merge-gate refreshをselected manifest laneでconflict-free merge-only実行し、verify後にnormal push |
| `nuinui e2e-start [<human-test-lane>] <SAY-123> <tested-ref>` | unique Human-test laneのshort form、またはexplicit manifest laneをexact tested refへ固定しmarker作成 |
| `nuinui e2e-start-local-main [<human-test-lane>] <SAY-123> <tested-ref>` | Active interim workflow時だけselected Human-test laneをproject policyのimplementation sourceへ安全に固定 |
| `nuinui e2e-release [<human-test-lane>] <SAY-123> <tested-ref>` | unique Human-test laneのshort form、またはexplicit manifest laneでcaller identityを照合し、verified stateをlatest authoritative default branchへ戻してmarkerを削除。exact duplicateはread-only no-op |
| `nuinui last-result` | latest tracked Human mutationのstrict durable resultと、command-result heading / footerを除くcanonical outputをread-onlyで検証・復旧 |
| `nuinui context-audit <expected-main> <expected-artifact-blob>` | GitHub authoritative mainを照合するstandard cloneのstrict read-only audit。behind local HEAD / artifactは許容 |
| `nuinui context-sync <expected-main> <expected-artifact-blob>` | fresh fetch後にexpected-main treeのartifact blobを検証し、cleanなstandard clone `main`だけをff-only sync |
| `nuinui context-dev-audit <expected-branch> <expected-head>` | canonical `/Users/yosomi/Code/dev-context-dev`のregistered worktree / repository / clean / branch / HEADをstrict read-only audit |
| `nuinui context-dev-transition <expected-old-branch> <expected-old-head> <expected-main> <new-branch>` | concluded prior topicからexact expected mainへordinary detach/switchし、同じregistered worktreeでfresh branchをcreate/switch。exact immediate duplicateはread-only no-opとして認識 |
| `nuinui doctor` | helper / lane / local dev-context diagnostic |
| `nuinui doctor --full` | preflight、E2E status、local dev-context stateのread-only snapshot |
| `nuinui transition-audit` | Active interim transition条件をread-only監査 |
| `nuinui context-check` | dev-context Markdown local linksと`nuinui` CLI-doc整合をread-only検査 |
| `nuinui self-test` | isolated temporary Git repositoriesでsupported safety pathsをexercise |

旧claimless `resume <lane> <Issue> <checkpoint> <branch>`、旧`release <lane> <checkpoint>`、active checkoutをownershipへadoptするpublic commandはcurrent CLIではない。argument count mismatchはfail-closedでusage errorにする。

### Recoverable Human mutation results

Tracked Human mutation commands are exactly `lane-init`, `begin`, `start`, `resume`, `release`, `recover`, `pr-auto-merge`, `integrate-clean`, `e2e-start`, `e2e-start-local-main`, `e2e-release`, `context-sync`、and `context-dev-transition`。Read-only commands, including `preflight`, `verify`, `context-audit`, `context-dev-audit`, `doctor`, `transition-audit`, `context-check`, `self-test`, and `last-result`, never replace the latest mutation result. Version and help behavior is outside this result contract.

The latest result store is kept at `$(git -C /Users/yosomi/Code/dev-context rev-parse --absolute-git-dir)/nuinui-command-result-v1/` in the standard dev-context Git directory and contains only `state` and `output`。 It is recovery evidence only; lane ownership, claims, locks, release receipts, E2E markers/sessions, and other authorities remain authoritative. The production helper uses the canonical standard clone represented by `C`; isolated `NUINUI_SELFTEST` runs use an isolated dev-context repository and never the production store.

Each tracked request binds the command, every original argument in order, and any forensic option/path with a NUL-separated SHA-256 request identity. The state is strict schema version 1. A fresh operation atomically replaces the previous result with `phase=STARTED`, `result=INCOMPLETE`, and `mutation=unknown` before the mutation runs. A terminal result atomically stores the exact combined canonical stdout/stderr in `output` first, then the matching `phase=TERMINAL` state with `result=SUCCESS|BLOCKED|ERROR`, `mutation=yes|no|unknown`, the actual exit status, and the output SHA-256. The timestamp is informational identity evidence, not an expiry rule.

After successful terminal finalization, tracked mutations display a common `🧾 NUINUI COMMAND RESULT` heading and decorated result state while preserving their existing canonical output. `nuinui last-result` verifies the stored output hash before printing `🧾 NUINUI LAST RESULT`, decorated recovery / result state, and the original output; `output_begin` and `output_end` remain unchanged. Human decoration is display-only: canonical internal stdout/stderr, the durable `output` file, and the version=1 state schema remain undecorated. A valid `STARTED` record returns `🟠 result=INCOMPLETE` / `⛔ recovery=BLOCKED` and never exposes an older output. Missing, malformed, unsafe, partial, or hash-mismatched state fails closed without `🟢 recovery=READY`; a recovered terminal BLOCKED or ERROR is still a successful read-only `last-result` operation.

`context-dev-transition` keeps the normal #78 transition semantics unchanged: exact old branch / head, clean canonical registered worktree, authoritative remote `main` equal to expected main, old-head ancestry, absent local / remote new branch, guarded fetch / revalidation, ordinary detach to expected main, ordinary new-branch create / switch, exact post-transition read-back, and retained old branch. After argument validation, standard repository / origin identity validation, and exact canonical worktree-registration validation, a non-old current branch is eligible for already-transitioned recognition only when every fresh read-only proof matches: current branch is exactly caller `new-branch`; current HEAD is exactly caller `expected-main`; the worktree is clean; registration is exact, unique, valid, and tied to the same repository; authoritative remote `main` is exactly caller `expected-main`; local `expected-old-branch` exists and points exactly to caller `expected-old-head`; `expected-old-head` is contained in `expected-main`; and remote `new-branch` is absent. The remote-new-branch absence intentionally limits recognition to the immediate post-transition state before implementation / push progression.

The exact duplicate success envelope is deterministic:

```text
DEV-CONTEXT ALREADY TRANSITIONED
worktree=/Users/yosomi/Code/dev-context-dev
branch=<new-branch>
base=<expected-main>
head=<expected-main>
mutation=no-op
clean=yes
```

The duplicate implementation path performs no Git, worktree, ref, or fetch mutation; the tracked command-result store may still durably record the terminal no-op. This is terminal evidence for continuing the current Task workflow without extra Human handback. Progressed, mismatched, near-match, missing, malformed, or ambiguous state remains `BLOCKED` / `ERROR` and follows the normal fresh-state route; no branch naming inference or repair is allowed.

### Durable ownership behavior

ownership schemaは[`CHECKOUTS.md`](./CHECKOUTS.md)の`version=1`をそのままconsumeする。helper versionとmetadata versionは独立している。

`preflight`はread-only diagnostic / routing command。各implementation laneのFREE判定はmanifestのdefault branchに対するauthoritative `ls-remote`を使い、cleanでもbehindならFREEにしない。mutation lock、active slot、releasing tombstoneを優先して分類し、strict schema violationはBLOCKする。validなactive slotのbranch / Base ancestry / claim identityが一致していれば、working treeがdirtyでも`clean=no`と`state=BUSY`を返す。branch / Base / metadata identity mismatchは引き続きBLOCKする。通常startでは、`begin`が全implementation laneのcomplete inventoryを同じauditで確認するため、別preflightを先に実行しない。

`lane-init`はmanifestで宣言されたimplementation laneを正当に新規 / 再作成した場合のschema bootstrap。slot / lock / release stateがなくexact safe idleを証明できる場合だけmarkerを書く。既存active-looking checkoutからclaimを生成するrepair用途には使わない。

`begin`の形式は`nuinui begin <implementation-lane> <SAY-123> <expected-base-sha> <branch> <complete-implementation-inventory>`。inventoryはmanifest順の全implementation laneを一度ずつ`lane=FREE`または`lane=SAY-123`で指定する。targetは必ずphysically FREEで、全laneの期待値とfull preflightが一致しなければ開始しない。mutation-boundaryでも全inventoryを再比較してから`start`へ委譲する。post-mutation consistencyを証明できない場合は新しいdurable ownershipを推測・削除せずBLOCKEDで返し、target generationを検証できれば`mutation_state=COMPLETED`とtargetのissue / branch / base / checkpoint / claim / clean / `state=BUSY`を返す。検証不能なら`mutation_state=UNKNOWN`と既知のrequested/new identityを返す。

同じ`begin` commandを直後に誤って再実行した場合、最初のfull preflightがPASSでtargetがBUSYなら、targetのdurable Issue / branch / Base、validな既存claim、slot / checkout identity、cleanなcheckout、checkout `HEAD == Base`、no lock / tombstone、callerのcomplete inventory、およびfull preflight PASSをすべてread-onlyで再証明できたときだけduplicateとして扱う。進行後のgenerationでcheckout `HEAD != Base`ならduplicate successにしない。再証明中にstateが変化した場合、または証明できない場合は既存のBLOCKEDへfail-closedする。

duplicate successは`IMPLEMENTATION ALREADY STARTED`とlane / issue / branch / base / `checkpoint=<Base>` / existing `claim` / `clean=yes` / `state=BUSY` / complete inventory fields / `mutation=no-op` / `preflight=PASS`を返す。既存のdurable claimをそのまま再利用し、slot、claim、lock、tombstone、branch、checkout、inventory stateを変更しない。これは新しい`start`ではなく、`resume`や`recover`を内部で代用するものでもない。

`start`はbranch switchより先にnew claim + lock + slotをdurable化する低レベル lifecycle primitiveとして保持する。成功outputのclaimはGitHub Issue workflowへcheckpointする。通常のHuman handoffは`begin`を使う。

`resume`はcaller-supplied Lane / Issue / Base / exact checkpoint / branch / claimとslotをexact照合する。通常のpushed checkpointではremote topicも同じcheckpointであることを要求する。`begin`直後の初回push前に限り、remote topicの成功したabsence、local topic = Base = expected checkpoint、cleanな既存topic、safeなidle identityをすべて証明できた場合だけ、そのlocal topicへ復帰できる。Base refresh、merge-main、rebase、reset、stash、force-switch、branch generation、claim inferenceを行わない。

`release`はcaller-supplied merged checkpoint + claimを必須とする。facadeはmutation前にactive slot、current topic branch checkpoint、durable claim、lock / tombstone / schemaをread-only検証し、checkpoint不一致は`BLOCKED: checkpoint mismatch`と`expected` / `actual`、claim不一致は`BLOCKED: claim mismatch`とdurable `expected` / caller `actual`を返す。claimed local refのmissingはcheckpoint mismatchではなくbranch identity failureとして診断する。rejected releaseはdurable ownershipを保持し、raw mutationが予期せず無診断で失敗してもcontext付きERRORを返す。remote topic branchがpost-mergeで削除済みでも、saved checkpointがcurrent authoritative mainに含まれることを証明できればrelease可能。release開始時にclaimed local topic branchをcheckoutしていた場合だけ、そのexact branchをsafe cleanup candidateにする。active generationがなく、receiptのlane / checkpoint / claim / Base / Issue / branch identity、idle checkout、authoritative main containmentをすべて完全一致で証明できない限り、過去receiptからreleaseを推測・採用しない。

`recover`は一般repairではない。lock/tombstone age expiry、自動削除、reset、stash、force-switch、broad branch cleanupを行わない。metadata malformed、multiple tombstones、claim mismatch、dirty、不一致stateはfail-closed。

`nuinui self-test`はmanifest-driven isolated runtime regressionでcomplete inventory admission、renamed lanes、wrong-role rejection、Human-test short/explicit selection、manifest resolution/security、uncertain mutation recovery、release receipt、topology-only helper byte identityを検証し、`scripts/test-nuinui-command-result`、`scripts/test-nuinui-integration-clean`、`scripts/test-nuinui-pr-auto-merge`、`scripts/test-nuinui-context-sync`、およびsource-budget regressionを集約する。

成功outputはcallerが別preflightなしにmanagement synchronizationへ進めるためのstate envelopeである。`begin`は`IMPLEMENTATION STARTED`とlane / issue / branch / base / checkpoint / claim / `clean=yes` / `state=BUSY` / exact peer fields / `preflight=PASS`を返す。`resume`は`IMPLEMENTATION RESUMED`とlane / issue / branch / base / checkpoint / claim / `clean=yes` / `state=BUSY`を返す。通常の`release`は`IMPLEMENTATION RELEASED`とIssue / saved checkpoint / released claim / released branch / idle branch / idle HEAD / authoritative origin main / `clean=yes` / `state=FREE`を返し、exact duplicateは`IMPLEMENTATION ALREADY RELEASED`とlane / Issue / Base / saved checkpoint / released claim / released branch / authoritative origin main / `clean=yes` / `mutation=no-op` / `state=FREE`を返す。

`start`をexplicit low-level primitiveとして直接使った場合も、full local audit後にlocal transition envelopeを返す。ただしpeerはその時点の観測値であり、ChatGPTが決めたcaller expectationとの一致を証明しない。canonical normal startupでは`begin`のexpected peer照合と`preflight=PASS`をadmission evidenceに使う。

### `integrate-clean` merge-only integration

`nuinui integrate-clean <implementation-lane> <SAY-123> <expected-claim> <expected-topic-head> <expected-main> <verification-script> <expected-files-manifest|->` は、already-reviewed topicに対するcurrent-base freshnessだけが必要な場合のnarrow Human integration helper。

eligibilityとpost-integration driftのsemantic `NON-INTERFERING`判断はChatGPTが行い、helper自身は判断しない。active durable lane / Issue / claim / branch / Base / exact local and remote topic / exact current main / clean stateを再検証してから、exact current mainの`--no-commit --no-ff` mergeだけを行う。

`verification-script`はChatGPTがcurrent Task contractから確定したabsolute executable pathを渡す。helperはtest selectionやCI classificationを再決定しない。optional manifestを使う場合はabsolute readable regular fileとし、`expected-main -> prospective merge tree`のNUL-delimited exact file setと比較する。

commit前のconflict、file-set mismatch、verification failure、tracked merge-state mutation、remote raceはmergeをabortし、必要なtracked worktree restorationをindexから行った上でoriginal topic checkpoint / durable claim / clean state / original remote topicを再証明する。`reset`、`stash`、force-switch、force-pushは行わない。exact restorationを証明できなければ`ERROR:`で停止する。

verification成功後にremote main / topicを再読込し、変化がない場合だけmerge commitを作る。commitはprior topicとexact expected mainの2 parentおよびverified prospective treeであることを検証する。normal non-force push成功後だけ`INTEGRATION PUSHED` envelopeを返し、その`integration_watermark`をexpected mainとして扱う。

push failureはverified local merge commitを保持し、rollback / rewrite / retryを行わずfresh ChatGPT diagnosisへ戻す。conflict resolution、integration fix、source edit、ambiguous failure diagnosis、test-debug loopはこのhelperのscope外でLunaへ戻す。

successful push/read-back後、`integrate-clean`はGit dirの`nuinui-integrate-clean-receipt-v1`へ、request identity、active durable claim、branch / Base、prior topic、integration watermark、resulting merge head、verifier / manifest identity、verification / file-set successをstrict versioned receiptとしてatomically保存する。receiptはownership authorityではなく、後続のsuccessful integrationで置き換えられる。

同じrequestを直後に再実行した場合、receiptとcallerのlane / Issue / claim / prior topic / expected main / verifier / manifest、active slot、branch / Base、clean checkout、local / remote resulting head、exact two-parent merge、lock / releasing state、current authoritative mainをすべてread-onlyで再証明できたときだけ、次のterminal evidenceを返す。

```text
INTEGRATION ALREADY PUSHED
lane=...
issue=...
branch=...
prior_topic=...
head=...
integration_watermark=...
claim=...
topic_remote=...
verification=PASS
file_set=VERIFIED|NOT_REQUESTED
mutation=no-op
clean=yes
```

このexact duplicate pathはmerge、verifier、commit、push、reset、checkout mutation、receipt rewriteを行わない。上記success envelopeはcompleted integrationのterminal evidenceであり、ChatGPTは追加のHuman preflight、lane / remote state paste、初回成功確認、verifier再実行、generic diagnosis、同じcommandの再々実行を要求せず、blocking review / PR workflowへ直接継続する。claim、prior topic、expected main、verifier、manifest、local / remote head、parent shape、receipt schema、lock / releasing stateのnear-match、superseded receipt、またはその他のambiguous stateは従来どおり`BLOCKED`でfail-closedする。

### Standalone non-lane mechanics

`pr-auto-merge`, E2E, context-audit / context-sync / context-dev-audit / context-dev-transition, doctor, transition-audit, context-checkも同じ`nuinui` scriptが直接実装する。別backend fileの存在をruntime preconditionにしない。

`nuinui pr-auto-merge`は`sayosomi/nuinuiCAD`だけを対象とするreservation-only command。`expected-main`はcallerがfreshに確認したauthoritative remote `main` SHAであり、helperはGitHubから`main` tipを独立取得して一致を確認する。PRの`baseRefOid`はauthoritative current-main freshnessのevidenceとして扱わない。PRがOPEN / non-draft / base=`main` / exact reviewed headで、reviewed headがそのauthoritative current `main`をintegration済みであり、mergeabilityがunambiguous、required checksがfailure/cancel/skip/unknownなしで少なくとも1件pendingの場合だけ予約へ進む。current main mismatchは`BLOCKED: expected main mismatch`、behind PRは`BLOCKED: PR is behind current main; integration required`としてfail-closedする。check discoveryは`pass` / `pending` / `fail` / `none-required` / `required-checks-unresolved` / `api-error`の明示stateを使い、visible required checksがすべて成功しpendingがない場合は、exact first line `BLOCKED: all required checks are already complete`でfail-closedし、Auto-merge予約もdirect mergeも行わない。

initial current PR snapshotに既存のAuto-merge reservationがある場合、`pr-auto-merge`はPR number / OPEN state / non-draft / base=`main` / exact expected head / acceptableでunambiguousなmergeability / authoritative current main / #60 integration / `autoMergeRequest.mergeMethod=MERGE`をfreshに独立証明できたときだけ、read-only terminal successとして認識する。これは既存reservationをcancel / replace / recreateせず、GraphQL mutationを行わない。required checksはreservation後にpassへ進んでもよく、exact already-reserved recognitionではpendingのままであることを要求しない。

exact already-reserved successのcanonical envelopeは次のとおりである。

```text
AUTO-MERGE ALREADY RESERVED
pr=<number>
head=<expected-head>
main=<expected-main>
merge_method=MERGE
mutation=no-op
```

このsuccess envelopeはChatGPTがそのままnormal CI / PR workflowへ進むための十分なterminal evidenceである。exact proofが成功した場合、追加のPR-state paste、head/main recheck、同じ`pr-auto-merge`の再実行、最初のreservation確認、またはgeneric duplicate-only diagnosisをHumanへ求めない。near-match、non-MERGE、closed / merged、draft、non-main base、ambiguous mergeability / integration、current-main drift、lookup failureはfail-closedする。

visible required checksは`gh pr checks --required`のmachine-readable stdoutだけをparseし、stderrの`no required checks reported`等のhuman proseをcheck rowとして扱わない。required check viewが空の場合はbranch protectionのrequired status metadata、ruleset metadata、exact-head pull_request workflow run、check suite、check runを相関する。exact-head Actions runがqueued / in_progressならpending、関連executionがすべてsuccessならpass、evidenceがない場合はnone-required、相関が不完全 / 矛盾 / truncatedならrequired-checks-unresolved、GitHub/API/tool failureならapi-errorとしてfail-closedする。commit-statusのdefault pendingだけではpendingと判定しない。

operationalなnonzero exitはHuman-visibleに分類する。証明できたfail-closed state / precondition mismatchは`BLOCKED:`、GitHub / API / auth / tool execution failureやreservation stateを判定できない場合は`ERROR:`で返す。mutation直前にpreconditionを再確認し、GraphQL `enablePullRequestAutoMerge`へ`mergeMethod=MERGE`と`expectedHeadOid`を渡す。initial check通過後のpre-mutation state transitionは`BLOCKED: Auto-merge reservation precondition changed before mutation`と具体的な現在理由を返してfail-closedし、mutationしない。GraphQL mutation raceはmutationをretryせず、fresh read-only diagnosisを最大1回だけ行い、direct mergeへfallbackしない。mutation後はsame PR / head / expected main / OPEN / `autoMergeRequest.mergeMethod=MERGE`をread-backして成功扱いする。

成功時のstable output contractは次の5行である。これは既存のpost-mutation read-backがexact reservation identityを証明した後だけemitする。

```text
AUTO-MERGE RESERVED
pr=<number>
head=<exact reviewed head>
main=<expected/current authoritative main>
merge_method=MERGE
```

`nuinui doctor --full`、`transition-audit`、`context-check`、`context-audit`、`context-dev-audit`はread-only。`context-sync`はexpected-main tree artifactを検証したff-only mutation、`context-dev-transition`はexact old-stateを再検証したordinary detach/switch + create/switchだけを行う。これらはcleanup、process stop、Issue selection、GitHub update、merge判断を行わず、one-time worktree migrationやgeneric worktree cleanupもcommand surfaceに含めない。

## Human Manual E2E preparation helper

current Human E2E preparation helper version: `1.3.0`。

`projects/nuinuiCAD/scripts/nuinui-e2e-prepare`はdedicated e2e laneでHuman Manual E2E hostを準備するversioned helper。

```text
nuinui-e2e-prepare check <SAY-123> <tested-ref> <fixture-path>
nuinui-e2e-prepare prepare <SAY-123> <tested-ref> <fixture-path> [cdp-port]
nuinui-e2e-prepare status
nuinui-e2e-prepare cleanup <SAY-123> <tested-ref> <e2e-root>
nuinui-e2e-prepare closure-check <SAY-123>
```

`prepare`はexact tested ref / marker / clean detached checkoutを検証し、dependency materializationとrequired build後にfresh VS Code Extension Development Hostを起動してHuman handoffを作る。tracked-file mutationはBLOCKする。

healthyなexact duplicate `prepare`は、active session、handoff、prepared fixture、owned process、CDPをread-onlyで完全一致検証した場合だけ次の成功 envelopeを返す。

```text
E2E SETUP ALREADY READY
mutation=no-op
READY FOR HUMAN E2E
```

exact duplicate `cleanup`は、active session authorityがない場合に限り、matchingなcleanup receipt、root不在、handoff不在、owned process不在をread-onlyで完全一致検証した場合だけ次を返す。

```text
E2E CLEANUP ALREADY COMPLETE
mutation=no-op
```

active session authorityはcleanup receiptより常に優先される。near-match、stale、ambiguousなsession / handoff / receipt stateは`BLOCKED`であり、cleanup receiptからactive sessionを推測しない。この二つのexact duplicate success envelopeが返った場合、ChatGPTは通常workflowを直接継続し、Humanにstatus実行、session / marker / process stateの貼り付け、最初のinvocation成功確認、またはduplicateだけを理由にしたprepare / cleanup再実行を求めない。

Human E2Eのcanonical successful closureは、次の順序に固定する。

```text
nuinui-e2e-prepare cleanup <SAY-123> <tested-ref> <e2e-root>
nuinui e2e-release <SAY-123> <tested-ref>
nuinui-e2e-prepare closure-check <SAY-123>
```

session metadataはcurrent generationではstrictな`issue / ref / source_fixture / root / handoff / cdp_port / launch_pid`を保持する。legacyな6-field metadataはrollout/cleanup互換のためだけに認識し、duplicate prepareの成功には使わない。`cleanup <Issue> <tested-ref> <e2e-root>`はcallerのrootまでidentity照合し、owned process / temporary root / handoff / session metadataだけを削除する。完了時はGit dirの`nuinui-e2e-cleanup-receipt`（`version=1 / issue / ref / root`）を先にatomically保存する。tested same-Issue markerは意図的に保持され、cleanup後のmarker存在・session metadata不在がnormalなrelease-ready stateである。`nuinui e2e-release <SAY-123> <tested-ref>`はcaller identity、strict marker、clean detached checkout、session不在をmutation前後に照合し、Git dirの`nuinui-e2e-release-receipt`をatomically durable化してからmarkerを削除する。session metadataが残る間はe2e laneをreleaseしない。

`status`と`closure-check`はread-only。unmanaged artifactや別Issue stateを勝手にcleanupしない。`closure-check`はe2e-release後だけに行うfinal read-only closure proofであり、cleanupとe2e-releaseの間の通常のrelease-precondition checkではない。同一Issue markerが残っている間は`closure-check`が`BLOCKED`になるfail-closed semanticsを維持する。markerがない場合も、matchingなstrict E2E release receipt、idle clean detached checkout、current authoritative `origin/main`を証明できるexact duplicate releaseだけを`E2E ALREADY RELEASED` / `mutation=no-op`として受理する。active markerはreceiptより常に優先される。

`projects/nuinuiCAD/scripts/test-nuinui-e2e-prepare`はtemporary Git checkoutとfake hostでisolated self-testを行う。実機VS Code / dependency / CDP lifecycleはactual e2e preparation時に別途確認する。

active E2E markerはcurrent generationのauthorityである。markerがある間のexact duplicate `e2e-start`はcaller Issue/ref、strict marker、clean detached checkout、HEAD、optional sessionをread-onlyで照合し、`E2E ALREADY STARTED` / `mutation=no-op`を返す。markerがない場合のexact duplicate `e2e-release`も、matching receiptとcurrent authoritative `origin/main` idle proofをread-onlyで満たすときだけ成功する。同じcommandの再実行に対して追加のHuman handback、preflight、status、confirmationは要求しない。

Humanへhelper commandを渡す場合、Issue、Base、checkpoint、claim、branch、tested ref、fixture path等、ChatGPT側で確定できる値を埋めたcopy/paste-ready commandにする。

## Helper promotion rule

helper sourceをauthoritative GitHubへpromotionする前に:

1. current authoritative source identityを取得する。
2. candidateをauthoritative fileとは別に作る。
3. supported safety-critical pathsをisolated environmentで実行する。
4. failure path / fail-closed behaviorもexerciseする。
5. exact tested candidate identityを固定する。
6. tested candidateへpromotion後の未試験変更を足さない。
7. dev-context write planへのHuman approvalを得る。
8. promotion直前にtarget blob / repo head driftを再確認する。
9. exact candidateをpromotionしread-backする。
10. local clone sync commandをHumanへ提示する。

live implementation laneでhelper candidateのmutation commandを試験しない。production promotion前のlive checkはread-only preflight / external evidence照合に限定する。

unexpected error、hang、wrong output、unsafe-looking behaviorが出た場合はone-off workaroundで終わらせずhelper defectとしてrepair loopへ戻す。safety checkを弱めてfailureを通さない。

## Standalone durable helper promotion evidence

current `nuinui` 1.6.4 exact Git blob:

```text
8dda577d6c5261ea10700c6bbe160498e1062db5
```

candidate SHA-256:

```text
3a9cd6e21df707a5f13661f704fba25bfd7a357722c9f6b9bc6a14c6b0033c2c
```

promotion candidateはseparate legacy/backend fileなしでisolated temporary Git repositories上の`nuinui self-test`を完走し、次を確認した。

- initialization gate / exact idle;
- canonical begin with FREE peer and exact BUSY peer admission;
- wrong peer, target BUSY, and invalid fixed-lane fail-closed admission;
- complete start / resume / release envelopes;
- old resume/release signature rejection;
- strict v1 unknown/missing/duplicate/unsupported schema failure;
- tombstone claim/suffix fail-closed;
- durable start claimとcheckout mismatch detection;
- Base + claim付きresume;
- failed unmerged releaseのslot保持 / own-lock rollback;
- newer authoritative mainへのmerged release;
- interrupted start / release recovery;
- existing v1 BUSY slotの無変換classification（dirty working treeを含むvalid active claimの`clean=no` / `state=BUSY`、wrong branchのBLOCK）;
- E2E marker lifecycle;
- standalone Auto-merge reservation path;
- Auto-merge already-complete, TOCTOU pending-to-complete, mutation-race, required-check failure/API, reviewed-head/main mismatch, successful reservation, and post-mutation read-back failure diagnostics;
- stale clean mainのFREE拒否。

result:

```text
SELFTEST PASS
NUINUI LIFECYCLE SELFTEST PASS
NUINUI HANDOFF CHECK SELFTEST PASS
CONTEXT CHECK PASS
```

exact final candidate verification:

```text
/bin/sh -n projects/nuinuiCAD/scripts/nuinui                    PASS
/bin/sh -n projects/nuinuiCAD/scripts/test-nuinui-lifecycle      PASS
projects/nuinuiCAD/scripts/nuinui self-test                     PASS
projects/nuinuiCAD/scripts/test-nuinui-handoff-check             PASS
projects/nuinuiCAD/scripts/nuinui context-check                  PASS
/bin/sh -n projects/nuinuiCAD/scripts/test-nuinui-pr-auto-merge PASS
projects/nuinuiCAD/scripts/test-nuinui-pr-auto-merge           PASS
git hash-object projects/nuinuiCAD/scripts/nuinui                  b192bfd6ad26ca538baf113d0525449e15c650ff
shasum -a 256 projects/nuinuiCAD/scripts/nuinui                  4f7298b66cf0e393e4b06ff891500f7379dbf52be415ea3342abaaca9811ed4b
```

1.5.1 repairではpromotion後のmacOS標準awk failureを再現根拠として、strict metadata parserの出力をternary expressionなしのPOSIX awkへ変更した。exact candidateで`/bin/sh -n`と`nuinui self-test`を再実行し、parser単体は`awk` / `nawk` / BusyBox awkでvalid slotの同一field outputとduplicate-key rejectionを確認した。GitHub compareで1.5.0からのcode diffはversion bumpとこのparser rewriteだけである。

runtime compatibility backendはcurrent designに存在しない。過去の1.4.0 wrapper / 1.3.5 backendはGit historyからrollback可能だが、current treeで別authorityやfallbackとして保持しない。

## Fallback

versioned helperが未install、stale / broken、またはcurrent operationをsupportしていない場合は利用を強行しない。

diagnostic preflight等でHuman actionが必要なら[`CHECKOUTS.md`](./CHECKOUTS.md)とshared `human-terminal-instructions` skillに従ったcomplete inline commandをfallbackとして提示する。

fallbackで得られた反復可能operationをhelperへ追加する場合も、上記promotion ruleでcandidate verificationとapprovalを行う。
