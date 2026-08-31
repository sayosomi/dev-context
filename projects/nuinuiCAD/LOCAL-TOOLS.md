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

current standalone helper version: `1.6.16`。

verify、direct public start、およびbeginは、既存のlifecycle ownerを呼ぶ前に新規requestのIssue / branch pairをstrictに検証する。branch全体からcase-insensitiveなSAY-Nを抽出して重複を除き、distinctなidentifierが1つだけでcaller Issueと一致する場合だけ通過する。複数のdistinct identifier、別Issueのみ、identifierなし、または不正なGit ref syntaxはactionableなERROR:で拒否する。このrequest境界は既存のdurable ownership parserとは分離され、保存済みslot / lock / release receiptの互換性を変更しない。

`preflight`、`begin`、`start`だけは、末尾のone-shot `--forensic-worktree <absolute-path>` pairを受け付ける。これはHuman-authorizedな、同じnuinuiCAD repositoryにregisteredされた正確に1つのextra worktreeをcurrent invocationのinventory exceptionとして認識するだけで、allowlistやmarkerなどのdurable stateを作らず、worktreeをexecution laneにはしない。pathはcanonical absolute directoryで、fixed laneではなく、registered worktree inventoryがfixed main / sub / e2e + supplied pathと完全一致しなければならない。default no-option behaviorは引き続きexact three-worktree strictnessであり、継承環境変数やdirectory nameだけでexceptionを有効化しない。成功したactive invocationは`forensic_exception=active`とsupplied pathを表示し、invalid requestはmutation前にactionableな`forensic_exception=BLOCKED`としてfail closedする。

`nuinui preflight`のHuman copy boundaryは、`===== NUINUI PREFLIGHT RESULT =====`からコピーを開始し、`PREFLIGHT PASS`または`PREFLIGHT BLOCKED`の直後で停止する。ヘッダはplain-textの出力境界だけを示し、lane / preflight semanticsは変更しない。

`nuinui release <main|sub> <merged-checkpoint> <claim>`は、post-mergeにlane checkoutだけがdriftした場合も、`CHECKOUTS.md`の狭いproof setをrelease中に満たすときだけ既存local claimed topicへ通常の`git switch`で復旧する。branch生成やforce系操作はせず、再検証に失敗した場合はactive ownershipを保持して`BLOCKED:`で停止する。成功したreleaseはlane Git dirへcompleted-release receiptをdurable化してからlock / tombstoneをcleanupし、receipt・idle state・authoritative main・clean checkoutをread-onlyで完全一致検証できる同一requestの再実行だけ`IMPLEMENTATION ALREADY RELEASED`の`mutation=no-op`として受理する。このrelease-only recoveryは`resume` / `recover`のclaim-checkout mismatchを変更しない。

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
ownership-schema.sh
  canonical durable ownership schema semantics

nuinui-body.sh
  shared runtime / low-level lifecycle primitives

github-pr.sh
  GitHub PR transport boundary

required-checks.sh
  required-check evidence correlation/classification

pr-auto-merge.sh
  reservation state machine

lifecycle-facade.sh
  public lifecycle façade/envelopes

integration-clean.sh
  conflict-free merge-only Human integration refresh

e2e.sh
  e2e-start / e2e-start-local-main / identity-safe e2e-release mechanics

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

これらはdevelopment source onlyであり、production helperがruntimeにdynamic `source`することはない。`begin`は既存の`preflight` / `start` ownerを薄く組み合わせ、ownership state machineを二重実装しない。

### Source-size architecture budget

`projects/nuinuiCAD/scripts/test-nuinui-source-budget` is the dedicated architecture-budget owner. It deterministically classifies and measures every regular file recursively under:

```text
projects/nuinuiCAD/scripts/nuinui-src/
projects/nuinuiCAD/scripts/nuinui-handoff-check-src/
```

It also guards every regular file directly under `projects/nuinuiCAD/scripts/` as a standalone implementation source. This includes `nuinui-e2e-prepare`; future standalone helpers are included automatically. Top-level discovery is sorted with `LC_ALL=C` and excludes only the generated artifacts `nuinui` and `nuinui-handoff-check`, generators named `generate-*`, and focused regression scripts named `test-*`.

The hard limit is exactly `32768` bytes per guarded source, measured with `wc -c`; a source is over budget only when its actual byte count is greater than the limit. There is no current exception. Future exceptions require an exact tracked path and non-empty rationale. Threshold and exception changes must remain review-visible tracked changes. `nuinui self-test` aggregates this source-budget regression.

current commands:

| Command | Purpose |
| --- | --- |
| `nuinui preflight [--forensic-worktree <absolute-path>]` | fixed main / sub / e2e 3-lane stateとdurable ownershipをread-only auditし、必要な場合だけHuman-authorized forensic inventory exceptionをone-shotで認識 |
| `nuinui verify <main\|sub> <SAY-123> <expected-base-sha> <branch>` | initialized FREE laneのstart preconditionをread-only検証 |
| `nuinui lane-init <main\|sub>` | proven exact idle fixed laneへpermanent v1 ownership schema markerをbootstrap |
| `nuinui begin <main\|sub> <SAY-123> <expected-base-sha> <branch> <FREE\|SAY-123> [--forensic-worktree <absolute-path>]` | full 3-lane audit、target FREE、exact peer occupancy確認とnew generation startを1 Human handoffで実行。直後の同一requestだけはexact duplicateとしてread-only認識。末尾optionはone-shot inventory exception |
| `nuinui start <main\|sub> <SAY-123> <expected-base-sha> <branch> [--forensic-worktree <absolute-path>]` | mutation lock + durable slotをbranch switch前に取得してnew claim generationを開始。末尾optionはone-shot inventory exception |
| `nuinui resume <main\|sub> <SAY-123> <expected-base-sha> <expected-checkpoint-sha> <branch> <expected-claim>` | exact Base / checkpoint / branch / claimでsame generationへ復帰 |
| `nuinui release <main\|sub> <merged-checkpoint-sha> <expected-claim>` | exact claimを照合しclaim-specific tombstone経由でmerged laneをrelease |
| `nuinui recover <main\|sub> <expected-claim>` | known interrupted init/start/resume/release stateだけをexact claimでexplicit recovery |
| `nuinui pr-auto-merge <pr-number> <expected-head-sha> <expected-main-sha>` | reviewed exact headへrequired CI pending時だけGitHub Auto-mergeを予約 |
| `nuinui integrate-clean <main\|sub> <SAY-123> <expected-claim> <expected-topic-head> <expected-main> <verification-script> <expected-files-manifest\|->` | ChatGPT-authorized NON-INTERFERING merge-gate refreshをactive laneでconflict-free merge-only実行し、verify後にnormal push |
| `nuinui e2e-start <SAY-123> <tested-ref>` | idle e2e laneをexact tested refへ固定しmarker作成 |
| `nuinui e2e-start-local-main <SAY-123> <tested-ref>` | Active interim workflow時だけlocal main checkpointをe2eへ安全に固定 |
| `nuinui e2e-release <SAY-123> <tested-ref>` | caller identityを照合し、verified e2e stateをlatest `origin/main` detachedへ戻し、durable receipt後にmarker削除。exact duplicateはread-only no-op |
| `nuinui last-result` | latest tracked Human mutationのstrict durable resultと、footerを除くcanonical outputをread-onlyで検証・復旧 |
| `nuinui context-audit <expected-main> <expected-artifact-blob>` | GitHub authoritative mainを照合するstandard cloneのstrict read-only audit。behind local HEAD / artifactは許容 |
| `nuinui context-sync <expected-main> <expected-artifact-blob>` | fresh fetch後にexpected-main treeのartifact blobを検証し、cleanなstandard clone `main`だけをff-only sync |
| `nuinui context-dev-audit <expected-branch> <expected-head>` | canonical `/Users/yosomi/Code/dev-context-dev`のregistered worktree / repository / clean / branch / HEADをstrict read-only audit |
| `nuinui context-dev-transition <expected-old-branch> <expected-old-head> <expected-main> <new-branch>` | concluded prior topicからexact expected mainへordinary detach/switchし、同じregistered worktreeでfresh branchをcreate/switch |
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

After successful terminal finalization, tracked mutations append a common `NUINUI COMMAND RESULT` footer while preserving their existing canonical output. `nuinui last-result` verifies the stored output hash before printing `recovery=READY` and the original output without that footer. A valid `STARTED` record returns `result=INCOMPLETE` / `recovery=BLOCKED` and never exposes an older output. Missing, malformed, unsafe, partial, or hash-mismatched state fails closed without `recovery=READY`; a recovered terminal BLOCKED or ERROR is still a successful read-only `last-result` operation.

### Durable ownership behavior

ownership schemaは[`CHECKOUTS.md`](./CHECKOUTS.md)の`version=1`をそのままconsumeする。helper versionとmetadata versionは独立している。

`preflight`はread-only diagnostic / routing command。main/sub FREE判定はauthoritative `ls-remote origin main`を使い、cleanでもbehindならFREEにしない。mutation lock、active slot、releasing tombstoneを優先して分類し、strict schema violationはBLOCKする。validなactive slotのbranch / Base ancestry / claim identityが一致していれば、working treeがdirtyでも`clean=no`と`state=BUSY`を返す。branch / Base / metadata identity mismatchは引き続きBLOCKする。known-Issueの通常startでは、ChatGPTが`expected-peer`を構成した`begin`が同じauditを行うため、別preflightを先に実行しない。

`lane-init`はfixed laneを正当に新規 / 再作成した場合のschema bootstrap。slot / lock / release stateがなくexact safe idleを証明できる場合だけmarkerを書く。既存active-looking checkoutからclaimを生成するrepair用途には使わない。

`begin`の形式は`nuinui begin <main|sub> <SAY-123> <expected-base-sha> <branch> <FREE|SAY-123>`。targetは必ずphysically FREE、peerは`FREE`またはexact durable owner Issueの`BUSY`でなければ開始しない。full 3-lane audit後、target条件を再検証して`start`へ委譲する。post-mutation consistencyを証明できない場合は新しいdurable ownershipを推測・削除せずBLOCKEDで返し、target generationを検証できれば`mutation_state=COMPLETED`とtargetのissue / branch / base / checkpoint / claim / clean / `state=BUSY`を返す。検証不能なら`mutation_state=UNKNOWN`と既知のrequested/new identityを返す。

同じ`begin` commandを直後に誤って再実行した場合、最初のfull preflightがPASSでtargetがBUSYなら、targetのdurable Issue / branch / Base、validな既存claim、slot / checkout identity、cleanなcheckout、checkout `HEAD == Base`、no lock / tombstone、callerのexact peer expectation、およびfull preflight PASSをすべてread-onlyで再証明できたときだけduplicateとして扱う。進行後のgenerationでcheckout `HEAD != Base`ならduplicate successにしない。再証明中にstateが変化した場合、または証明できない場合は既存のBLOCKEDへfail-closedする。

duplicate successは`IMPLEMENTATION ALREADY STARTED`とlane / issue / branch / base / `checkpoint=<Base>` / existing `claim` / `clean=yes` / `state=BUSY` / exact peer fields / `mutation=no-op` / `preflight=PASS`を返す。既存のdurable claimをそのまま再利用し、slot、claim、lock、tombstone、branch、checkout、peer stateを変更しない。これは新しい`start`ではなく、`resume`や`recover`を内部で代用するものでもない。

`start`はbranch switchより先にnew claim + lock + slotをdurable化する低レベル lifecycle primitiveとして保持する。成功outputのclaimは[`LINEAR-ISSUES.md`](./LINEAR-ISSUES.md)へcheckpointする。通常のHuman handoffは`begin`を使う。

`resume`はcaller-supplied Lane / Issue / Base / exact checkpoint / branch / claimとslotをexact照合する。通常のpushed checkpointではremote topicも同じcheckpointであることを要求する。`begin`直後の初回push前に限り、remote topicの成功したabsence、local topic = Base = expected checkpoint、cleanな既存topic、safeなidle identityをすべて証明できた場合だけ、そのlocal topicへ復帰できる。Base refresh、merge-main、rebase、reset、stash、force-switch、branch generation、claim inferenceを行わない。

`release`はcaller-supplied merged checkpoint + claimを必須とする。facadeはmutation前にactive slot、current topic branch checkpoint、durable claim、lock / tombstone / schemaをread-only検証し、checkpoint不一致は`BLOCKED: checkpoint mismatch`と`expected` / `actual`、claim不一致は`BLOCKED: claim mismatch`とdurable `expected` / caller `actual`を返す。rejected releaseはdurable ownershipを保持し、raw mutationが予期せず無診断で失敗してもcontext付きERRORを返す。remote topic branchがpost-mergeで削除済みでも、saved checkpointがcurrent authoritative mainに含まれることを証明できればrelease可能。release開始時にclaimed local topic branchをcheckoutしていた場合だけ、そのexact branchをsafe cleanup candidateにする。active generationがなく、receiptのlane / checkpoint / claim / Base / Issue / branch identity、idle checkout、authoritative main containmentをすべて完全一致で証明できない限り、過去receiptからreleaseを推測・採用しない。

`recover`は一般repairではない。lock/tombstone age expiry、自動削除、reset、stash、force-switch、broad branch cleanupを行わない。metadata malformed、multiple tombstones、claim mismatch、dirty、不一致stateはfail-closed。

`nuinui self-test`は既存のdurable safety pathsに加え、`scripts/test-nuinui-lifecycle`のisolated fixed-three-checkout testsでbegin occupancy admission、dirty valid BUSY lane classification、target start後にdirtyになるvalid BUSY peerを期待したbegin、wrong-branch fail-closed、complete lifecycle envelopes、durable completed-release receipt、read-only exact duplicate release、near-match / stale-generation / dirty / non-idle / lock / tombstone fail-closed、release checkpoint / claim failure retention、target mutation後のnon-target audit failureと`mutation_state=COMPLETED`、interrupted start / release recovery、old signature rejection、BLOCKED lane、stale FREE rejection、全public lifecycle failureのnon-empty diagnosticsを検証し、`scripts/test-nuinui-pr-auto-merge`のfake GitHub testでAuto-mergeのfailure / race diagnosticsを検証し、`scripts/test-nuinui-context-sync`のisolated Git repository/worktree testでproduction context audit/syncとpersistent worktree audit/transitionのfail-closed境界を検証する。

成功outputはcallerが別preflightなしにmanagement synchronizationへ進めるためのstate envelopeである。`begin`は`IMPLEMENTATION STARTED`とlane / issue / branch / base / checkpoint / claim / `clean=yes` / `state=BUSY` / exact peer fields / `preflight=PASS`を返す。`resume`は`IMPLEMENTATION RESUMED`とlane / issue / branch / base / checkpoint / claim / `clean=yes` / `state=BUSY`を返す。通常の`release`は`IMPLEMENTATION RELEASED`とIssue / saved checkpoint / released claim / released branch / idle branch / idle HEAD / authoritative origin main / `clean=yes` / `state=FREE`を返し、exact duplicateは`IMPLEMENTATION ALREADY RELEASED`とlane / Issue / Base / saved checkpoint / released claim / released branch / authoritative origin main / `clean=yes` / `mutation=no-op` / `state=FREE`を返す。

`start`をexplicit low-level primitiveとして直接使った場合も、full local audit後にlocal transition envelopeを返す。ただしpeerはその時点の観測値であり、ChatGPTが決めたcaller expectationとの一致を証明しない。canonical normal startupでは`begin`のexpected peer照合と`preflight=PASS`をadmission evidenceに使う。

### `integrate-clean` merge-only integration

`nuinui integrate-clean <main|sub> <SAY-123> <expected-claim> <expected-topic-head> <expected-main> <verification-script> <expected-files-manifest|->` は、already-reviewed topicに対するcurrent-base freshnessだけが必要な場合のnarrow Human integration helper。

eligibilityとpost-integration driftのsemantic `NON-INTERFERING`判断はChatGPTが行い、helper自身は判断しない。active durable lane / Issue / claim / branch / Base / exact local and remote topic / exact current main / clean stateを再検証してから、exact current mainの`--no-commit --no-ff` mergeだけを行う。

`verification-script`はChatGPTがcurrent Task contractから確定したabsolute executable pathを渡す。helperはtest selectionやCI classificationを再決定しない。optional manifestを使う場合はabsolute readable regular fileとし、`expected-main -> prospective merge tree`のNUL-delimited exact file setと比較する。

commit前のconflict、file-set mismatch、verification failure、tracked merge-state mutation、remote raceはmergeをabortし、必要なtracked worktree restorationをindexから行った上でoriginal topic checkpoint / durable claim / clean state / original remote topicを再証明する。`reset`、`stash`、force-switch、force-pushは行わない。exact restorationを証明できなければ`ERROR:`で停止する。

verification成功後にremote main / topicを再読込し、変化がない場合だけmerge commitを作る。commitはprior topicとexact expected mainの2 parentおよびverified prospective treeであることを検証する。normal non-force push成功後だけ`INTEGRATION PUSHED` envelopeを返し、その`integration_watermark`をexpected mainとして扱う。

push failureはverified local merge commitを保持し、rollback / rewrite / retryを行わずfresh ChatGPT diagnosisへ戻す。conflict resolution、integration fix、source edit、ambiguous failure diagnosis、test-debug loopはこのhelperのscope外でLunaへ戻す。

### Standalone non-lane mechanics

`pr-auto-merge`, E2E, context-audit / context-sync / context-dev-audit / context-dev-transition, doctor, transition-audit, context-checkも同じ`nuinui` scriptが直接実装する。別backend fileの存在をruntime preconditionにしない。

`nuinui pr-auto-merge`は`sayosomi/nuinuiCAD`だけを対象とするreservation-only command。`expected-main`はcallerがfreshに確認したauthoritative remote `main` SHAであり、helperはGitHubから`main` tipを独立取得して一致を確認する。PRの`baseRefOid`はauthoritative current-main freshnessのevidenceとして扱わない。PRがOPEN / non-draft / base=`main` / exact reviewed headで、reviewed headがそのauthoritative current `main`をintegration済みであり、mergeabilityがunambiguous、required checksがfailure/cancel/skip/unknownなしで少なくとも1件pendingの場合だけ予約へ進む。current main mismatchは`BLOCKED: expected main mismatch`、behind PRは`BLOCKED: PR is behind current main; integration required`としてfail-closedする。check discoveryは`pass` / `pending` / `fail` / `none-required` / `required-checks-unresolved` / `api-error`の明示stateを使い、visible required checksがすべて成功しpendingがない場合は、exact first line `BLOCKED: all required checks are already complete`でfail-closedし、Auto-merge予約もdirect mergeも行わない。

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

`nuinui doctor --full`、`transition-audit`、`context-check`、`context-audit`、`context-dev-audit`はread-only。`context-sync`はexpected-main tree artifactを検証したff-only mutation、`context-dev-transition`はexact old-stateを再検証したordinary detach/switch + create/switchだけを行う。これらはcleanup、process stop、Issue selection、Linear/GitHub update、merge判断を行わず、one-time worktree migrationやgeneric worktree cleanupもcommand surfaceに含めない。

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
