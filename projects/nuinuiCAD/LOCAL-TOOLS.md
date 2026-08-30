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

ChatGPTが承認済みdev-context create / update / deleteをGitHubへ反映した場合、同じ応答でlocal cloneへ反映するraw git commandを必ず提示する。

```bash
git -C /Users/yosomi/Code/dev-context pull --ff-only
```

cloneがないことが分かっている場合だけ初回cloneを案内する。

```bash
git clone https://github.com/sayosomi/dev-context.git /Users/yosomi/Code/dev-context
```

Humanが実行する前にlocal sync済みとみなさない。`nuinui context-sync`はconvenience commandだが、authoritative helper更新後にraw sync commandを提示する義務の代替ではない。

local cloneがdirty、`main`以外、またはfast-forward不可能ならreset / stash / forceせず`BLOCKED:`で停止する。

## Versioned `nuinui` helper

current standalone helper version: `1.6.6`。

`nuinui release <main|sub> <merged-checkpoint> <claim>`は、post-mergeにlane checkoutだけがdriftした場合も、`CHECKOUTS.md`の狭いproof setをrelease中に満たすときだけ既存local claimed topicへ通常の`git switch`で復旧する。branch生成やforce系操作はせず、再検証に失敗した場合はactive ownershipを保持して`BLOCKED:`で停止する。このrelease-only recoveryは`resume` / `recover`のclaim-checkout mismatchを変更しない。

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

e2e.sh
  e2e-start / e2e-start-local-main / e2e-release mechanics

context-sync.sh
  context-sync / local dev-context state diagnostics

diagnostics.sh
  doctor / transition-audit / context-check

self-test.sh
  built-in self-test + external regression aggregation

cli-dispatch.sh
  public command membership / usage / validation / dispatch
```

これらはdevelopment source onlyであり、production helperがruntimeにdynamic `source`することはない。`begin`は既存の`preflight` / `start` ownerを薄く組み合わせ、ownership state machineを二重実装しない。

current commands:

| Command | Purpose |
| --- | --- |
| `nuinui preflight` | fixed main / sub / e2e 3-lane stateとdurable ownershipのread-only audit |
| `nuinui verify <main\|sub> <SAY-123> <expected-base-sha> <branch>` | initialized FREE laneのstart preconditionをread-only検証 |
| `nuinui lane-init <main\|sub>` | proven exact idle fixed laneへpermanent v1 ownership schema markerをbootstrap |
| `nuinui begin <main\|sub> <SAY-123> <expected-base-sha> <branch> <FREE\|SAY-123>` | full 3-lane audit、target FREE、exact peer occupancy確認とnew generation startを1 Human handoffで実行 |
| `nuinui start <main\|sub> <SAY-123> <expected-base-sha> <branch>` | mutation lock + durable slotをbranch switch前に取得してnew claim generationを開始 |
| `nuinui resume <main\|sub> <SAY-123> <expected-base-sha> <expected-checkpoint-sha> <branch> <expected-claim>` | exact Base / checkpoint / branch / claimでsame generationへ復帰 |
| `nuinui release <main\|sub> <merged-checkpoint-sha> <expected-claim>` | exact claimを照合しclaim-specific tombstone経由でmerged laneをrelease |
| `nuinui recover <main\|sub> <expected-claim>` | known interrupted init/start/resume/release stateだけをexact claimでexplicit recovery |
| `nuinui pr-auto-merge <pr-number> <expected-head-sha> <expected-main-sha>` | reviewed exact headへrequired CI pending時だけGitHub Auto-mergeを予約 |
| `nuinui e2e-start <SAY-123> <tested-ref>` | idle e2e laneをexact tested refへ固定しmarker作成 |
| `nuinui e2e-start-local-main <SAY-123> <tested-ref>` | Active interim workflow時だけlocal main checkpointをe2eへ安全に固定 |
| `nuinui e2e-release` | verified e2e stateをlatest `origin/main` detachedへ戻しmarker削除 |
| `nuinui context-sync` | cleanなlocal dev-context `main`をsafe fast-forward |
| `nuinui doctor` | helper / lane / local dev-context diagnostic |
| `nuinui doctor --full` | preflight、E2E status、local dev-context stateのread-only snapshot |
| `nuinui transition-audit` | Active interim transition条件をread-only監査 |
| `nuinui context-check` | dev-context Markdown local linksと`nuinui` CLI-doc整合をread-only検査 |
| `nuinui self-test` | isolated temporary Git repositoriesでsupported safety pathsをexercise |

旧claimless `resume <lane> <Issue> <checkpoint> <branch>`、旧`release <lane> <checkpoint>`、active checkoutをownershipへadoptするpublic commandはcurrent CLIではない。argument count mismatchはfail-closedでusage errorにする。

### Durable ownership behavior

ownership schemaは[`CHECKOUTS.md`](./CHECKOUTS.md)の`version=1`をそのままconsumeする。helper versionとmetadata versionは独立している。

`preflight`はread-only diagnostic / routing command。main/sub FREE判定はauthoritative `ls-remote origin main`を使い、cleanでもbehindならFREEにしない。mutation lock、active slot、releasing tombstoneを優先して分類し、strict schema violationはBLOCKする。validなactive slotのbranch / Base ancestry / claim identityが一致していれば、working treeがdirtyでも`clean=no`と`state=BUSY`を返す。branch / Base / metadata identity mismatchは引き続きBLOCKする。known-Issueの通常startでは、ChatGPTが`expected-peer`を構成した`begin`が同じauditを行うため、別preflightを先に実行しない。

`lane-init`はfixed laneを正当に新規 / 再作成した場合のschema bootstrap。slot / lock / release stateがなくexact safe idleを証明できる場合だけmarkerを書く。既存active-looking checkoutからclaimを生成するrepair用途には使わない。

`begin`の形式は`nuinui begin <main|sub> <SAY-123> <expected-base-sha> <branch> <FREE|SAY-123>`。targetは必ずphysically FREE、peerは`FREE`またはexact durable owner Issueの`BUSY`でなければ開始しない。full 3-lane audit後、target条件を再検証して`start`へ委譲する。post-mutation consistencyを証明できない場合は新しいdurable ownershipを推測・削除せずBLOCKEDで返し、target generationを検証できれば`mutation_state=COMPLETED`とtargetのissue / branch / base / checkpoint / claim / clean / `state=BUSY`を返す。検証不能なら`mutation_state=UNKNOWN`と既知のrequested/new identityを返す。

`start`はbranch switchより先にnew claim + lock + slotをdurable化する低レベル lifecycle primitiveとして保持する。成功outputのclaimは[`LINEAR-ISSUES.md`](./LINEAR-ISSUES.md)へcheckpointする。通常のHuman handoffは`begin`を使う。

`resume`はcaller-supplied Lane / Issue / Base / exact checkpoint / branch / claimとslotをexact照合する。通常のpushed checkpointではremote topicも同じcheckpointであることを要求する。`begin`直後の初回push前に限り、remote topicの成功したabsence、local topic = Base = expected checkpoint、cleanな既存topic、safeなidle identityをすべて証明できた場合だけ、そのlocal topicへ復帰できる。Base refresh、merge-main、rebase、reset、stash、force-switch、branch generation、claim inferenceを行わない。

`release`はcaller-supplied merged checkpoint + claimを必須とする。facadeはmutation前にactive slot、current topic branch checkpoint、durable claim、lock / tombstone / schemaをread-only検証し、checkpoint不一致は`BLOCKED: checkpoint mismatch`と`expected` / `actual`、claim不一致は`BLOCKED: claim mismatch`とdurable `expected` / caller `actual`を返す。rejected releaseはdurable ownershipを保持し、raw mutationが予期せず無診断で失敗してもcontext付きERRORを返す。remote topic branchがpost-mergeで削除済みでも、saved checkpointがcurrent authoritative mainに含まれることを証明できればrelease可能。release開始時にclaimed local topic branchをcheckoutしていた場合だけ、そのexact branchをsafe cleanup candidateにする。

`recover`は一般repairではない。lock/tombstone age expiry、自動削除、reset、stash、force-switch、broad branch cleanupを行わない。metadata malformed、multiple tombstones、claim mismatch、dirty、不一致stateはfail-closed。

`nuinui self-test`は既存のdurable safety pathsに加え、`scripts/test-nuinui-lifecycle`のisolated fixed-three-checkout testsでbegin occupancy admission、dirty valid BUSY lane classification、target start後にdirtyになるvalid BUSY peerを期待したbegin、wrong-branch fail-closed、complete lifecycle envelopes、release checkpoint / claim failure retention、target mutation後のnon-target audit failureと`mutation_state=COMPLETED`、interrupted start / release recovery、old signature rejection、BLOCKED lane、stale FREE rejection、全public lifecycle failureのnon-empty diagnosticsを検証し、`scripts/test-nuinui-pr-auto-merge`のfake GitHub testでAuto-mergeのfailure / race diagnosticsを検証する。

成功outputはcallerが別preflightなしにmanagement synchronizationへ進めるためのstate envelopeである。`begin`は`IMPLEMENTATION STARTED`とlane / issue / branch / base / checkpoint / claim / `clean=yes` / `state=BUSY` / exact peer fields / `preflight=PASS`を返す。`resume`は`IMPLEMENTATION RESUMED`とlane / issue / branch / base / checkpoint / claim / `clean=yes` / `state=BUSY`を返す。`release`は`IMPLEMENTATION RELEASED`とIssue / saved checkpoint / released claim / released branch / idle branch / idle HEAD / authoritative origin main / `clean=yes` / `state=FREE`を返す。

`start`をexplicit low-level primitiveとして直接使った場合も、full local audit後にlocal transition envelopeを返す。ただしpeerはその時点の観測値であり、ChatGPTが決めたcaller expectationとの一致を証明しない。canonical normal startupでは`begin`のexpected peer照合と`preflight=PASS`をadmission evidenceに使う。

### Standalone non-lane mechanics

`pr-auto-merge`, E2E, context-sync, doctor, transition-audit, context-checkも同じ`nuinui` scriptが直接実装する。別backend fileの存在をruntime preconditionにしない。

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

`nuinui doctor --full`、`transition-audit`、`context-check`はread-only。checkout mutation、cleanup、process stop、Issue selection、Linear/GitHub update、merge判断を行わない。

## Human Manual E2E preparation helper

`projects/nuinuiCAD/scripts/nuinui-e2e-prepare`はdedicated e2e laneでHuman Manual E2E hostを準備するversioned helper。

```text
nuinui-e2e-prepare check <SAY-123> <tested-ref> <fixture-path>
nuinui-e2e-prepare prepare <SAY-123> <tested-ref> <fixture-path> [cdp-port]
nuinui-e2e-prepare status
nuinui-e2e-prepare cleanup
nuinui-e2e-prepare closure-check <SAY-123>
```

`prepare`はexact tested ref / marker / clean detached checkoutを検証し、dependency materializationとrequired build後にfresh VS Code Extension Development Hostを起動してHuman handoffを作る。tracked-file mutationはBLOCKする。

Human E2Eのcanonical successful closureは、次の順序に固定する。

```text
nuinui-e2e-prepare cleanup
nuinui e2e-release
nuinui-e2e-prepare closure-check <SAY-123>
```

session metadataはexact E2E root / handoff / launch PIDを保持する。`cleanup`はmetadataとtested markerを再検証し、owned process / temporary root / handoff / session metadataだけを削除する。tested same-Issue markerは意図的に保持され、cleanup後のmarker存在・session metadata不在がnormalなrelease-ready stateである。markerを削除するのは`nuinui e2e-release`だけである。session metadataが残る間はe2e laneをreleaseしない。

`status`と`closure-check`はread-only。unmanaged artifactや別Issue stateを勝手にcleanupしない。`closure-check`はe2e-release後だけに行うfinal read-only closure proofであり、cleanupとe2e-releaseの間の通常のrelease-precondition checkではない。同一Issue markerが残っている間はclosure-checkが`BLOCKED`になるfail-closed semanticsを維持する。

`projects/nuinuiCAD/scripts/test-nuinui-e2e-prepare`はtemporary Git checkoutとfake hostでisolated self-testを行う。実機VS Code / dependency / CDP lifecycleはactual e2e preparation時に別途確認する。

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
